import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import 'notification_service.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Obtener la alerta activa más reciente
  Stream<AlertModel?> getActiveAlert() {
    return _firestore
        .collection('alerts')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      
      try {
        final alert = AlertModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
        return alert.isExpired ? null : alert;
      } catch (e) {
        return null;
      }
    });
  }

  Stream<List<AlertModel>> getAllAlerts() {
    return _firestore
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return AlertModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .whereType<AlertModel>()
            .toList());
  }

  // Crear nueva alerta
  Future<String> createAlert(AlertModel alert) async {
    try {
      final docRef = await _firestore.collection('alerts').add(alert.toMap());
      
      // Desactivar alertas anteriores
      await _firestore
          .collection('alerts')
          .where('isActive', isEqualTo: true)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          if (doc.id != docRef.id) {
            doc.reference.update({'isActive': false});
          }
        }
      });
      
      try {
        await _notificationService.sendToAllUsers(
          title: alert.title,
          body: alert.message,
          data: {
            'type': 'alert',
            'alertId': docRef.id,
          },
        );
      } catch (e) {
        // Error silencioso
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear alerta: $e');
    }
  }

  // Desactivar alerta
  Future<void> deactivateAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Error al desactivar alerta: $e');
    }
  }

  // Eliminar alerta
  Future<void> deleteAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).delete();
    } catch (e) {
      throw Exception('Error al eliminar alerta: $e');
    }
  }
}

