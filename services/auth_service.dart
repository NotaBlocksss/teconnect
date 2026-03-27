import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userData = await getUserData(credential.user!.uid);

        if (userData == null) {
          await _auth.signOut();
          throw Exception('Usuario no encontrado o fue eliminado. Por favor, contacta al administrador.');
        }

        await _updateLastLogin(credential.user!.uid);
        return userData;
      }
      
      return null;
    } catch (e) {
      if (e.toString().contains('wrong-password') || 
          e.toString().contains('user-not-found') || 
          e.toString().contains('invalid-credential')) {
        throw Exception('Credenciales inválidas. Verifica tu email y contraseña.');
      }
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  Future<UserModel?> signInWithDocument(
    String documentNumber,
    String password,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('documentNumber', isEqualTo: documentNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Credenciales inválidas. Verifica tu número de documento y contraseña.');
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final email = userData['email']?.toString();

      if (email == null || email.isEmpty) {
        throw Exception('Usuario no válido. El usuario no tiene un email asociado.');
      }

      return await signInWithEmailAndPassword(email, password);
    } catch (e) {
      if (e.toString().contains('Credenciales inválidas') || 
          e.toString().contains('wrong-password') || 
          e.toString().contains('user-not-found') || 
          e.toString().contains('invalid-credential')) {
        throw Exception('Credenciales inválidas. Verifica tu número de documento y contraseña.');
      }
      rethrow;
    }
  }

  Future<UserModel?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        // RETORNAR userModel (esto era lo que faltaba!)
        return userModel;
      }
      
      return null;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final userData = doc.data();
        
        if (userData != null) {
          try {
            return UserModel.fromMap(userData, doc.id);
          } catch (e) {
            return null;
          }
        }
      }

      return null;
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'lastLogin': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignorar error si no se puede actualizar
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  // Método para crear usuario sin iniciar sesión automáticamente
  // Retorna el UID del usuario creado
  Future<String> createUserOnly(String email, String password) async {
    try {
      // Crear el usuario (esto automáticamente inicia sesión)
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Retornar el UID del usuario creado
      return credential.user!.uid;
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  // Método para restaurar la sesión usando el token guardado
  Future<bool> restoreAdminSession(String adminEmail) async {
    try {
      // Intentar esperar a que Firebase Auth restaure automáticamente la sesión
      // Firebase Auth mantiene la persistencia local de sesiones
      // Si el admin tenía una sesión persistente, debería restaurarse automáticamente
      
      // Esperar un momento para que Firebase procese la restauración
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email == adminEmail) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

}

