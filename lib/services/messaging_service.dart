//messaging_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../data/model/conversation.dart';
import '../data/model/message.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  static const String baseUrl = 'https://wooheartc-back.onrender.com/api/v1';

  Map<String, String> _getAuthHeaders() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Obtener todas las conversaciones del usuario
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List conversations = data['data']['conversations'] ?? [];
        return conversations.map((c) => Conversation.fromJson(c)).toList();
      } else {
        throw Exception('Error al obtener conversaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear o obtener conversación con un usuario
  Future<Conversation> createOrGetConversation(String otherUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations'),
        headers: _getAuthHeaders(),
        body: json.encode({'otherUserId': otherUserId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Conversation.fromJson(data['data']['conversation']);
      } else {
        throw Exception('Error al crear conversación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener mensajes de una conversación
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$conversationId?limit=$limit&skip=$skip'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List messages = data['data'] ?? [];

        // Obtener el userId actual para marcar isMine
        final currentUserId = AuthService().userId ?? '';

        return messages.map((m) {
          // Extraer datos del sender que viene como objeto poblado
          final sender = m['senderId'];
          final senderId = sender is Map
              ? (sender['_id'] ?? sender['id'] ?? '')
              : sender.toString();
          final senderName = sender is Map
              ? (sender['name'] ?? 'Usuario')
              : 'Usuario';
          final senderAvatar = sender is Map ? (sender['avatar'] ?? '') : '';

          return Message.fromJson({
            'id': m['_id'] ?? m['id'] ?? '',
            'content': m['content'] ?? '',
            'senderId': senderId,
            'senderName': senderName,
            'senderAvatar': senderAvatar,
            'isRead': m['isRead'] ?? false,
            'readAt': m['readAt'],
            'createdAt': m['createdAt'] ?? DateTime.now().toIso8601String(),
            'isMine': senderId == currentUserId,
          });
        }).toList();
      } else {
        throw Exception('Error al obtener mensajes');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Enviar un mensaje
  // Enviar un mensaje
  Future<Message> sendMessage(String conversationId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: _getAuthHeaders(),
        body: json.encode({
          'conversationId': conversationId,
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final messageData = data['data'];

        // Obtener el userId actual
        final currentUserId = AuthService().userId ?? '';

        // Extraer datos del sender poblado
        final sender = messageData['senderId'];
        final senderId = sender is Map
            ? (sender['_id'] ?? sender['id'] ?? '')
            : sender.toString();
        final senderName = sender is Map
            ? (sender['name'] ?? 'Usuario')
            : 'Usuario';
        final senderAvatar = sender is Map ? (sender['avatar'] ?? '') : '';

        return Message.fromJson({
          'id': messageData['_id'] ?? messageData['id'] ?? '',
          'content': messageData['content'] ?? '',
          'senderId': senderId,
          'senderName': senderName,
          'senderAvatar': senderAvatar,
          'isRead': messageData['isRead'] ?? false,
          'readAt': messageData['readAt'],
          'createdAt':
              messageData['createdAt'] ?? DateTime.now().toIso8601String(),
          'isMine': senderId == currentUserId,
        });
      } else {
        throw Exception('Error al enviar mensaje');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar conversación
  Future<void> deleteConversation(String conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/conversations/$conversationId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Error al eliminar conversación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar mensaje
  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/messages/$messageId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar mensaje');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
