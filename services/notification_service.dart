import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'presence_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PresenceService _presenceService = PresenceService();

  Future<String?> _getServerUrl() async {
    try {
      final doc = await _firestore.collection('config').doc('fcm').get();
      if (doc.exists) {
        return doc.data()?['serverUrl'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> _getAllUserTokens() async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .limit(1000)
          .get();
      
      final futures = usersSnapshot.docs.map((userDoc) async {
        try {
          final tokensSnapshot = await userDoc.reference
              .collection('fcmTokens')
              .limit(10)
              .get();
          
          return tokensSnapshot.docs
              .map((tokenDoc) => tokenDoc.data()['token'] as String?)
              .where((token) => token != null && token.isNotEmpty)
              .cast<String>()
              .toList();
        } catch (e) {
          return <String>[];
        }
      });

      final results = await Future.wait(futures);
      return results.expand((tokens) => tokens).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getAdminAndWorkerTokens() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['admin', 'worker'])
          .limit(500)
          .get();

      final futures = snapshot.docs.map((userDoc) async {
        try {
          final tokensSnapshot = await userDoc.reference
              .collection('fcmTokens')
              .limit(10)
              .get();
          
          return tokensSnapshot.docs
              .map((tokenDoc) => tokenDoc.data()['token'] as String?)
              .where((token) => token != null && token.isNotEmpty)
              .cast<String>()
              .toList();
        } catch (e) {
          return <String>[];
        }
      });

      final results = await Future.wait(futures);
      return results.expand((tokens) => tokens).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getTicketRelatedTokens(
    String ticketId,
    String excludeUserId,
  ) async {
    try {
      if (ticketId.isEmpty) {
        return [];
      }
      final ticketDoc = await _firestore.collection('tickets').doc(ticketId).get();
      if (!ticketDoc.exists) return [];

      final ticketData = ticketDoc.data();
      final createdBy = ticketData?['createdBy'] as String?;
      final assignedTo = ticketData?['assignedTo'] as String?;

      // Solo notificar al creador y al asignado
      final Set<String> userIds = {};
      if (createdBy != null) userIds.add(createdBy);
      if (assignedTo != null) userIds.add(assignedTo);

      // Excluir al remitente
      userIds.remove(excludeUserId);

      // Obtener usuarios que están viendo el ticket
      final viewers = await _presenceService.getUsersViewingTicket(ticketId);
      
      // Excluir a quienes están viendo el ticket
      userIds.removeAll(viewers);

      final futures = userIds.where((userId) => userId.isNotEmpty).map((userId) async {
        try {
          final tokensSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('fcmTokens')
              .limit(10)
              .get();
          
          return tokensSnapshot.docs
              .map((tokenDoc) => tokenDoc.data()['token'] as String?)
              .where((token) => token != null && token.isNotEmpty)
              .cast<String>()
              .toList();
        } catch (e) {
          return <String>[];
        }
      });

      final results = await Future.wait(futures);
      return results.expand((tokens) => tokens).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> sendToAllUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final tokens = await _getAllUserTokens();
    if (tokens.isEmpty) return;

    await _sendNotification(tokens: tokens, title: title, body: body, data: data);
  }

  Future<void> sendToAdminsAndWorkers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final tokens = await _getAdminAndWorkerTokens();
    if (tokens.isEmpty) return;

    await _sendNotification(tokens: tokens, title: title, body: body, data: data);
  }

  Future<void> sendToTicketUsers({
    required String ticketId,
    required String title,
    required String body,
    required String excludeUserId,
    Map<String, dynamic>? data,
  }) async {
    if (ticketId.isEmpty) {
      return;
    }
    final tokens = await _getTicketRelatedTokens(ticketId, excludeUserId);
    if (tokens.isEmpty) return;

    await _sendNotification(tokens: tokens, title: title, body: body, data: data);
  }

  Future<void> sendToSpecificUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? sound,
    int? priority,
  }) async {
    final tokens = <String>[];
    
    final futures = userIds.where((userId) => userId.isNotEmpty).map((userId) async {
      try {
        final tokensSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('fcmTokens')
            .limit(10)
            .get();
        
        return tokensSnapshot.docs
            .map((tokenDoc) => tokenDoc.data()['token'] as String?)
            .where((token) => token != null && token.isNotEmpty)
            .cast<String>()
            .toList();
      } catch (e) {
        return <String>[];
      }
    });

    final results = await Future.wait(futures);
    tokens.addAll(results.expand((tokens) => tokens));
    
    if (tokens.isEmpty) return;

    await _sendNotification(
      tokens: tokens,
      title: title,
      body: body,
      data: data,
      imageUrl: imageUrl,
      sound: sound,
      priority: priority,
    );
  }

  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? sound,
    int? priority,
  }) async {
    try {
      if (userId.isEmpty) {
        return;
      }
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .limit(10)
          .get();

      final tokens = tokensSnapshot.docs
          .map((doc) => doc.data()['token'] as String? ?? '')
          .where((token) => token.isNotEmpty)
          .toList();
      
      if (tokens.isEmpty) return;

      await _sendNotification(
        tokens: tokens,
        title: title,
        body: body,
        data: data,
        imageUrl: imageUrl,
        sound: sound,
        priority: priority,
      );
    } catch (e) {
      throw Exception('Error al enviar notificación a usuario: $e');
    }
  }

  Future<void> _sendNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? sound,
    int? priority,
  }) async {
    if (tokens.isEmpty) return;

    final serverUrl = await _getServerUrl();
    if (serverUrl == null || serverUrl.isEmpty) {
      throw Exception('ServerUrl no configurado en Firestore: config/fcm/serverUrl');
    }

    final notificationData = <String, dynamic>{};
    if (data != null) {
      notificationData.addAll(data);
    }

    final notificationPayload = <String, dynamic>{
      'title': title,
      'body': body,
    };

    if (imageUrl != null) {
      notificationPayload['image'] = imageUrl;
    }

    final payload = <String, dynamic>{
      'tokens': tokens,
      'notification': notificationPayload,
      'data': notificationData,
    };

    if (sound != null) {
      payload['sound'] = sound;
    }

    if (priority != null) {
      payload['priority'] = priority;
    }

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/send-notification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al enviar notificación');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error FCM: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al enviar notificación: $e');
    }
  }
}

