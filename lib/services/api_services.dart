//api_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  // URL base de tu backend
  static const String baseUrl = 'https://wooheartc-back.onrender.com/api/v1';

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Registrar usuario
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'user',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'token': data['token'],
          'user': data['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al registrar',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Login de usuario
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['token'],
          'user': data['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Credenciales incorrectas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Obtener headers con token de autenticación
  Map<String, String> _getAuthHeaders() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtener mascotas (con token si está disponible)
  Future<List<dynamic>> getPets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pets'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['pets'] ?? [];
      } else {
        throw Exception('Error al obtener mascotas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Buscar usuarios por nombre
  Future<List<dynamic>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/search?q=$query'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['users'] ?? [];
      } else {
        throw Exception('Error al buscar usuarios');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
