import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .limit(200)
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map((doc) {
              try {
                return UserModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .whereType<UserModel>()
            .toList();

          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return users;
        });
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      final isCurrentUser = currentUser != null && currentUser.uid == userId;

      // Eliminar del Firestore
      // Nota: Sin Cloud Functions, no podemos eliminar automáticamente de Firebase Authentication
      // desde el cliente. Sin embargo, al eliminar del Firestore:
      // 1. El usuario no podrá iniciar sesión (el login verifica que exista en Firestore)
      // 2. Si el usuario eliminado está autenticado actualmente, se cerrará su sesión
      await _firestore.collection('users').doc(userId).delete();

      // Si el usuario eliminado es el usuario actual, cerrar sesión inmediatamente
      if (isCurrentUser && _auth.currentUser != null) {
        await _auth.signOut();
      }
      
      // Nota importante: Para eliminar completamente de Firebase Authentication,
      // el administrador debe hacerlo manualmente desde la consola de Firebase,
      // o implementar un servidor backend con Admin SDK.
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // Obtener usuarios administradores y trabajadores
  Future<List<UserModel>> getAdminAndWorkerUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['admin', 'worker'])
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios admins/workers: $e');
    }
  }

  // Obtener todos los usuarios (Future en lugar de Stream)
  Future<List<UserModel>> getAllUsersSync() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }
}

