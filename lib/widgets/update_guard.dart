import 'package:flutter/material.dart';
import '../services/app_updater_service.dart';
import 'update_dialog.dart';

class UpdateGuard extends StatefulWidget {
  final Widget child;

  const UpdateGuard({
    super.key,
    required this.child,
  });

  @override
  State<UpdateGuard> createState() => _UpdateGuardState();
}

class _UpdateGuardState extends State<UpdateGuard> {
  final AppUpdaterService _updaterService = AppUpdaterService.instance;
  bool _isChecking = false;
  bool _hasRequiredUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkForRequiredUpdate();
  }

  Future<void> _checkForRequiredUpdate() async {
    if (_isChecking || _hasRequiredUpdate) return;

    _isChecking = true;

    try {
      final updateInfo = await _updaterService.checkForUpdates(forceCheck: false);
      
      if (updateInfo != null && updateInfo.isRequired && mounted) {
        setState(() {
          _hasRequiredUpdate = true;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => UpdateDialog(updateInfo: updateInfo),
            );
          }
        });
      }
    } catch (e) {
      // Error silencioso
    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRequiredUpdate) {
      return Scaffold(
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return widget.child;
  }
}

