import 'package:flutter/foundation.dart';

/// Sistema de logs profesional para debugging
/// Solo funciona en modo desarrollo (kDebugMode)
class Logger {
  /// Log de información general
  /// Uso: Logger.info('Usuario cargó la app');
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Log de errores
  /// Uso: Logger.error('Error en API', e);
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('   Details: $error');
      }
      if (stackTrace != null) {
        debugPrint(
          '   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}',
        );
      }
    }
  }

  /// Log de advertencias
  /// Uso: Logger.warning('Conexión lenta detectada');
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// Log de operaciones exitosas
  /// Uso: Logger.success('Pago procesado correctamente');
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ SUCCESS: $message');
    }
  }

  /// Log de operaciones de red
  /// Uso: Logger.network('GET', '/api/pets');
  static void network(String method, String endpoint, [int? statusCode]) {
    if (kDebugMode) {
      final status = statusCode != null ? ' [$statusCode]' : '';
      debugPrint('🌐 NETWORK: $method $endpoint$status');
    }
  }

  /// Log de navegación entre pantallas
  /// Uso: Logger.navigation('HomeScreen → ProfileScreen');
  static void navigation(String route) {
    if (kDebugMode) {
      debugPrint('📍 NAVIGATION: $route');
    }
  }
}
