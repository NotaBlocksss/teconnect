import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_version_model.dart';

class AppUpdateInfo {
  final String version;
  final int buildNumber;
  final bool isRequired;
  final String? downloadUrl;
  final String? releaseNotes;
  final DateTime? releaseDate;
  final String? minSupportedVersion;

  AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.isRequired,
    this.downloadUrl,
    this.releaseNotes,
    this.releaseDate,
    this.minSupportedVersion,
  });

  factory AppUpdateInfo.fromVersionModel(AppVersionModel model, String? downloadUrl) {
    return AppUpdateInfo(
      version: model.version,
      buildNumber: model.buildNumber,
      isRequired: model.isRequired,
      downloadUrl: downloadUrl,
      releaseNotes: model.releaseNotes,
      releaseDate: model.releaseDate,
      minSupportedVersion: model.minSupportedVersion,
    );
  }
}

class AppUpdaterService {
  static AppUpdaterService? _instance;
  static AppUpdaterService get instance {
    _instance ??= AppUpdaterService._();
    return _instance!;
  }

  AppUpdaterService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  PackageInfo? _cachedPackageInfo;
  DateTime? _lastCheckTime;
  AppUpdateInfo? _cachedUpdateInfo;
  static const Duration _cacheDuration = Duration(minutes: 15);
  static const Duration _queryTimeout = Duration(seconds: 10);

  Future<PackageInfo> _getPackageInfo() async {
    if (_cachedPackageInfo == null) {
      _cachedPackageInfo = await PackageInfo.fromPlatform();
    }
    return _cachedPackageInfo!;
  }

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  Future<AppUpdateInfo?> checkForUpdates({bool forceCheck = false}) async {
    try {
      if (!forceCheck && _cachedUpdateInfo != null && _lastCheckTime != null) {
        final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
        if (timeSinceLastCheck < _cacheDuration) {
          final packageInfo = await _getPackageInfo();
          final currentVersion = packageInfo.version;
          final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

          final isStillGreater = _isVersionGreater(
            _cachedUpdateInfo!.version,
            currentVersion,
            _cachedUpdateInfo!.buildNumber,
            currentBuildNumber,
          );

          if (isStillGreater) {
            return _cachedUpdateInfo;
          }
        }
      }

      final packageInfo = await _getPackageInfo();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      final platform = _getPlatform();

      AppUpdateInfo? updateInfo = await _checkNewStructure(platform, currentVersion, currentBuildNumber);
      
      if (updateInfo == null) {
        updateInfo = await _checkOldStructure(currentVersion, currentBuildNumber);
      }

      if (updateInfo != null) {
        _cachedUpdateInfo = updateInfo;
        _lastCheckTime = DateTime.now();
      } else {
        _lastCheckTime = DateTime.now();
      }

      return updateInfo;
    } catch (e) {
      return null;
    }
  }

  Future<AppUpdateInfo?> _checkNewStructure(
    String platform,
    String currentVersion,
    int currentBuildNumber,
  ) async {
    try {
      final platformLower = platform.toLowerCase();
      
      QuerySnapshot snapshot;
      
      try {
        final query = _firestore
            .collection('app_versions')
            .where('isActive', isEqualTo: true)
            .where('platform', isEqualTo: platformLower)
            .orderBy('releaseDate', descending: true)
            .limit(1);

        snapshot = await query
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(_queryTimeout);
      } catch (e) {
        final queryWithoutOrder = _firestore
            .collection('app_versions')
            .where('isActive', isEqualTo: true)
            .limit(50);

        snapshot = await queryWithoutOrder
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(_queryTimeout);
      }

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final matchingDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        final docPlatform = (data['platform'] as String? ?? '').toLowerCase();
        return docPlatform == platformLower;
      }).toList();

      if (matchingDocs.isEmpty) {
        return null;
      }

      matchingDocs.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>?;
        final dataB = b.data() as Map<String, dynamic>?;
        final dateA = dataA?['releaseDate'] as Timestamp?;
        final dateB = dataB?['releaseDate'] as Timestamp?;
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      final versionData = matchingDocs.first.data() as Map<String, dynamic>;
      final versionModel = AppVersionModel.fromMap(
        versionData,
        matchingDocs.first.id,
      );

      if (versionModel.version.isEmpty) {
        return null;
      }

      final isGreater = _isVersionGreater(
        versionModel.version,
        currentVersion,
        versionModel.buildNumber,
        currentBuildNumber,
      );

      if (!isGreater) {
        return null;
      }

      final downloadUrl = platformLower == 'android'
          ? versionModel.downloadUrlAndroid
          : versionModel.downloadUrlIOS;

      if (downloadUrl == null || downloadUrl.isEmpty) {
        return null;
      }

      final updateInfo = AppUpdateInfo.fromVersionModel(versionModel, downloadUrl);

      bool isRequired = versionModel.isRequired;

      if (versionModel.minSupportedVersion != null && versionModel.minSupportedVersion!.isNotEmpty) {
        final isBelowMinimum = _isVersionBelowMinimum(
          versionModel.minSupportedVersion!,
          currentVersion,
        );
        if (isBelowMinimum) {
          isRequired = true;
        }
      }

      return updateInfo.copyWith(isRequired: isRequired);
    } catch (e) {
      return null;
    }
  }

  Future<AppUpdateInfo?> _checkOldStructure(
    String currentVersion,
    int currentBuildNumber,
  ) async {
    try {
      final updateDoc = await _firestore
          .collection('app_config')
          .doc('updates')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(_queryTimeout);

      if (!updateDoc.exists) {
        return null;
      }

      final data = updateDoc.data();
      if (data == null) {
        return null;
      }

      final latestVersion = data['latestVersion'] as String? ?? '';
      final isRequired = data['isRequired'] as bool? ?? false;
      final downloadUrl = data['downloadUrl'] as String?;
      final releaseNotes = data['releaseNotes'] as String?;
      final releaseDate = data['releaseDate'] != null
          ? (data['releaseDate'] as Timestamp).toDate()
          : null;

      if (latestVersion.isEmpty) {
        return null;
      }

      final isGreater = _isVersionGreater(
        latestVersion,
        currentVersion,
        0,
        currentBuildNumber,
      );

      if (!isGreater) {
        return null;
      }

      if (downloadUrl == null || downloadUrl.isEmpty) {
        return null;
      }

      return AppUpdateInfo(
        version: latestVersion,
        buildNumber: 0,
        isRequired: isRequired,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        releaseDate: releaseDate,
      );
    } catch (e) {
      return null;
    }
  }

  bool _isVersionBelowMinimum(String minVersion, String currentVersion) {
    try {
      if (minVersion.isEmpty || currentVersion.isEmpty) {
        return false;
      }

      final minParts = minVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < minParts.length; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (currentPart < minParts[i]) {
          return true;
        }
        if (currentPart > minParts[i]) {
          return false;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  bool _isVersionGreater(
    String latestVersion,
    String currentVersion,
    int latestBuildNumber,
    int currentBuildNumber,
  ) {
    try {
      if (latestVersion.isEmpty || currentVersion.isEmpty) {
        return false;
      }

      final latestParts = latestVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (latestParts[i] > currentPart) {
          return true;
        }
        if (latestParts[i] < currentPart) {
          return false;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> openDownloadUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return {'success': false, 'error': 'URL vacía o nula'};
    }

    try {
      Uri uri;
      
      try {
        uri = Uri.parse(url);
        
        if (!uri.hasScheme) {
          uri = Uri.parse('https://$url');
        }
      } catch (e) {
        return {'success': false, 'error': 'URL inválida: $url'};
      }

      final result = await _tryLaunchUrl(uri);
      return result;
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado: $e'};
    }
  }

  Future<Map<String, dynamic>> _tryLaunchUrl(Uri uri) async {
    final List<LaunchMode> modes = [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppWebView,
    ];

    for (final mode in modes) {
      try {
        final launched = await launchUrl(uri, mode: mode);
        if (launched) {
          return {'success': true, 'error': null, 'mode': mode.toString()};
        }
      } catch (e) {
        continue;
      }
    }

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        return {
          'success': false,
          'error': 'No hay aplicación disponible para abrir esta URL. URL: ${uri.toString()}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al verificar URL: $e. URL: ${uri.toString()}',
      };
    }

    return {
      'success': false,
      'error': 'No se pudo abrir la URL después de intentar todos los modos. URL: ${uri.toString()}',
    };
  }

  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await _getPackageInfo();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  Future<int> getCurrentBuildNumber() async {
    try {
      final packageInfo = await _getPackageInfo();
      return int.tryParse(packageInfo.buildNumber) ?? 1;
    } catch (e) {
      return 1;
    }
  }

  Future<Map<String, dynamic>> debugCheck() async {
    final result = <String, dynamic>{};
    
    try {
      final packageInfo = await _getPackageInfo();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      final platform = _getPlatform();
      final platformLower = platform.toLowerCase();
      
      result['currentVersion'] = currentVersion;
      result['currentBuildNumber'] = currentBuildNumber;
      result['platform'] = platform;
      result['platformLower'] = platformLower;
      
      try {
        final query = _firestore
            .collection('app_versions')
            .where('isActive', isEqualTo: true)
            .limit(50);
        
        final snapshot = await query.get(const GetOptions(source: Source.server));
        result['totalDocuments'] = snapshot.docs.length;
        
        final allDocs = snapshot.docs.map((doc) {
          final data = doc.data();
          final docPlatform = (data['platform'] as String? ?? '').toLowerCase();
          return {
            'id': doc.id,
            'version': data['version'],
            'buildNumber': data['buildNumber'],
            'platform': data['platform'],
            'platformLower': docPlatform,
            'isActive': data['isActive'],
            'downloadUrlAndroid': data['downloadUrlAndroid'],
            'downloadUrlIOS': data['downloadUrlIOS'],
            'matchesPlatform': docPlatform == platformLower,
          };
        }).toList();
        
        result['documents'] = allDocs;
        
        final matchingDocs = allDocs.where((doc) => doc['matchesPlatform'] == true).toList();
        result['documentsFound'] = matchingDocs.length;
        
        if (matchingDocs.isNotEmpty) {
          matchingDocs.sort((a, b) {
            final versionA = a['version'] as String? ?? '';
            final versionB = b['version'] as String? ?? '';
            final buildA = (a['buildNumber'] as num?)?.toInt() ?? 0;
            final buildB = (b['buildNumber'] as num?)?.toInt() ?? 0;
            
            final partsA = versionA.split('.').map(int.tryParse).toList();
            final partsB = versionB.split('.').map(int.tryParse).toList();
            
            for (int i = 0; i < partsA.length && i < partsB.length; i++) {
              final aVal = partsA[i] ?? 0;
              final bVal = partsB[i] ?? 0;
              if (aVal != bVal) {
                return bVal.compareTo(aVal);
              }
            }
            
            return buildB.compareTo(buildA);
          });
          
          final latestDoc = matchingDocs.first;
          final latestVersion = latestDoc['version'] as String? ?? '';
          final latestBuild = (latestDoc['buildNumber'] as num?)?.toInt() ?? 0;
          
          result['latestVersion'] = latestVersion;
          result['latestBuildNumber'] = latestBuild;
          result['isNewer'] = _isVersionGreater(
            latestVersion,
            currentVersion,
            latestBuild,
            currentBuildNumber,
          );
        }
      } catch (e) {
        result['error'] = e.toString();
      }
    } catch (e) {
      result['error'] = e.toString();
    }
    
    return result;
  }

  void clearCache() {
    _cachedPackageInfo = null;
    _lastCheckTime = null;
    _cachedUpdateInfo = null;
  }
}

extension AppUpdateInfoExtension on AppUpdateInfo {
  AppUpdateInfo copyWith({
    String? version,
    int? buildNumber,
    bool? isRequired,
    String? downloadUrl,
    String? releaseNotes,
    DateTime? releaseDate,
    String? minSupportedVersion,
  }) {
    return AppUpdateInfo(
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      isRequired: isRequired ?? this.isRequired,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      releaseDate: releaseDate ?? this.releaseDate,
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
    );
  }
}
