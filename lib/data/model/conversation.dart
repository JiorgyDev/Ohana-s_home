class Conversation {
  final String id;
  final UserInfo otherUser;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // 1️⃣ Extraer ID de la conversación
    // Puede venir como '_id' (MongoDB) o 'id' (alternativo)
    String conversationId = json['_id'] ?? json['id'] ?? '';

    // 2️⃣ Extraer información del otro usuario
    // Si no viene, creamos un UserInfo vacío para evitar errores
    UserInfo otherUser = json['otherUser'] != null
        ? UserInfo.fromJson(json['otherUser'])
        : UserInfo(
            id: '',
            name: 'Usuario desconocido',
            email: '',
            avatar:
                'https://res.cloudinary.com/wooheart/image/upload/v1/default-avatar.png',
          );

    // 3️⃣ Extraer contenido del último mensaje
    // ⚠️ IMPORTANTE: lastMessage puede venir en 3 formas:
    //   - Como String simple: "Hola"
    //   - Como Object completo: { "_id": "...", "content": "Hola", ... }
    //   - Como null: cuando no hay mensajes aún
    String lastMessageContent = 'Sin mensajes';
    if (json['lastMessage'] != null) {
      if (json['lastMessage'] is String) {
        // Caso 1: Ya es un String
        lastMessageContent = json['lastMessage'];
      } else if (json['lastMessage'] is Map) {
        // Caso 2: Es un objeto, extraemos el 'content'
        lastMessageContent = json['lastMessage']['content'] ?? 'Sin contenido';
      }
    }

    // 4️⃣ Extraer ID del remitente del último mensaje
    String? lastSenderId;
    if (json['lastMessageSender'] != null) {
      if (json['lastMessageSender'] is String) {
        lastSenderId = json['lastMessageSender'];
      } else if (json['lastMessageSender'] is Map) {
        lastSenderId =
            json['lastMessageSender']['_id'] ?? json['lastMessageSender']['id'];
      }
    }

    // 5️⃣ Extraer timestamp del último mensaje
    // Si no viene, usamos updatedAt o la fecha actual
    DateTime lastMsgTime;
    if (json['lastMessageTime'] != null) {
      try {
        lastMsgTime = DateTime.parse(json['lastMessageTime']);
      } catch (e) {
        lastMsgTime = DateTime.now();
      }
    } else if (json['updatedAt'] != null) {
      try {
        lastMsgTime = DateTime.parse(json['updatedAt']);
      } catch (e) {
        lastMsgTime = DateTime.now();
      }
    } else {
      lastMsgTime = DateTime.now();
    }

    // 6️⃣ Extraer updatedAt
    DateTime updated;
    try {
      updated = DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      );
    } catch (e) {
      updated = DateTime.now();
    }

    // 7️⃣ Retornar la conversación construida
    return Conversation(
      id: conversationId,
      otherUser: otherUser,
      lastMessage: lastMessageContent,
      lastMessageTime: lastMsgTime,
      lastMessageSenderId: lastSenderId,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'otherUser': otherUser.toJson(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessageSender': lastMessageSenderId,
      'unreadCount': unreadCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class UserInfo {
  final String id;
  final String name;
  final String email;
  final String avatar;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Usuario',
      email: json['email'] ?? '',
      avatar:
          json['avatar'] ??
          'https://res.cloudinary.com/wooheart/image/upload/v1/default-avatar.png',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'avatar': avatar};
  }
}
