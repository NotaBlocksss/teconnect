import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart' as record;
import 'package:just_audio/just_audio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/auth_provider.dart';
import '../../services/ticket_service.dart';
import '../../services/message_service.dart';
import '../../services/presence_service.dart';
import '../../models/ticket_model.dart';
import '../../models/message_model.dart';
import '../../theme/app_theme.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final TicketService _ticketService = TicketService();
  final MessageService _messageService = MessageService();
  final PresenceService _presenceService = PresenceService();
  TicketModel? _ticket;
  String? _currentUserId;
  bool _isViewing = false;
  
  static const Color _primaryGreen = Color(0xFF2D5A3D);
  static const Color _darkGreen = Color(0xFF1B3A26);
  static const Color _lightGreen = Color(0xFF6BC48A);
  
  // WhatsApp-like features
  bool _showEmojiPicker = false;
  MessageModel? _replyingTo;
  final Map<String, MessageModel> _optimisticMessages = {};
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier<bool>(false);
  bool _shouldAutoScroll = false;
  bool _isTyping = false;
  final ValueNotifier<List<String>> _typingUsersNotifier = ValueNotifier<List<String>>([]);
  
  // Audio recording
  final record.AudioRecorder _audioRecorder = record.AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  
  // Audio playback
  final Map<String, AudioPlayer> _audioPlayers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePresence();
    _loadTicket();
    _messageController.addListener(_onTextChanged);
    _setupTypingListener();
    _setupOnlineListener();
    _setupViewersListener();
  }

  void _setupTypingListener() {
    _presenceService.getTypingUsers(widget.ticketId).listen((users) {
      if (mounted) {
        final filteredUsers = users.where((id) => id != _currentUserId && id.isNotEmpty).toList();
        if (_typingUsersNotifier.value.length != filteredUsers.length ||
            !_typingUsersNotifier.value.every((id) => filteredUsers.contains(id))) {
          _typingUsersNotifier.value = filteredUsers;
        }
      }
    });
  }

  StreamSubscription<QuerySnapshot>? _viewersSubscription;

  void _setupViewersListener() {
    // Escuchar cuando alguien entra o sale del ticket para actualizar estados de lectura
    _viewersSubscription = FirebaseFirestore.instance
        .collection('tickets')
        .doc(widget.ticketId)
        .collection('viewers')
        .snapshots()
        .listen((snapshot) async {
      if (_currentUserId == null || !mounted) return;

      // Verificar si el destinatario está viendo el ticket
      final ticket = _ticket;
      if (ticket == null) return;

      final otherUserId = ticket.createdBy == _currentUserId
          ? ticket.assignedTo
          : ticket.createdBy;

      if (otherUserId == null) return;

      final isOtherUserViewing = snapshot.docs.any((doc) => doc.id == otherUserId);

      if (isOtherUserViewing) {
        // Si el otro usuario está viendo, marcar mensajes como leídos
        await _markMessagesAsReadForOtherUser(otherUserId);
      }
    });
  }

  Timer? _markReadDebounceTimer;
  
  Future<void> _markMessagesAsReadForOtherUser(String otherUserId) async {
    // Debounce para evitar actualizaciones constantes
    _markReadDebounceTimer?.cancel();
    _markReadDebounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      try {
        // Marcar los mensajes del otro usuario como leídos solo si él está viendo
        final viewerDoc = await FirebaseFirestore.instance
            .collection('tickets')
            .doc(widget.ticketId)
            .collection('viewers')
            .doc(otherUserId)
            .get();

        if (!viewerDoc.exists) return;

        final snapshot = await FirebaseFirestore.instance
            .collection('tickets')
            .doc(widget.ticketId)
            .collection('messages')
            .where('senderId', isEqualTo: _currentUserId)
            .where('status', whereIn: ['sent', 'delivered'])
            .limit(10)
            .get();

        if (snapshot.docs.isEmpty) return;

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {'status': 'read'});
        }
        await batch.commit();
      } catch (e) {
        // Error silencioso
      }
    });
  }

  void _setupOnlineListener() {
    // El estado online se maneja directamente en el StreamBuilder del AppBar
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    
    if (_hasTextNotifier.value != hasText) {
      _hasTextNotifier.value = hasText;
    }

    if (_currentUserId != null && _ticket != null && !_ticket!.isClosed) {
      if (hasText && !_isTyping) {
        _isTyping = true;
        _presenceService.setUserTyping(_currentUserId!, widget.ticketId, true);
        Future.delayed(const Duration(seconds: 3), () {
          if (_isTyping && mounted) {
            _isTyping = false;
            _presenceService.setUserTyping(_currentUserId!, widget.ticketId, false);
          }
        });
      } else if (!hasText && _isTyping) {
        _isTyping = false;
        _presenceService.setUserTyping(_currentUserId!, widget.ticketId, false);
      }
    }
  }

  Future<void> _initializePresence() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      await _presenceService.setUserViewingTicket(user.id, widget.ticketId);
      if (mounted) {
        _isViewing = true;
        _markMessagesAsRead();
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null) return;
    try {
      // Verificar si el usuario está online
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId!)
          .get();
      
      final isOnline = userDoc.data()?['isOnline'] as bool? ?? false;
      
      if (isOnline) {
        // Actualizar mensajes "sent" a "delivered" cuando el usuario está online
        await _messageService.updateSentMessagesToDelivered(widget.ticketId, _currentUserId!);
        
        // Marcar mensajes como leídos solo si el usuario está viendo el ticket
        // (esto se verifica dentro de markAllMessagesAsRead)
        await _messageService.markAllMessagesAsRead(widget.ticketId, _currentUserId!);
      }
    } catch (e) {
      // Error silencioso
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUserId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted) {
          _presenceService.setUserViewingTicket(_currentUserId!, widget.ticketId);
          _isViewing = true;
          _markMessagesAsRead();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _presenceService.removeUserViewingTicket(_currentUserId!, widget.ticketId);
        _isViewing = false;
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _presenceService.removeUserViewingTicket(_currentUserId!, widget.ticketId);
        _isViewing = false;
        break;
    }
  }

  Future<void> _loadTicket() async {
    final ticket = await _ticketService.getTicketById(widget.ticketId);
    if (mounted) {
      setState(() {
        _ticket = ticket;
      });
      _setupOnlineListener();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewersSubscription?.cancel();
    _recordingTimer?.cancel();
    _markReadDebounceTimer?.cancel();
    
    if (_isRecording) {
      _audioRecorder.stop().then((_) {
        try {
          _audioRecorder.dispose();
        } catch (e) {
          // Error silencioso al limpiar
        }
      }).catchError((_) {
        try {
          _audioRecorder.dispose();
        } catch (e) {
          // Error silencioso al limpiar
        }
      });
    } else {
      try {
        _audioRecorder.dispose();
      } catch (e) {
        // Error silencioso al limpiar
      }
    }
    
    for (var player in _audioPlayers.values) {
      try {
        player.dispose();
      } catch (e) {
        // Error silencioso al limpiar
      }
    }
    _audioPlayers.clear();
    
    if (_currentUserId != null) {
      if (_isViewing) {
        _presenceService.removeUserViewingTicket(_currentUserId!, widget.ticketId);
      }
      if (_isTyping) {
        _presenceService.setUserTyping(_currentUserId!, widget.ticketId, false);
      }
    }
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _hasTextNotifier.dispose();
    _typingUsersNotifier.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null || !mounted) return;

      final ticket = await _ticketService.getTicketById(widget.ticketId);
      if (ticket == null) return;

      if (ticket.isClosed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Este ticket está cerrado y no se pueden enviar más mensajes'),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      final messageText = _messageController.text.trim();

      if (messageText.startsWith('/close') && (user.isWorker || user.isAdmin)) {
        final reason = messageText.substring('/close'.length).trim();
        if (reason.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Debes proporcionar una razón para cerrar el ticket. Ejemplo: /close Problema resuelto'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          return;
        }

        await _ticketService.closeTicket(widget.ticketId, reason);

        final closeMessage = MessageModel(
          id: '',
          ticketId: widget.ticketId,
          senderId: user.id,
          senderName: user.name,
          content: 'Ticket cerrado. Razón: $reason',
          timestamp: DateTime.now(),
        );
        await _messageService.sendMessage(closeMessage);

        await _loadTicket();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Ticket cerrado exitosamente'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        _messageController.clear();
        return;
      }

      if (messageText.startsWith('/close')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Solo trabajadores y administradores pueden cerrar tickets'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      // Crear mensaje con estado "sending" para optimistic update
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final message = MessageModel(
        id: tempId,
        ticketId: widget.ticketId,
        senderId: user.id,
        senderName: user.name,
        content: messageText,
        timestamp: DateTime.now(),
        status: 'sending',
        replyToId: _replyingTo?.id,
        replyToContent: _replyingTo?.content,
        replyToSenderName: _replyingTo?.senderName,
      );

      // Optimistic update - mostrar mensaje inmediatamente
      if (mounted) {
        setState(() {
          _optimisticMessages[tempId] = message;
          _replyingTo = null;
        });
      }

      // Limpiar input inmediatamente
      _messageController.clear();
      
      // Dejar de escribir
      if (_isTyping) {
        _isTyping = false;
        _presenceService.setUserTyping(user.id, widget.ticketId, false);
      }
      
      // Marcar para scroll automático solo para este mensaje
      _shouldAutoScroll = true;

      // Enviar mensaje en background
      _sendMessageAsync(message, tempId, ticket, user);
    } catch (e) {
      if (!mounted) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error al enviar mensaje: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _sendMessageAsync(
    MessageModel message,
    String tempId,
    TicketModel ticket,
    user,
  ) async {
    try {
      // Enviar mensaje real
      final sentMessage = message.copyWith(id: '');
      await _messageService.sendMessage(sentMessage);

      // El stream de Firestore se encargará de actualizar la UI cuando el mensaje se agregue
      // Solo removemos el mensaje optimista después de un delay para dar tiempo al stream
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _optimisticMessages.containsKey(tempId)) {
          setState(() {
            _optimisticMessages.remove(tempId);
          });
        }
      });

      // Actualizar participantes si es necesario (solo una vez, sin rebuild)
      if (!ticket.participants.contains(user.id)) {
        await _ticketService.updateTicket(
          ticket.copyWith(
            participants: [...ticket.participants, user.id],
          ),
        );
      }
    } catch (e) {
      // Si falla, actualizar estado del mensaje optimista
      if (mounted) {
        setState(() {
          if (_optimisticMessages.containsKey(tempId)) {
            _optimisticMessages[tempId] = _optimisticMessages[tempId]!
                .copyWith(status: 'error');
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al enviar mensaje: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: const Color(0xFF2A2A2A),
              onPressed: () => _sendMessageAsync(message, tempId, ticket, user),
            ),
          ),
        );
        }
      }
    }
  }

  Future<void> _assignTicket(String? assignedTo) async {
    if (!mounted) return;
    try {
      final ticket = await _ticketService.getTicketById(widget.ticketId);
      if (ticket == null || !mounted) return;

      await _ticketService.assignTicket(widget.ticketId, assignedTo ?? '');
      if (mounted) {
        await _loadTicket();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar ticket: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
        appBar: _buildChatAppBar(context, currentUser, isDark),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messageService.getMessagesByTicket(widget.ticketId),
              builder: (context, snapshot) {
                            // Solo mostrar loading en la carga inicial
                            if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: _primaryGreen,
                                ),
                              );
                            }
                            
                            // Si hay datos previos, usarlos mientras se carga
                            final messages = snapshot.data ?? [];

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        size: 48,
                                        color: AppTheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Error al cargar mensajes',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      snapshot.error.toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (messages.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : _primaryGreen.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 48,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No hay mensajes aún',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sé el primero en escribir',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final allMessages = <MessageModel>[];
                            
                            if (messages.isNotEmpty) {
                              allMessages.addAll(messages);
                            }
                            
                            if (_optimisticMessages.isNotEmpty) {
                              final optimisticToAdd = <MessageModel>[];
                              final toRemove = <String>[];
                              
                              for (var entry in _optimisticMessages.entries) {
                                final optimisticMsg = entry.value;
                                // Detección mejorada de duplicados: comparar contenido, sender y tiempo
                                final isDuplicate = messages.any((realMsg) {
                                  if (realMsg.senderId != optimisticMsg.senderId) return false;
                                  if (realMsg.content != optimisticMsg.content) return false;
                                  final timeDiff = (realMsg.timestamp.difference(optimisticMsg.timestamp).inSeconds).abs();
                                  return timeDiff <= 3; // Reducido de 5 a 3 segundos
                                });
                                
                                if (isDuplicate) {
                                  toRemove.add(entry.key);
                                } else {
                                  optimisticToAdd.add(optimisticMsg);
                                }
                              }
                              
                              // Remover duplicados de forma asíncrona para no bloquear el build
                              if (toRemove.isNotEmpty) {
                                Future.microtask(() {
                                  if (mounted) {
                                    setState(() {
                                      for (var key in toRemove) {
                                        _optimisticMessages.remove(key);
                                      }
                                    });
                                  }
                                });
                              }
                              
                              if (optimisticToAdd.isNotEmpty) {
                                allMessages.addAll(optimisticToAdd);
                              }
                            }
                            
                            if (allMessages.length > 1) {
                              allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                            }

                            if (allMessages.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 64,
                                      color: isDark ? Colors.white24 : Colors.black26,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay mensajes aún',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Scroll automático sin animación para evitar interrupciones
                            if (_shouldAutoScroll) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_scrollController.hasClients && _scrollController.position.maxScrollExtent >= 0) {
                                  _scrollController.jumpTo(0);
                                  _shouldAutoScroll = false;
                                }
                              });
                            }

                            return NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                return false;
                              },
                              child: ListView.builder(
                                key: const ValueKey('messages_list'),
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                itemCount: allMessages.length,
                                itemBuilder: (context, index) {
                                    final message = allMessages[allMessages.length - 1 - index];
                                    final isSystem = message.type == 'system' || message.senderId == 'system';
                                    final isMe = !isSystem && message.senderId == currentUser?.id;
                                    final prevMessage = index < allMessages.length - 1
                                        ? allMessages[allMessages.length - 2 - index]
                                        : null;
                                    final showAvatar = !isMe && !isSystem && (prevMessage == null || prevMessage.senderId != message.senderId);
                                    final showTime = prevMessage == null || 
                                        (message.timestamp.difference(prevMessage.timestamp).inMinutes > 5);

                                    if (isSystem) {
                                      return _SystemMessageBubble(
                                        message: message,
                                        isDark: isDark,
                                      );
                                    }

                                    return _MessageBubble(
                                      message: message,
                                      isMe: isMe,
                                      isDark: isDark,
                                      showAvatar: showAvatar,
                                      showTime: showTime,
                                      onReply: () {
                                        if (mounted) {
                                          setState(() {
                                            _replyingTo = message;
                                            _showEmojiPicker = false;
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                              );
              },
            ),
          ),
          
          // Indicador de escribiendo (estilo WhatsApp)
          ValueListenableBuilder<List<String>>(
            valueListenable: _typingUsersNotifier,
            builder: (context, typingUsers, _) {
              if (typingUsers.isEmpty) {
                return const SizedBox.shrink();
              }
              return _TypingIndicator(
                typingUsers: typingUsers,
                isDark: isDark,
              );
            },
          ),
          
          // Input de mensaje
          _buildMessageInput(context, currentUser, isDark),
          
          // Emoji picker
          if (_showEmojiPicker)
            Container(
              height: 280,
              color: isDark ? const Color(0xFF1E2329) : const Color(0xFF2A2A2A),
              child: Builder(
                builder: (context) {
                  try {
                    return emoji.EmojiPicker(
                      onEmojiSelected: (category, emojiItem) {
                        if (mounted) {
                          setState(() {
                            _messageController.text += emojiItem.emoji;
                          });
                        }
                      },
                      config: emoji.Config(
                        height: 280,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: emoji.EmojiViewConfig(
                          backgroundColor: isDark ? const Color(0xFF1E2329) : const Color(0xFF2A2A2A),
                          emojiSizeMax: 28,
                        ),
                        skinToneConfig: const emoji.SkinToneConfig(),
                        categoryViewConfig: emoji.CategoryViewConfig(
                          backgroundColor: isDark ? const Color(0xFF2A2F35) : const Color(0xFFF0F0F0),
                          iconColorSelected: _primaryGreen,
                        ),
                        bottomActionBarConfig: emoji.BottomActionBarConfig(
                          backgroundColor: isDark ? const Color(0xFF2A2F35) : const Color(0xFFF0F0F0),
                        ),
                      ),
                    );
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar(BuildContext context, currentUser, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1B3A26) : _primaryGreen,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: _ticket == null
          ? const SizedBox.shrink()
          : Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryGreen,
                        _darkGreen,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.support_agent, color: const Color(0xFF2A2A2A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ticket!.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A2A2A),
                        ),
                        softWrap: true,
                      ),
                      StreamBuilder<bool>(
                        stream: _ticket != null
                            ? _presenceService.isUserOnline(
                                _ticket!.createdBy == currentUser?.id
                                    ? (_ticket!.assignedTo ?? '')
                                    : _ticket!.createdBy)
                            : Stream.value(false),
                        builder: (context, snapshot) {
                          final isOnline = snapshot.data ?? false;
                          if (_ticket!.status == 'closed') {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            isOnline ? 'En línea' : 'Sin conexión',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: isDark ? const Color(0xFF2A2F35) : const Color(0xFF2A2A2A),
          itemBuilder: (context) => [
            if (currentUser != null &&
                (currentUser.isAdmin || currentUser.isWorker) &&
                _ticket?.assignedTo == null)
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.person_add, size: 20),
                    const SizedBox(width: 12),
                    Text('Asignar a mí', style: GoogleFonts.inter()),
                  ],
                ),
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _assignTicket(currentUser.id),
                ),
              ),
          ],
        ),
      ],
    );
  }


  Widget _buildMessageInput(BuildContext context, currentUser, bool isDark) {
    if (_ticket?.isClosed == true) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF2A2A2A),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9).withValues(alpha: isDark ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lock_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Este ticket está cerrado. No se pueden enviar más mensajes.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2A2A2A),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2F35) : const Color(0xFF2A2A2A),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryGreen, _darkGreen],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyingTo!.senderName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _replyingTo!.content,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _replyingTo = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            
            // Indicador de grabación
            if (_isRecording)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.error.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic,
                      color: AppTheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatRecordingDuration(_recordingDuration),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.error,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        if (!mounted) return;
                        _recordingTimer?.cancel();
                        _audioRecorder.stop();
                        if (_audioPath != null) {
                          File(_audioPath!).delete();
                        }
                        if (mounted) {
                          setState(() {
                            _isRecording = false;
                            _recordingDuration = Duration.zero;
                            _audioPath = null;
                          });
                        }
                      },
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.inter(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  // Botón de adjuntar
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pickFile(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.attach_file,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  
                  // Campo de texto
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2F35) : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Mensaje',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: isDark ? Colors.white54 : Colors.black38,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // Botón de emoji
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _showEmojiPicker ? Icons.keyboard : Icons.insert_emoticon,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // Botón de enviar/micrófono
                  ValueListenableBuilder<bool>(
                    valueListenable: _hasTextNotifier,
                    builder: (context, hasText, _) {
                      return GestureDetector(
                        onLongPress: hasText ? null : _startRecording,
                        onLongPressEnd: hasText ? null : (_) => _stopRecording(),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: hasText ? _sendMessage : null,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: hasText || _isRecording
                                    ? LinearGradient(
                                        colors: _isRecording
                                            ? [AppTheme.error, Colors.red.shade700]
                                            : [_primaryGreen, _darkGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: hasText || _isRecording
                                    ? null
                                    : (isDark ? const Color(0xFF2A2F35) : const Color(0xFFF5F7FA)),
                                shape: BoxShape.circle,
                                boxShadow: hasText || _isRecording
                                    ? [
                                        BoxShadow(
                                          color: (_isRecording ? AppTheme.error : _primaryGreen).withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: _isRecording
                                  ? const Icon(
                                      Icons.stop,
                                      color: const Color(0xFF2A2A2A),
                                      size: 20,
                                    )
                                  : Icon(
                                      hasText ? Icons.send : Icons.mic,
                                      color: hasText
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : Colors.black54),
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    if (!mounted) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        // TODO: Subir archivo a Firebase Storage y enviar mensaje
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Funcionalidad de archivos próximamente'),
              backgroundColor: AppTheme.info,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  String _formatRecordingDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    if (!mounted) return;
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Se necesita permiso de micrófono para grabar audio'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _audioPath = '${directory.path}/audio_$timestamp.m4a';

      if (await _audioRecorder.hasPermission() && mounted) {
        await _audioRecorder.start(
          const record.RecordConfig(
            encoder: record.AudioEncoder.aacLc,
            bitRate: 128000,
          ),
          path: _audioPath!,
        );

        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordingDuration = Duration.zero;
          });
        }

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordingDuration = Duration(seconds: timer.tick);
            });
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar grabación: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!mounted) return;
    try {
      _recordingTimer?.cancel();
      
      if (_isRecording && _audioPath != null) {
        final path = await _audioRecorder.stop();
        
        if (!mounted) return;
        
        if (path != null) {
          if (mounted) {
            setState(() {
              _isRecording = false;
            });
          }
          
          if (mounted) {
            await _sendAudioMessage(path);
          }
        } else {
          if (mounted) {
            setState(() {
              _isRecording = false;
              _recordingDuration = Duration.zero;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al detener grabación: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendAudioMessage(String audioPath) async {
    if (!mounted) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) return;

      final ticket = await _ticketService.getTicketById(widget.ticketId);
      if (ticket == null || ticket.isClosed) return;

      final file = File(audioPath);
      final fileSize = await file.length();
      final duration = _recordingDuration;

      if (fileSize == 0 || duration.inSeconds < 1) {
        await file.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('La grabación es muy corta'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
        return;
      }

      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('tickets')
          .child(widget.ticketId)
          .child('audios')
          .child(fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Subiendo audio...'),
              ],
            ),
            backgroundColor: AppTheme.info,
            duration: const Duration(seconds: 30),
          ),
        );
      }

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      if (!mounted) {
        await file.delete();
        return;
      }

      final message = MessageModel(
        id: '',
        ticketId: widget.ticketId,
        senderId: user.id,
        senderName: user.name,
        content: '🎤 Audio',
        timestamp: DateTime.now(),
        type: 'audio',
        attachmentUrl: downloadUrl,
        fileName: fileName,
        fileSize: fileSize,
      );

      await _messageService.sendMessage(message);

      await file.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (mounted) {
          setState(() {
            _recordingDuration = Duration.zero;
            _audioPath = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar audio: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
        }
      }
    }
  }
}

class _SystemMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isDark;
  
  static const Color _primaryGreen = Color(0xFF2D5A3D);
  static const Color _darkGreen = Color(0xFF1B3A26);
  static const Color _lightGreen = Color(0xFF6BC48A);

  const _SystemMessageBubble({
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF2A2F35).withValues(alpha: 0.6)
                : _primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? _primaryGreen.withValues(alpha: 0.3)
                  : _primaryGreen.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark ? _lightGreen : _primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sistema',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? _lightGreen : _primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppTheme.darkGray,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isDark;
  final bool showAvatar;
  final bool showTime;
  final VoidCallback? onReply;
  
  static const Color _primaryGreen = Color(0xFF2D5A3D);
  static const Color _darkGreen = Color(0xFF1B3A26);
  static const Color _lightGreen = Color(0xFF6BC48A);

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
    this.showAvatar = false,
    this.showTime = true,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryGreen, _darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              margin: EdgeInsets.only(
                left: isMe ? 50 : 0,
                right: isMe ? 0 : 50,
                top: 4,
                bottom: 4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [
                          _primaryGreen.withValues(alpha: 0.9),
                          _darkGreen.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe
                    ? null
                    : (isDark ? const Color(0xFF2A2F35) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? _primaryGreen : Colors.black).withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMe 
                            ? Colors.white.withValues(alpha: 0.9)
                            : (isDark ? _lightGreen : _primaryGreen),
                      ),
                    ),
                  ),
                  
                  if (message.replyToId != null && message.replyToContent != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: (isMe ? Colors.black : Colors.white).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border(
                          left: BorderSide(
                            color: isMe ? Colors.white : _primaryGreen,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.replyToSenderName ?? 'Usuario',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isMe ? Colors.white : _primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message.replyToContent!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isMe ? Colors.white70 : Colors.black87,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  
                  if (message.type == 'audio')
                    _AudioPlayerWidget(
                      message: message,
                      isMe: isMe,
                      isDark: isDark,
                    )
                  else
                    Text(
                      message.content,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        height: 1.4,
                        fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  
                  const SizedBox(height: 2),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: isMe ? Colors.white70 : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                      if (message.status == 'sending') ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isMe ? Colors.white70 : Colors.white54,
                        ),
                      ] else if (message.status == 'error') ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Colors.red,
                        ),
                      ] else if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == 'read' || message.status == 'delivered'
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: message.status == 'read'
                              ? Colors.white
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final bool isDark;

  const _AudioPlayerWidget({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  static const Color _primaryGreen = Color(0xFF2D5A3D);
  static const Color _darkGreen = Color(0xFF1B3A26);
  static const Color _lightGreen = Color(0xFF6BC48A);
  
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.message.attachmentUrl == null) return;

    try {
      await _audioPlayer.setUrl(widget.message.attachmentUrl!);
      
      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = state.processingState == ProcessingState.loading;
          });
        }
      });
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> _togglePlayPause() async {
    if (!mounted) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reproducir audio: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : _primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isMe ? Colors.white : _primaryGreen,
                        ),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isMe ? Colors.white : _primaryGreen,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0,
                  backgroundColor: widget.isMe
                      ? Colors.white.withValues(alpha: 0.3)
                      : _primaryGreen.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isMe ? Colors.white : _primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_position),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: widget.isMe
                        ? Colors.white70
                        : (widget.isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;
  final bool isDark;

  const _TypingIndicator({
    required this.typingUsers,
    required this.isDark,
  });

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2A2A2A),
        border: Border(
          top: BorderSide(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF2A2F35) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _dotAnimations[index],
                  builder: (context, child) {
                    return Container(
                      margin: EdgeInsets.only(
                        right: index < 2 ? 4 : 0,
                      ),
                      child: Opacity(
                        opacity: 0.3 + (_dotAnimations[index].value * 0.7),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.white70 : Colors.black54,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.typingUsers.length == 1
                  ? 'Escribiendo...'
                  : '${widget.typingUsers.length} personas escribiendo...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: widget.isDark ? Colors.white54 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}


