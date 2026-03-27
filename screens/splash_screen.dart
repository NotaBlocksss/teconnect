import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'user/user_home_screen.dart';
import 'worker/worker_home_screen.dart';
import 'admin/admin_home_screen.dart';
import '../services/app_updater_service.dart';
import '../widgets/update_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color _bluePrimary = Color(0xFF2196F3);
  static const Color _blueDark = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _fadeController.forward();
    _navigateToHome();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final updaterService = AppUpdaterService.instance;
    
    final updateInfo = await updaterService.checkForUpdates(forceCheck: true);
    
    if (updateInfo != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: !updateInfo.isRequired,
            builder: (context) => UpdateDialog(updateInfo: updateInfo),
          );
        }
      });
      
      if (updateInfo.isRequired) {
        return;
      }
    }

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await _waitForAuthState(authProvider);

    if (!mounted) return;

    final user = authProvider.currentUser;

    if (user != null) {
      if (mounted) {
        _navigateByRole(user.role);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _waitForAuthState(AuthProvider authProvider) async {
    int attempts = 0;
    const maxAttempts = 20;

    while (attempts < maxAttempts && mounted) {
      if (authProvider.currentUser != null) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  void _navigateByRole(String role) {
    if (!mounted) return;
    
    Widget screen;
    switch (role) {
      case 'admin':
        screen = const AdminHomeScreen();
        break;
      case 'worker':
        screen = const WorkerHomeScreen();
        break;
      default:
        screen = const UserHomeScreen();
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _bluePrimary,
              _blueDark,
              const Color(0xFF1565C0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/logologin.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
