import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'fcm_background_handler.dart';
import '../models/fcm_token_model.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _currentToken;
  String? _currentUserId;
  String? _currentDeviceId;
  Timer? _tokenRefreshTimer;

  Future<void> initialize() async {
    await _requestPermission();
    await _initializeLocalNotifications();
    await _setupMessageHandlers();
    await _getToken();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Canal para notificaciones importantes',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones Importantes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  Future<void> _getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null && _currentUserId != null) {
        await _saveTokenToFirestore(_currentUserId!, _currentToken!);
      }
    } catch (e) {
      // Error silencioso
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      if (_currentUserId != null) {
        _saveTokenToFirestore(_currentUserId!, newToken);
      }
    });
  }

  Future<String> _getDeviceId() async {
    if (_currentDeviceId != null) {
      return _currentDeviceId!;
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _currentDeviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _currentDeviceId = iosInfo.identifierForVendor ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        _currentDeviceId = 'unknown-${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      _currentDeviceId = 'error-${DateTime.now().millisecondsSinceEpoch}';
    }

    return _currentDeviceId!;
  }

  Future<String> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      } else {
        return 'Dispositivo desconocido';
      }
    } catch (e) {
      return 'Dispositivo desconocido';
    }
  }

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  Future<void> setupUser(String userId) async {
    _currentUserId = userId;
    if (_currentToken != null) {
      await _saveTokenToFirestore(userId, _currentToken!);
    } else {
      await _getToken();
    }
    
    _startTokenRefreshTimer();
    _cleanupObsoleteTokens(userId);
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();
      final platform = _getPlatform();
      final now = DateTime.now();

      final tokenData = FCMTokenModel(
        deviceId: deviceId,
        token: token,
        deviceName: deviceName,
        platform: platform,
        createdAt: now,
        lastUpdated: now,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(deviceId)
          .set(tokenData.toMap());
    } catch (e) {
      // Error silencioso
    }
  }

  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    
    _tokenRefreshTimer = Timer.periodic(const Duration(days: 7), (timer) async {
      if (_currentUserId != null && _currentToken != null) {
        print('🔄 Actualizando token FCM (renovación semanal)');
        await _getToken();
        if (_currentToken != null && _currentUserId != null) {
          await _saveTokenToFirestore(_currentUserId!, _currentToken!);
        }
      }
    });
  }

  Future<void> _cleanupObsoleteTokens(String userId) async {
    try {
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .get();

      final now = DateTime.now();
      final obsoleteThreshold = now.subtract(const Duration(days: 30));

      final batch = _firestore.batch();
      int deletedCount = 0;

      for (var doc in tokensSnapshot.docs) {
        final data = doc.data();
        final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate();
        
        if (lastUpdated != null && lastUpdated.isBefore(obsoleteThreshold)) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      print('❌ Error al limpiar tokens obsoletos: $e');
    }
  }

  Future<void> removeUser() async {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    
    if (_currentUserId != null && _currentDeviceId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('fcmTokens')
            .doc(_currentDeviceId!)
            .delete();
      } catch (e) {
        // Error silencioso
      }
    }
    _currentUserId = null;
    _currentDeviceId = null;
  }

  Future<List<String>> getUserTokens(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['token'] as String? ?? '')
          .where((token) => token.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> refreshToken() async {
    if (_currentUserId != null) {
      await _getToken();
      if (_currentToken != null && _currentUserId != null) {
        await _saveTokenToFirestore(_currentUserId!, _currentToken!);
      }
    }
  }

  String? get currentToken => _currentToken;
}

