import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/fcm_service.dart';
import 'services/fcm_background_handler.dart';
import 'services/navigation_service.dart';
import 'services/presence_service.dart';
import 'services/invoice_scheduler_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/update_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  final fcmService = FCMService();
  await fcmService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Teconnect Support',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            navigatorKey: NavigationService.navigatorKey,
            home: UpdateGuard(
              child: const AppLifecycleWrapper(child: SplashScreen()),
            ),
          );
        },
      ),
    );
  }
}

class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({super.key, required this.child});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> with WidgetsBindingObserver {
  final PresenceService _presenceService = PresenceService();
  String? _currentUserId;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePresence();
    });
  }

  void _initializePresence() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      _presenceService.setUserOnline(user.id);
      _startHeartbeat();
      // Verificar y enviar facturas automáticamente cuando la app se inicia
      InvoiceSchedulerService.checkAndSendPendingInvoices();
    }

    if (mounted) {
      authProvider.addListener(_onAuthChange);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentUserId != null) {
        _presenceService.updateHeartbeat(_currentUserId!);
      } else {
        timer.cancel();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _onAuthChange() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null && user.id != _currentUserId) {
      _stopHeartbeat();
      if (_currentUserId != null) {
        _presenceService.setUserOffline(_currentUserId!);
      }
      _currentUserId = user.id;
      _presenceService.setUserOnline(user.id);
      _startHeartbeat();
    } else if (user == null && _currentUserId != null) {
      _stopHeartbeat();
      _presenceService.setUserOffline(_currentUserId!);
      _currentUserId = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUserId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _presenceService.setUserOnline(_currentUserId!);
        _startHeartbeat();
        // Verificar y enviar facturas automáticamente cuando la app se reanuda
        InvoiceSchedulerService.checkAndSendPendingInvoices();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _presenceService.setUserOnline(_currentUserId!);
        _startHeartbeat();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopHeartbeat();
        _presenceService.setUserOffline(_currentUserId!);
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    if (_currentUserId != null) {
      _presenceService.setUserOffline(_currentUserId!);
    }
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_onAuthChange);
    } catch (e) {
      // Context puede no estar disponible
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
