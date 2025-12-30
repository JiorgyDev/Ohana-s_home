// lib/services/pet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../data/model/pet_model.dart';

class PetService {
  static const String baseUrl = 'https://wooheartc-back.onrender.com/api/v1';

  // ✅ AHORA RETORNA List<PetModel> en lugar de Map
  static Future<List<PetModel>> fetchPets() async {
    try {
      final token = AuthService().token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/pets'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final petsData = jsonData['data']['pets'] as List;

        // ✅ USAR EL MODELO
        final pets = petsData
            .map((petJson) => PetModel.fromJson(petJson))
            .toList();
        pets.shuffle();
        return pets;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar mascotas: $e');
    }
  }

  static Future<Map<String, dynamic>> toggleLike(String petId) async {
    try {
      final token = AuthService().token;

      if (token == null) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para dar like',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/pets/$petId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'isLiked': data['data']['isLiked'],
          'likesCount': data['data']['likesCount'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al dar like',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<Map<String, dynamic>> createComment({
    required String petId,
    required String content,
  }) async {
    try {
      final token = AuthService().token;

      if (token == null) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para comentar',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/pets/$petId/comment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': content}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'comment': data['data']['comment'],
          'commentsCount': data['data']['commentsCount'],
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

  static Future<List<Map<String, dynamic>>> getComments(String petId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pets/$petId/comments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentsData = data['data']['comments'] as List;

        return commentsData.map((comment) {
          return {
            'userId': comment['userId'],
            'username': comment['username'],
            'content': comment['content'],
            'createdAt': comment['createdAt'],
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> incrementShare(String petId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pets/$petId/share'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'shares': data['data']['shares']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al registrar share',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }
}
