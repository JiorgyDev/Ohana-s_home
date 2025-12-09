class Message {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final bool isMine;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.isMine,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      content: json['content'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Usuario',
      senderAvatar:
          json['senderAvatar'] ??
          'https://res.cloudinary.com/wooheart/image/upload/v1/default-avatar.png',
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isMine: json['isMine'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content};
  }
}
