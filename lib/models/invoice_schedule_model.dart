class InvoiceScheduleModel {
  final String id;
  final String userId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InvoiceScheduleModel({
    required this.id,
    required this.userId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory InvoiceScheduleModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceScheduleModel(
      id: id,
      userId: map['userId'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  InvoiceScheduleModel copyWith({
    String? id,
    String? userId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceScheduleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

