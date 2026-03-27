import 'package:cloud_firestore/cloud_firestore.dart';

class AppVersionModel {
  final String version;
  final int buildNumber;
  final bool isRequired;
  final bool isActive;
  final String platform;
  final String? downloadUrlAndroid;
  final String? downloadUrlIOS;
  final String? releaseNotes;
  final DateTime releaseDate;
  final String? minSupportedVersion;
  final Map<String, dynamic>? metadata;

  AppVersionModel({
    required this.version,
    required this.buildNumber,
    required this.isRequired,
    this.isActive = true,
    required this.platform,
    this.downloadUrlAndroid,
    this.downloadUrlIOS,
    this.releaseNotes,
    required this.releaseDate,
    this.minSupportedVersion,
    this.metadata,
  });

  factory AppVersionModel.fromMap(Map<String, dynamic> map, String id) {
    return AppVersionModel(
      version: map['version'] as String? ?? '',
      buildNumber: (map['buildNumber'] as num?)?.toInt() ?? 0,
      isRequired: map['isRequired'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      platform: map['platform'] as String? ?? 'android',
      downloadUrlAndroid: map['downloadUrlAndroid'] as String?,
      downloadUrlIOS: map['downloadUrlIOS'] as String?,
      releaseNotes: map['releaseNotes'] as String?,
      releaseDate: map['releaseDate'] != null
          ? (map['releaseDate'] as Timestamp).toDate()
          : DateTime.now(),
      minSupportedVersion: map['minSupportedVersion'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'isRequired': isRequired,
      'isActive': isActive,
      'platform': platform,
      'downloadUrlAndroid': downloadUrlAndroid,
      'downloadUrlIOS': downloadUrlIOS,
      'releaseNotes': releaseNotes,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'minSupportedVersion': minSupportedVersion,
      'metadata': metadata,
    };
  }

  AppVersionModel copyWith({
    String? version,
    int? buildNumber,
    bool? isRequired,
    bool? isActive,
    String? platform,
    String? downloadUrlAndroid,
    String? downloadUrlIOS,
    String? releaseNotes,
    DateTime? releaseDate,
    String? minSupportedVersion,
    Map<String, dynamic>? metadata,
  }) {
    return AppVersionModel(
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      isRequired: isRequired ?? this.isRequired,
      isActive: isActive ?? this.isActive,
      platform: platform ?? this.platform,
      downloadUrlAndroid: downloadUrlAndroid ?? this.downloadUrlAndroid,
      downloadUrlIOS: downloadUrlIOS ?? this.downloadUrlIOS,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      releaseDate: releaseDate ?? this.releaseDate,
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
      metadata: metadata ?? this.metadata,
    );
  }
}

