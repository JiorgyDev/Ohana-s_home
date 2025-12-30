// lib/services/payment_history_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import './payment_models.dart';
import '../../services/auth_service.dart';

class PaymentHistoryService {
  static const String baseUrl = 'https://wooheartc-back.onrender.com/api/v1';

  // Singleton
  static final PaymentHistoryService _instance =
      PaymentHistoryService._internal();
  factory PaymentHistoryService() => _instance;
  PaymentHistoryService._internal();

  /// Obtener historial completo de pagos del usuario
  Future<Map<String, dynamic>> getPaymentHistory() async {
    try {
      // 1. Validar que el usuario esté autenticado
      final token = AuthService().token;
      if (token == null) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para ver tu historial',
          'data': null,
        };
      }

      // 2. Hacer request al endpoint
      final response = await http
          .get(
            Uri.parse('$baseUrl/payments/history'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(seconds: 15));

      // 3. Parsear respuesta
      final data = jsonDecode(response.body);

      // 4. Validar status code
      if (response.statusCode == 200) {
        // Parsear datos usando el modelo
        final historyData = PaymentHistoryData.fromJson(data['data']);

        return {
          'success': true,
          'message': 'Historial obtenido correctamente',
          'data': historyData,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener historial',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'data': null,
      };
    }
  }

  /// Obtener solo las donaciones (Apoyo)
  Future<Map<String, dynamic>> getDonations() async {
    try {
      final result = await getPaymentHistory();

      if (result['success']) {
        final historyData = result['data'] as PaymentHistoryData?;
        return {'success': true, 'donations': historyData?.donations ?? []};
      }

      return {
        'success': false,
        'message': result['message'],
        'donations': <PaymentHistory>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener donaciones: $e',
        'donations': <PaymentHistory>[],
      };
    }
  }

  /// Obtener solo la suscripción general activa
  Future<Map<String, dynamic>> getActiveSubscription() async {
    try {
      final result = await getPaymentHistory();

      if (result['success']) {
        final historyData = result['data'] as PaymentHistoryData?;
        final subscription = historyData?.generalSubscription;

        return {
          'success': true,
          'subscription': subscription,
          'hasActive': subscription?.isActive ?? false,
        };
      }

      return {
        'success': false,
        'message': result['message'],
        'subscription': null,
        'hasActive': false,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener suscripción: $e',
        'subscription': null,
        'hasActive': false,
      };
    }
  }

  /// Obtener solo las adopciones
  Future<Map<String, dynamic>> getAdoptions() async {
    try {
      final result = await getPaymentHistory();

      if (result['success']) {
        final historyData = result['data'] as PaymentHistoryData?;
        return {
          'success': true,
          'adoptions': historyData?.adoptions ?? [],
          'activeCount': historyData?.activeAdoptionsCount ?? 0,
        };
      }

      return {
        'success': false,
        'message': result['message'],
        'adoptions': <AdoptionInfo>[],
        'activeCount': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener adopciones: $e',
        'adoptions': <AdoptionInfo>[],
        'activeCount': 0,
      };
    }
  }

  /// Obtener estadísticas resumidas
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      final result = await getPaymentHistory();

      if (result['success']) {
        final historyData = result['data'] as PaymentHistoryData?;

        if (historyData == null) {
          return {
            'success': true,
            'totalDonations': 0,
            'totalDonated': 0.0,
            'hasActiveSubscription': false,
            'activeAdoptions': 0,
          };
        }

        // Calcular total donado
        final totalDonated = historyData.donations.fold<double>(
          0.0,
          (sum, donation) => sum + donation.amount,
        );

        return {
          'success': true,
          'totalDonations': historyData.donations.length,
          'totalDonated': totalDonated,
          'hasActiveSubscription': historyData.hasActiveSubscription,
          'activeAdoptions': historyData.activeAdoptionsCount,
        };
      }

      return {
        'success': false,
        'message': result['message'],
        'totalDonations': 0,
        'totalDonated': 0.0,
        'hasActiveSubscription': false,
        'activeAdoptions': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener estadísticas: $e',
        'totalDonations': 0,
        'totalDonated': 0.0,
        'hasActiveSubscription': false,
        'activeAdoptions': 0,
      };
    }
  }

  /// Cancelar suscripción general (opcional - si tu backend lo soporta)
  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final token = AuthService().token;
      if (token == null) {
        return {'success': false, 'message': 'Debes iniciar sesión'};
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/payments/cancel-subscription'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Suscripción cancelada',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al cancelar suscripción',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Cancelar adopción específica (opcional - si tu backend lo soporta)
  Future<Map<String, dynamic>> cancelAdoption(String adoptionId) async {
    try {
      final token = AuthService().token;
      if (token == null) {
        return {'success': false, 'message': 'Debes iniciar sesión'};
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/payments/cancel-adoption/$adoptionId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Adopción cancelada',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al cancelar adopción',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
