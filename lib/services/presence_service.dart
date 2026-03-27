import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> setUserViewingTicket(String userId, String ticketId) async {
    try {
      if (userId.isEmpty || ticketId.isEmpty) {
        return;
      }
      await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('viewers')
          .doc(userId)
          .set({
        'userId': userId,
        'viewingAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> removeUserViewingTicket(String userId, String ticketId) async {
    try {
      if (userId.isEmpty || ticketId.isEmpty) {
        return;
      }
      await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('viewers')
          .doc(userId)
          .delete();
    } catch (e) {
      // Error silencioso
    }
  }

  Future<List<String>> getUsersViewingTicket(String ticketId) async {
    try {
      if (ticketId.isEmpty) {
        return [];
      }
      final snapshot = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('viewers')
          .get();

      return snapshot.docs.map((doc) => doc.id).where((id) => id.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> setUserOnline(String userId) async {
    try {
      if (userId.isEmpty) {
        return;
      }
      await _firestore.collection('users').doc(userId).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'lastHeartbeat': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> updateHeartbeat(String userId) async {
    try {
      if (userId.isEmpty) {
        return;
      }
      await _firestore.collection('users').doc(userId).update({
        'lastHeartbeat': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> setUserOffline(String userId) async {
    try {
      if (userId.isEmpty) {
        return;
      }
      await _firestore.collection('users').doc(userId).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error silencioso
    }
  }

  Stream<bool> isUserOnline(String userId) {
    if (userId.isEmpty) {
      return Stream.value(false);
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return false;
      
      final isOnline = data['isOnline'] as bool? ?? false;
      if (!isOnline) return false;
      
      final lastHeartbeat = data['lastHeartbeat'] as Timestamp?;
      if (lastHeartbeat == null) return false;
      
      final now = DateTime.now();
      final heartbeatTime = lastHeartbeat.toDate();
      final difference = now.difference(heartbeatTime);
      
      return difference.inMinutes < 3;
    });
  }

  Future<void> setUserTyping(String userId, String ticketId, bool isTyping) async {
    try {
      if (userId.isEmpty || ticketId.isEmpty) {
        return;
      }
      if (isTyping) {
        await _firestore
            .collection('tickets')
            .doc(ticketId)
            .collection('typing')
            .doc(userId)
            .set({
          'userId': userId,
          'isTyping': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore
            .collection('tickets')
            .doc(ticketId)
            .collection('typing')
            .doc(userId)
            .delete();
      }
    } catch (e) {
      // Error silencioso
    }
  }

  Stream<List<String>> getTypingUsers(String ticketId) {
    if (ticketId.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('typing')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['isTyping'] == true)
            .map((doc) => doc.id)
            .where((id) => id.isNotEmpty)
            .toList());
  }
}

