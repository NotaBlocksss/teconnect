import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<List<MessageModel>> getMessagesByTicket(String ticketId) {
    return _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return MessageModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .whereType<MessageModel>()
            .toList());
  }

  Future<void> sendMessage(MessageModel message) async {
    try {
      if (message.ticketId.isEmpty) {
        throw Exception('El ID del ticket no puede estar vacío');
      }
      
      final messageData = message.toMap();
      messageData['status'] = 'sent';
      
      final docRef = await _firestore
          .collection('tickets')
          .doc(message.ticketId)
          .collection('messages')
          .add(messageData);
      
      // Actualizar updatedAt del ticket (sin esperar)
      _firestore.collection('tickets').doc(message.ticketId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((_) {
        // Error silencioso
      });
      
      // Verificar estado de entrega después de un pequeño delay para evitar actualizaciones múltiples
      if (message.type != 'system' && message.senderId != 'system' && docRef.id.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _checkAndUpdateDeliveryStatus(message.ticketId, docRef.id, message.senderId);
        });
      }
      
      if (message.type != 'system' && message.senderId != 'system') {
        try {
          if (docRef.id.isNotEmpty) {
            await _notificationService.sendToTicketUsers(
              ticketId: message.ticketId,
              title: 'Nuevo mensaje',
              body: '${message.senderName}: ${message.content.length > 50 ? message.content.substring(0, 50) + "..." : message.content}',
              excludeUserId: message.senderId,
              data: {
                'type': 'ticket_message',
                'ticketId': message.ticketId,
                'messageId': docRef.id,
              },
            );
          }
        } catch (e) {
          // Error silencioso
        }
      }
      
    } catch (e) {
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  Future<void> _checkAndUpdateDeliveryStatus(String ticketId, String messageId, String senderId) async {
    try {
      if (ticketId.isEmpty || messageId.isEmpty) {
        return;
      }
      
      // Obtener información del ticket para identificar al destinatario
      final ticketDoc = await _firestore.collection('tickets').doc(ticketId).get();
      if (!ticketDoc.exists) return;

      final ticketData = ticketDoc.data()!;
      final createdBy = ticketData['createdBy'] as String?;
      final assignedTo = ticketData['assignedTo'] as String?;

      // Determinar quién es el destinatario (el que no es el remitente)
      String? recipientId;
      if (createdBy == senderId) {
        recipientId = assignedTo;
      } else {
        recipientId = createdBy;
      }

      if (recipientId == null || recipientId.isEmpty) return;

      // Verificar si el destinatario está online
      final isRecipientOnline = await _checkUserOnlineStatus(recipientId);

      if (isRecipientOnline) {
        // Si el destinatario está online, marcar como "delivered" (sin await para no bloquear)
        _firestore
            .collection('tickets')
            .doc(ticketId)
            .collection('messages')
            .doc(messageId)
            .update({'status': 'delivered'})
            .catchError((_) {
              // Error silencioso
            });
      }
    } catch (e) {
      // Error silencioso
    }
  }

  Future<bool> _checkUserOnlineStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['isOnline'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateSentMessagesToDelivered(String ticketId, String recipientId) async {
    try {
      // Verificar que el destinatario esté online
      final userDoc = await _firestore.collection('users').doc(recipientId).get();
      final isOnline = userDoc.data()?['isOnline'] as bool? ?? false;

      if (!isOnline) return;

      // Actualizar todos los mensajes "sent" a "delivered" cuando el destinatario se conecta
      final snapshot = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .where('senderId', isNotEqualTo: recipientId)
          .where('status', isEqualTo: 'sent')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'delivered'});
      }
      await batch.commit();
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> markMessageAsRead(String ticketId, String messageId) async {
    try {
      await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .doc(messageId)
          .update({'status': 'read'});
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> markAllMessagesAsRead(String ticketId, String userId) async {
    try {
      // Verificar que el usuario esté realmente viendo el ticket
      final viewerDoc = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('viewers')
          .doc(userId)
          .get();

      // Solo marcar como leído si el usuario está viendo el ticket
      if (!viewerDoc.exists) return;

      final snapshot = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    } catch (e) {
      // Error silencioso
    }
  }
}

