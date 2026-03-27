class MessageModel {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String? type; // 'text', 'image', 'file', 'audio'
  final String? attachmentUrl;
  final String? replyToId; // ID del mensaje al que responde
  final String? replyToContent; // Contenido del mensaje al que responde
  final String? replyToSenderName; // Nombre del remitente del mensaje al que responde
  final Map<String, List<String>>? reactions; // {emoji: [userId1, userId2]}
  final String? status; // 'sending', 'sent', 'delivered', 'read'
  final String? fileName; // Nombre del archivo si es tipo file
  final int? fileSize; // Tamaño del archivo en bytes

  MessageModel({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.attachmentUrl,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    this.reactions,
    this.status,
    this.fileName,
    this.fileSize,
  });

  MessageModel copyWith({
    String? id,
    String? ticketId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    String? type,
    String? attachmentUrl,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    Map<String, List<String>>? reactions,
    String? status,
    String? fileName,
    int? fileSize,
  }) {
    return MessageModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      ticketId: map['ticketId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      type: map['type'] ?? 'text',
      attachmentUrl: map['attachmentUrl'],
      replyToId: map['replyToId'],
      replyToContent: map['replyToContent'],
      replyToSenderName: map['replyToSenderName'],
      reactions: map['reactions'] != null 
          ? Map<String, List<String>>.from(
              (map['reactions'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  List<String>.from(value),
                ),
              ),
            )
          : null,
      status: map['status'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp,
      'type': type,
      'attachmentUrl': attachmentUrl,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToContent != null) 'replyToContent': replyToContent,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (reactions != null) 'reactions': reactions,
      if (status != null) 'status': status,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
    };
  }
}

