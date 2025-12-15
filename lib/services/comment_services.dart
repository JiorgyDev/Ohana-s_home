import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/model/comment.dart';
import 'auth_service.dart';

class CommentService {
  static const String baseUrl = 'https://wooheartc-back.onrender.com/api/v1';

  // Singleton
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;
  CommentService._internal();

  /// Obtener headers con token de autenticación
  Map<String, String> _getAuthHeaders() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// ============================================
  /// OBTENER comentarios de un pet
  /// ============================================
  Future<List<Comment>> getCommentsByPet(String petId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/comments/pet/$petId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            Duration(seconds: 3),
            onTimeout: () => http.Response('{"data":[]}', 200),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentsJson = data['data'] as List;
        return commentsJson.map((json) => Comment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error cargando comentarios: $e');
      return [];
    }
  }

  /// ============================================
  /// CREAR un comentario nuevo
  /// ============================================
  Future<Map<String, dynamic>> createComment({
    required String petId,
    required String content,
  }) async {
    try {
      if (AuthService().token == null) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para comentar',
        };
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/comments'),
            headers: _getAuthHeaders(),
            body: json.encode({'petId': petId, 'content': content}),
          )
          .timeout(Duration(seconds: 5));

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'comment': Comment.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al crear comentario',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  /// ============================================
  /// ELIMINAR un comentario
  /// ============================================
  Future<Map<String, dynamic>> deleteComment(String commentId) async {
    try {
      if (AuthService().token == null) {
        return {'success': false, 'message': 'Debes iniciar sesión'};
      }

      final response = await http
          .delete(
            Uri.parse('$baseUrl/comments/$commentId'),
            headers: _getAuthHeaders(),
          )
          .timeout(Duration(seconds: 5));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al eliminar',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }
}
