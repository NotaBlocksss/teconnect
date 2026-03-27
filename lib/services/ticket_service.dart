import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';
import 'notification_service.dart';
import 'message_service.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final MessageService _messageService = MessageService();

  Stream<List<TicketModel>> getTicketsByUser(String userId) {
    return _firestore
        .collection('tickets')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return TicketModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .whereType<TicketModel>()
            .toList());
  }

  Stream<List<TicketModel>> getAllTickets() {
    return _firestore
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return TicketModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .whereType<TicketModel>()
            .toList());
  }

  Stream<List<TicketModel>> getTicketsAssignedTo(String userId) {
    return _firestore
        .collection('tickets')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return TicketModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .whereType<TicketModel>()
            .toList());
  }

  // Verificar si un usuario tiene tickets abiertos
  // Un ticket está abierto si su estado NO es 'resolved' ni 'closed'
  Future<bool> hasOpenTickets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('createdBy', isEqualTo: userId)
          .where('status', whereIn: ['open', 'in_progress', 'pending'])
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return true;
    }
  }

  Future<String> createTicket(TicketModel ticket, {bool checkOpenTickets = true}) async {
    try {
      // Si se solicita verificar tickets abiertos, hacerlo antes de crear
      if (checkOpenTickets) {
        final hasOpen = await hasOpenTickets(ticket.createdBy);
        if (hasOpen) {
          throw Exception('Ya tienes un ticket abierto. Debes cerrarlo antes de crear uno nuevo.');
        }
      }
      
      final docRef = await _firestore.collection('tickets').add(ticket.toMap());
      
      // Agregar al creador como participante
      await _firestore.collection('tickets').doc(docRef.id).update({
        'participants': FieldValue.arrayUnion([ticket.createdBy]),
      });
      
      // Crear mensaje del sistema con el título y descripción del ticket
      try {
        final systemMessage = MessageModel(
          id: '',
          ticketId: docRef.id,
          senderId: 'system',
          senderName: 'Sistema',
          content: 'TITULO: ${ticket.title}\n\nDESCRIPCION: ${ticket.description}',
          timestamp: DateTime.now(),
          type: 'system',
          status: 'read',
        );
        
        await _messageService.sendMessage(systemMessage);
      } catch (e) {
        // Error silencioso
      }
      
      try {
        await _notificationService.sendToAdminsAndWorkers(
          title: 'Nuevo ticket creado',
          body: ticket.title,
          data: {
            'type': 'ticket',
            'ticketId': docRef.id,
          },
        );
      } catch (e) {
        // Error silencioso
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear ticket: $e');
    }
  }

  Future<void> updateTicket(TicketModel ticket) async {
    try {
      await _firestore
          .collection('tickets')
          .doc(ticket.id)
          .update(ticket.toMap());
    } catch (e) {
      throw Exception('Error al actualizar ticket: $e');
    }
  }

  Future<void> assignTicket(String ticketId, String userId) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'assignedTo': userId,
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Error al asignar ticket: $e');
    }
  }

  Future<TicketModel?> getTicketById(String ticketId) async {
    try {
      final doc = await _firestore.collection('tickets').doc(ticketId).get();
      if (doc.exists) {
        return TicketModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener ticket: $e');
    }
  }

  Future<void> closeTicket(String ticketId, String reason) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'status': 'closed',
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al cerrar ticket: $e');
    }
  }
}

