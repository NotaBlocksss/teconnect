class UserModel {
  final String id;
  final String email;
  final String name;
  final String? lastName;
  final String? address;
  final String? internetPlan;
  final String role; // 'admin', 'worker', 'user'
  final String? phone;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool hasPaidInstallation; // Si el usuario pagó el servicio de instalación

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.lastName,
    this.address,
    this.internetPlan,
    required this.role,
    this.phone,
    this.photoUrl,
    required this.createdAt,
    this.lastLogin,
    this.hasPaidInstallation = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    try {
      // Manejar createdAt que puede ser Timestamp o DateTime
      DateTime? createdAtDate;
      if (map['createdAt'] != null) {
        if (map['createdAt'] is DateTime) {
          createdAtDate = map['createdAt'] as DateTime;
        } else {
          // Intentar convertir Timestamp a DateTime
          try {
            createdAtDate = (map['createdAt'] as dynamic).toDate();
          } catch (e) {
            print('⚠️ No se pudo convertir createdAt: $e');
            createdAtDate = DateTime.now();
          }
        }
      } else {
        createdAtDate = DateTime.now();
      }

      // Manejar lastLogin que puede ser Timestamp o DateTime
      DateTime? lastLoginDate;
      if (map['lastLogin'] != null) {
        if (map['lastLogin'] is DateTime) {
          lastLoginDate = map['lastLogin'] as DateTime;
        } else {
          try {
            lastLoginDate = (map['lastLogin'] as dynamic).toDate();
          } catch (e) {
            print('⚠️ No se pudo convertir lastLogin: $e');
            lastLoginDate = null;
          }
        }
      }

      final normalizedRole = _normalizeRole(map['role']?.toString());

      return UserModel(
        id: id,
        email: map['email']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        lastName: map['lastName']?.toString(),
        address: map['address']?.toString(),
        internetPlan: map['internetPlan']?.toString(),
        role: normalizedRole,
        phone: map['phone']?.toString(),
        photoUrl: map['photoUrl']?.toString(),
        createdAt: createdAtDate ?? DateTime.now(),
        lastLogin: lastLoginDate,
        hasPaidInstallation: map['hasPaidInstallation'] as bool? ?? false,
      );
    } catch (e) {
      print('❌ Error en fromMap: $e');
      print('📋 Map recibido: $map');
      print('📋 ID: $id');
      rethrow;
    }
  }

  static String _normalizeRole(String? rawRole) {
    final role = rawRole?.trim().toLowerCase() ?? '';
    if (role == 'admin' || role == 'administrador') return 'admin';
    if (role == 'worker' || role == 'trabajador') return 'worker';
    return 'user';
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'lastName': lastName,
      'address': address,
      'internetPlan': internetPlan,
      'role': role,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'hasPaidInstallation': hasPaidInstallation,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? lastName,
    String? address,
    String? internetPlan,
    String? role,
    String? phone,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? hasPaidInstallation,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      internetPlan: internetPlan ?? this.internetPlan,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      hasPaidInstallation: hasPaidInstallation ?? this.hasPaidInstallation,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isWorker => role == 'worker';
  bool get isUser => role == 'user';
}

