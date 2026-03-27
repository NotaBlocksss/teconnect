class AlertModel {
  final String id;
  final String title;
  final String message;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String type; // 'informacion', 'advertencia', 'mantenimiento', 'caida_servicio'
  final bool isActive;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.type = 'informacion',
    this.isActive = true,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    return AlertModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      expiresAt: map['expiresAt']?.toDate(),
      type: map['type'] ?? 'informacion',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'type': type,
      'isActive': isActive,
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get shouldShow => isActive && !isExpired;
}

