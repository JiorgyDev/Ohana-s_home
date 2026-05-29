// lib/services/pet_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../data/model/pet_model.dart';

class PetService {
  static const String baseUrl = 'https://wooheartc-back-zz5h.onrender.com/api/v1';

  // ✅ AHORA RETORNA List<PetModel> en lugar de Map
  static Future<List<PetModel>> fetchPets() async {
    try {
      final token = AuthService().token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/pets?limit=1000'),
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/pets/$petId/share'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10)); // ✅ AGREGAR TIMEOUT

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'shares': data['data']['shares']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al registrar share',
        };
      }
    } on TimeoutException {
      // ✅ MANEJAR TIMEOUT
      return {'success': false, 'message': 'Conexión lenta. Intenta de nuevo'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // ✅ NUEVA FUNCIÓN: Obtener mascotas con like (estilo TikTok)
  static Future<List<PetModel>> fetchLikedPets() async {
    try {
      final token = AuthService().token;

      if (token == null) {
        throw Exception('Debes iniciar sesión para ver tus likes');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse('$baseUrl/pets/liked'), headers: headers)
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final petsData = jsonData['data']['pets'] as List;

        final pets = petsData
            .map((petJson) => PetModel.fromJson(petJson))
            .toList();

        return pets;
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Vuelve a iniciar sesión');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Conexión lenta. Intenta de nuevo');
    } catch (e) {
      throw Exception('Error al cargar likes: $e');
    }
  }

  // ✅ NUEVA FUNCIÓN: Obtener mascotas adoptadas (estilo TikTok)
  static Future<List<PetModel>> fetchAdoptedPets() async {
    try {
      final token = AuthService().token;

      if (token == null) {
        throw Exception('Debes iniciar sesión para ver tus adopciones');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse('$baseUrl/pets/adopted'), headers: headers)
          .timeout(Duration(seconds: 15));
      // ✅ AGREGAR ESTOS PRINTS:
      print('🔍 Status Code: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // ✅ AGREGAR ESTE PRINT:
        print('🔍 JSON Data: $jsonData');
        print('🔍 Pets Array: ${jsonData['data']['pets']}');
        final petsData = jsonData['data']['pets'] as List;

        final pets = petsData.map((petJson) {
          print('🔍 Parsing pet: ${petJson['name']}'); // ✅ AGREGAR
          print('🔍 Has adoptionInfo: ${petJson['adoptionInfo']}'); // ✅ AGREGAR
          return PetModel.fromJson(petJson);
        }).toList();
        return pets;
        print('🔍 Total pets parsed: ${pets.length}');
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Vuelve a iniciar sesión');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Conexión lenta. Intenta de nuevo');
    } catch (e) {
      print('❌ Error en fetchAdoptedPets: $e');
      throw Exception('Error al cargar adopciones: $e');
    }
  }

  // ✅ NUEVA FUNCIÓN: Obtener mascotas apoyadas (últimas del refugio)
  static Future<List<PetModel>> fetchSupportedPets() async {
    try {
      final token = AuthService().token;

      if (token == null) {
        throw Exception('Debes iniciar sesión para ver tus apoyos');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('🔍 [APOYOS] Llamando al endpoint /pets/supported...');
      print(
        '🔍 [APOYOS] Token: ${token.substring(0, 20)}...',
      ); // ✅ Mostrar inicio del token

      final response = await http
          .get(Uri.parse('$baseUrl/pets/supported'), headers: headers)
          .timeout(Duration(seconds: 15));

      print('🔍 [APOYOS] Status Code: ${response.statusCode}');
      print('🔍 [APOYOS] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        print('🔍 [APOYOS] JSON Data: $jsonData');

        // ✅ VERIFICAR SI HAY MENSAJE DE "NO HAY DONACIONES"
        if (jsonData['data']['message'] != null) {
          print(
            '⚠️ [APOYOS] Mensaje del backend: ${jsonData['data']['message']}',
          );
          throw Exception(jsonData['data']['message']);
        }

        final petsData = jsonData['data']['pets'] as List;

        print(
          '🔍 [APOYOS] Pets Array: ${petsData.length} mascotas encontradas',
        );

        final pets = petsData.map((petJson) {
          print('🔍 [APOYOS] Parsing pet: ${petJson['name']}');
          return PetModel.fromJson(petJson);
        }).toList();

        print('✅ [APOYOS] Total pets parsed: ${pets.length}');
        return pets;
      } else if (response.statusCode == 401) {
        print('❌ [APOYOS] Sesión expirada (401)');
        throw Exception('Sesión expirada. Vuelve a iniciar sesión');
      } else {
        print('❌ [APOYOS] Error del servidor: ${response.statusCode}');
        print('❌ [APOYOS] Body: ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on TimeoutException {
      print('⏱️ [APOYOS] Timeout después de 15 segundos');
      throw Exception('Conexión lenta. Intenta de nuevo');
    } catch (e) {
      print('❌ [APOYOS] Error en fetchSupportedPets: $e');
      rethrow; // ✅ Re-lanzar el error para que la UI lo capture
    }
  }
}
