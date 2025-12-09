import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Keys para SharedPreferences
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyUserId = 'userId';
  static const String _keyToken = 'token';

  // Variables en memoria
  bool _isLoggedIn = false;
  String? _username;
  String? _email;
  String? _userId;
  String? _token;

  // Getters públicos
  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get email => _email;
  String? get userId => _userId;
  String? get token => _token;

  /// Inicializar el servicio
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _username = prefs.getString(_keyUsername);
    _email = prefs.getString(_keyEmail);
    _userId = prefs.getString(_keyUserId);
    _token = prefs.getString(_keyToken);
  }

  /// Guardar sesión después del login/registro
  Future<void> login({
    required String username,
    required String email,
    String? userId,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyEmail, email);
    if (userId != null) {
      await prefs.setString(_keyUserId, userId);
    }
    if (token != null) {
      await prefs.setString(_keyToken, token);
    }

    // Actualizar en memoria
    _isLoggedIn = true;
    _username = username;
    _email = email;
    _userId = userId;
    _token = token;
  }

  /// Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyToken);

    // Limpiar en memoria
    _isLoggedIn = false;
    _username = null;
    _email = null;
    _userId = null;
    _token = null;
  }

  /// Verificar sesión
  Future<bool> checkSession() async {
    await init();
    return _isLoggedIn;
  }

  /// Obtener usuario actual (puedes implementarlo según tu backend)
  /// Obtener usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!_isLoggedIn) return null;

    return {
      'username': _username,
      'email': _email,
      'userId': _userId,
      'phone': '', // Por ahora vacío, después lo agregas al registro
    };
  }

  /// Actualizar perfil del usuario
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? description,
  }) async {
    try {
      // VALIDAR que tengamos userId
      if (_userId == null) {
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      final response = await http
          .put(
            Uri.parse(
              'https://wooheartc-back.onrender.com/api/v1/users/$_userId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({
              if (name != null) 'name': name,
              if (email != null) 'email': email,
              if (phone != null) 'phone': phone,
              if (description != null) 'description': description,
            }),
          )
          .timeout(Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Actualizar datos locales
        if (name != null) {
          _username = name;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyUsername, name);
        }
        if (email != null) {
          _email = email;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyEmail, email);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Perfil actualizado',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al actualizar',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Cambiar contraseña
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(
              'https://wooheartc-back.onrender.com/api/v1/users/updateMyPassword',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({
              'passwordCurrent':
                  currentPassword, // ← OJO: tu backend usa "passwordCurrent"
              'password': newPassword,
            }),
          )
          .timeout(Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña actualizada',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al cambiar contraseña',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Enviar código de verificación
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              'https://wooheartc-back.onrender.com/api/v1/auth/send-verification-code',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al enviar código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Verificar código de email
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              'https://wooheartc-back.onrender.com/api/v1/auth/verify-email',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'code': code}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['data']?['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Código inválido',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Enviar código de recuperación de contraseña
  Future<Map<String, dynamic>> sendPasswordResetCode(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              'https://wooheartc-back.onrender.com/api/v1/auth/forgot-password',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al enviar código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Resetear contraseña con código
  Future<Map<String, dynamic>> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              'https://wooheartc-back.onrender.com/api/v1/auth/reset-password',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'code': code,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al resetear contraseña',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
// ⚠️ NO AGREGUES NADA DESPUÉS DE ESTA LÍNEA
// Las funciones duplicadas han sido eliminadas