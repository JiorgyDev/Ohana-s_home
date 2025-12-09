//comment.dart
class Comment {
  final String id;
  final String petId;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.petId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir JSON a Comment
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      petId: json['petId'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Usuario',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Convertir Comment a JSON (para enviar al backend)
  Map<String, dynamic> toJson() {
    return {'petId': petId, 'content': content};
  }

  // Para depuración
  @override
  String toString() {
    return 'Comment(id: $id, username: $username, content: $content)';
  }
}
