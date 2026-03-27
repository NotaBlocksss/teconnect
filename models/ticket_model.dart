class TicketModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String? assignedTo; // worker o admin que atiende
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final List<String> participants; // IDs de usuarios que participan

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    this.assignedTo,
    this.status = 'open',
    this.priority = 'medium',
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    List<String>? participants,
  }) : participants = participants ?? [];

  factory TicketModel.fromMap(Map<String, dynamic> map, String id) {
    return TicketModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      assignedTo: map['assignedTo'],
      status: map['status'] ?? 'open',
      priority: map['priority'] ?? 'medium',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
      resolvedAt: map['resolvedAt']?.toDate(),
      participants: List<String>.from(map['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'status': status,
      'priority': priority,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'resolvedAt': resolvedAt,
      'participants': participants,
    };
  }

  TicketModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    String? assignedTo,
    String? status,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    List<String>? participants,
  }) {
    return TicketModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      participants: participants ?? this.participants,
    );
  }

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';
}

