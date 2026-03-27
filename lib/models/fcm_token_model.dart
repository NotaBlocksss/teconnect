import 'package:cloud_firestore/cloud_firestore.dart';

class FCMTokenModel {
  final String deviceId;
  final String token;
  final String deviceName;
  final String platform;
  final DateTime createdAt;
  final DateTime lastUpdated;

  FCMTokenModel({
    required this.deviceId,
    required this.token,
    required this.deviceName,
    required this.platform,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'token': token,
      'deviceName': deviceName,
      'platform': platform,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory FCMTokenModel.fromMap(Map<String, dynamic> map, String deviceId) {
    return FCMTokenModel(
      deviceId: deviceId,
      token: map['token'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? 'Dispositivo desconocido',
      platform: map['platform'] as String? ?? 'unknown',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  FCMTokenModel copyWith({
    String? deviceId,
    String? token,
    String? deviceName,
    String? platform,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return FCMTokenModel(
      deviceId: deviceId ?? this.deviceId,
      token: token ?? this.token,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

