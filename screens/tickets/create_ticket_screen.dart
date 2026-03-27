import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';

// Clase para las razones de tickets relacionadas con wifi
class TicketReason {
  final String id;
  final String title;
  final String priority;

  const TicketReason({
    required this.id,
    required this.title,
    required this.priority,
  });
}

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  //Rs Development
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedReason;
  bool _isLoading = false;
  bool _hasOpenTicket = false;

  // Lista de razones disponibles para crear tickets
  static const List<TicketReason> _ticketReasons = [
    TicketReason(
      id: 'network_failure',
      title: 'Fallo de red / Sin conexión a internet',
      priority: 'urgent',
    ),
    TicketReason(
      id: 'slow_speed',
      title: 'Velocidad de internet muy lenta',
      priority: 'high',
    ),
    TicketReason(
      id: 'router_modem_issue',
      title: 'Problemas con el router o módem',
      priority: 'high',
    ),
    TicketReason(
      id: 'intermittent_connection',
      title: 'Conexión intermitente o inestable',
      priority: 'high',
    ),
    TicketReason(
      id: 'installation_issue',
      title: 'Problemas con la instalación del servicio',
      priority: 'high',
    ),
    TicketReason(
      id: 'equipment_damage',
      title: 'Equipo dañado o defectuoso',
      priority: 'high',
    ),
    TicketReason(
      id: 'billing_issue',
      title: 'Problemas con la facturación',
      priority: 'medium',
    ),
    TicketReason(
      id: 'plan_change',
      title: 'Solicitud de cambio de plan',
      priority: 'medium',
    ),
    TicketReason(
      id: 'service_suspension',
      title: 'Servicio suspendido o cortado',
      priority: 'high',
    ),
    TicketReason(
      id: 'technical_support',
      title: 'Soporte técnico general',
      priority: 'medium',
    ),
    TicketReason(
      id: 'update_personal_data',
      title: 'Actualización de datos personales',
      priority: 'low',
    ),
    TicketReason(
      id: 'information_request',
      title: 'Solicitud de información',
      priority: 'low',
    ),
    TicketReason(
      id: 'other',
      title: 'Otro motivo',
      priority: 'medium',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkOpenTicket();
  }

  Future<void> _checkOpenTicket() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // Verificar tickets abiertos para TODOS los roles
    if (user != null) {
      try {
        final ticketService = TicketService();
        final hasOpen = await ticketService.hasOpenTickets(user.id);
        if (mounted) {
          setState(() {
            _hasOpenTicket = hasOpen;
          });
        }
      } catch (e) {
        // Error al verificar, continuar normalmente
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Urgente';
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return 'Media';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return AppTheme.error;
      case 'high':
        return AppTheme.warning;
      case 'medium':
        return AppTheme.info;
      case 'low':
        return AppTheme.success;
      default:
        return AppTheme.info;
    }
  }

  Future<void> _createTicket() async {
    if (!_formKey.currentState!.validate()) return;

    // BLOQUEAR INMEDIATAMENTE para evitar múltiples clics
    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Aplicar restricción a TODOS los roles (admin, worker, user)
      final ticketService = TicketService();
      
      // Verificar ANTES de crear el ticket
      final hasOpen = await ticketService.hasOpenTickets(user.id);
      
      if (hasOpen) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ya tienes un ticket abierto',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        softWrap: true,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Debes cerrar tu ticket actual antes de crear uno nuevo',
                        style: TextStyle(fontSize: 12),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final selectedReason = _ticketReasons.firstWhere(
        (reason) => reason.id == _selectedReason,
      );

      final ticket = TicketModel(
        id: '',
        title: selectedReason.title,
        description: _descriptionController.text.trim(),
        createdBy: user.id,
        status: 'open',
        priority: selectedReason.priority,
        createdAt: DateTime.now(),
      );

      // Verificar tickets abiertos para TODOS los roles
      await ticketService.createTicket(
        ticket,
        checkOpenTickets: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Ticket creado exitosamente'),
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

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${e.toString()}')),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(width: double.infinity, height: double.infinity, 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF1A1A1A),
                    const Color(0xFF0F0F0F),
                  ]
                : [
                    const Color(0xFF0A0E27),
                    const Color(0xFF1A1F3A),
                    const Color(0xFF0F1419),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.darkBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppTheme.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crear Ticket',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              softWrap: true,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Describe tu problema o solicitud',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              softWrap: true,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Advertencia si tiene ticket abierto
                  if (_hasOpenTicket) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.warning,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ya tienes un ticket abierto',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warning,
                                  ),
                                  softWrap: true,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Debes cerrar tu ticket actual antes de crear uno nuevo',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                        softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Motivo del ticket
                  Text(
                    'Motivo del ticket',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedReason,
                      isExpanded: true,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Selecciona el motivo',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8).withValues(alpha: 0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.category_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.error,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      items: _ticketReasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason.id,
                          child: Text(
                            reason.title,
                                    softWrap: true,
                            maxLines: 2,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return _ticketReasons.map((reason) {
                          return Text(
                            reason.title,
                                    softWrap: true,
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          );
                        }).toList();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Debes seleccionar un motivo';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedReason = value;
                        });
                      },
                    ),
                  ),
                  
                  // Información de prioridad
                  if (_selectedReason != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          _ticketReasons
                              .firstWhere((r) => r.id == _selectedReason)
                              .priority,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getPriorityColor(
                            _ticketReasons
                                .firstWhere((r) => r.id == _selectedReason)
                                .priority,
                          ).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                _ticketReasons
                                    .firstWhere((r) => r.id == _selectedReason)
                                    .priority,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: _getPriorityColor(
                                _ticketReasons
                                    .firstWhere((r) => r.id == _selectedReason)
                                    .priority,
                              ),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prioridad asignada automáticamente',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  softWrap: true,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(
                                      _ticketReasons
                                          .firstWhere((r) => r.id == _selectedReason)
                                          .priority,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getPriorityText(
                                      _ticketReasons
                                          .firstWhere((r) => r.id == _selectedReason)
                                          .priority,
                                    ),
                                    style: GoogleFonts.inter(
                                      color: _getPriorityColor(
                                        _ticketReasons
                                            .firstWhere((r) => r.id == _selectedReason)
                                            .priority,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Descripción
                  Text(
                    'Descripción detallada',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe el problema o solicitud con más detalle...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8).withValues(alpha: 0.6),
                        ),
                        helperText: 'Proporciona información adicional sobre tu solicitud',
                        helperStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.error,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La descripción es requerida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón crear
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: (_isLoading || _hasOpenTicket)
                            ? [
                                AppTheme.primaryBlue.withValues(alpha: 0.6),
                                AppTheme.darkBlue.withValues(alpha: 0.6),
                              ]
                            : [
                                AppTheme.primaryBlue,
                                AppTheme.darkBlue,
                              ],
                      ),
                      boxShadow: (_isLoading || _hasOpenTicket)
                          ? []
                          : [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                                spreadRadius: 0,
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: AbsorbPointer(
                        absorbing: _isLoading || _hasOpenTicket,
                        child: InkWell(
                          onTap: _createTicket,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _hasOpenTicket ? 'Ticket Abierto' : 'Crear Ticket',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _hasOpenTicket 
                                            ? Icons.lock_outline_rounded
                                            : Icons.check_circle_outline_rounded,
                                        color: AppTheme.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
