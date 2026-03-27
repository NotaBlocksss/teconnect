import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_updater_service.dart';

class AppUpdaterProvider with ChangeNotifier {
  final AppUpdaterService _updaterService = AppUpdaterService.instance;
  AppUpdateInfo? _updateInfo;
  bool _isChecking = false;
  Timer? _periodicCheckTimer;

  AppUpdateInfo? get updateInfo => _updateInfo;
  bool get isChecking => _isChecking;
  bool get hasUpdate => _updateInfo != null;

  AppUpdaterProvider() {
    _init();
  }

  void _init() {
    _checkForUpdates();
    _startPeriodicCheck();
  }

  Future<void> _checkForUpdates({bool forceCheck = false}) async {
    if (_isChecking && !forceCheck) return;

    _isChecking = true;
    notifyListeners();

    try {
      final updateInfo = await _updaterService.checkForUpdates(forceCheck: forceCheck);
      _updateInfo = updateInfo;
    } catch (e) {
      _updateInfo = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => _checkForUpdates(),
    );
  }

  Future<void> checkForUpdates({bool forceCheck = false}) async {
    await _checkForUpdates(forceCheck: forceCheck);
  }

  Future<void> openDownloadUrl() async {
    if (_updateInfo?.downloadUrl != null) {
      await _updaterService.openDownloadUrl(_updateInfo!.downloadUrl);
    }
  }

  void clearUpdateInfo() {
    _updateInfo = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}

