import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/presence_service.dart';
import '../services/navigation_service.dart';
import '../screens/auth/login_screen.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FCMService _fcmService = FCMService();
  final PresenceService _presenceService = PresenceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isMaintainingSession = false;
  bool _isCreatingUser = false;
  StreamSubscription<DocumentSnapshot>? _userListener;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
    _loadCurrentUser();
  }

  // Cargar usuario actual inmediatamente al iniciar
  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        final userData = await _authService.getUserData(firebaseUser.uid);
        if (userData == null) {
          await signOut();
          return;
        }
        _currentUser = userData;
        await _fcmService.setupUser(_currentUser!.id);
        await _presenceService.setUserOnline(_currentUser!.id);
        _setupUserDeletionListener(_currentUser!.id);
        notifyListeners();
      }
    } catch (e) {
      // Error silencioso
    }
  }

  void _init() {
    // Escuchar cambios en el estado de autenticación
    _authService.authStateChanges.listen((user) async {
      // Si estamos manteniendo la sesión manualmente O creando un usuario,
      // IGNORAR COMPLETAMENTE los cambios
      if (_isMaintainingSession || _isCreatingUser) {
        return; // Salir inmediatamente sin modificar nada
      }
      
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData == null) {
          if (!_isMaintainingSession && !_isCreatingUser) {
            await signOut();
          }
          return;
        }
        if (!_isMaintainingSession && !_isCreatingUser) {
          _currentUser = userData;
          await _fcmService.setupUser(_currentUser!.id);
          await _presenceService.setUserOnline(_currentUser!.id);
          _setupUserDeletionListener(user.uid);
          notifyListeners();
        }
      } else {
        if (!_isMaintainingSession && !_isCreatingUser) {
          _cancelUserDeletionListener();
          await _fcmService.removeUser();
          _currentUser = null;
          notifyListeners();
        }
      }
    });
  }

  void _setupUserDeletionListener(String userId) {
    _cancelUserDeletionListener();
    
    _userListener = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists) {
          _handleUserDeleted();
        }
      },
      onError: (error) {
        _handleUserDeleted();
      },
    );
  }

  void _cancelUserDeletionListener() {
    _userListener?.cancel();
    _userListener = null;
  }

  Future<void> _handleUserDeleted() async {
    if (_isMaintainingSession || _isCreatingUser) {
      return;
    }
    
    _cancelUserDeletionListener();
    await _presenceService.setUserOffline(_currentUser?.id ?? '');
    await _fcmService.removeUser();
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
    
    _showUserDeletedMessage();
  }

  void _showUserDeletedMessage() {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = NavigationService.context;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu cuenta ha sido eliminada. La sesión se ha cerrado.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (_currentUser != null) {
        await _fcmService.setupUser(_currentUser!.id);
        await _presenceService.setUserOnline(_currentUser!.id);
        _setupUserDeletionListener(_currentUser!.id);
      }

      _isLoading = false;
      notifyListeners();
      
      return _currentUser != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> signInWithDocument(String documentNumber, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithDocument(
        documentNumber,
        password,
      );
      
      if (_currentUser != null) {
        await _fcmService.setupUser(_currentUser!.id);
        await _presenceService.setUserOnline(_currentUser!.id);
        _setupUserDeletionListener(_currentUser!.id);
      }

      _isLoading = false;
      notifyListeners();
      
      return _currentUser != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String name,
    String role,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.signUpWithEmailAndPassword(
        email,
        password,
        name,
        role,
      );

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _cancelUserDeletionListener();
    if (_currentUser != null) {
      await _presenceService.setUserOffline(_currentUser!.id);
    }
    await _fcmService.removeUser();
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      await _authService.updateUserProfile(user);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void setUser(UserModel? user) {
    _currentUser = user;
    if (user != null) {
      _isMaintainingSession = true; // Activar modo mantenimiento
    } else {
      _isMaintainingSession = false; // Desactivar modo mantenimiento
    }
    notifyListeners();
  }

  // Método para desactivar el modo de mantenimiento de sesión
  void clearMaintenanceMode() {
    _isMaintainingSession = false;
  }

  // Método para activar/desactivar el modo de creación de usuario
  void setCreatingUser(bool isCreating) {
    _isCreatingUser = isCreating;
  }
}

