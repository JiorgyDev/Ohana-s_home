import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PaymentService {
  static const String baseUrl = 'https://wooheartc-back.onrender.com/api/v1';

  // Singleton
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // ============================================
  // PAGO ÚNICO - APOYO (AdoptarScreen)
  // ============================================
  Future<Map<String, dynamic>> createOneTimePayment({
    required BuildContext context,
    required double amount,
    required String description,
  }) async {
    try {
      // 1. Validar monto mínimo ($1 según backend)
      if (amount < 1) {
        return {'success': false, 'message': 'El monto mínimo es \$1.00 USD'};
      }

      // 2. Obtener token del usuario
      final token = AuthService().token;
      if (token == null) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para hacer un apoyo',
        };
      }

      // 3. Crear Payment Intent en el backend
      // ✅ CAMBIO: Ruta correcta del backend
      final response = await http
          .post(
            Uri.parse('$baseUrl/payments/apoyo'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'amount': amount, // El backend espera amount en USD
            }),
          )
          .timeout(Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al crear el pago',
        };
      }

      final clientSecret = data['data']['clientSecret'];

      // 4. Inicializar el Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'WooHeart',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
        ),
      );

      // 5. Mostrar el Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      return {
        'success': true,
        'message': '¡Pago exitoso! Gracias por tu apoyo 💝',
      };
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return {'success': false, 'message': 'Pago cancelado'};
      }
      return {
        'success': false,
        'message': 'Error: ${e.error.localizedMessage ?? "Error desconocido"}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ============================================
  // SUSCRIPCIÓN MENSUAL - SUSCRIBIR (SuscScreen)
  // ============================================
  Future<Map<String, dynamic>> createSuscripcionSubscription({
    required BuildContext context,
    required String plan, // '5', '10', '60', '150'
    required String planName,
  }) async {
    try {
      final token = AuthService().token;
      if (token == null) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para suscribirte',
        };
      }

      // ✅ RUTA CORRECTA + BODY CORRECTO
      final response = await http
          .post(
            Uri.parse('$baseUrl/payments/suscripcion'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'plan': plan, // Backend espera: '5', '10', '60', '150'
            }),
          )
          .timeout(Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al crear la suscripción',
        };
      }

      final clientSecret = data['data']['clientSecret'];

      // Inicializar Payment Sheet para suscripción
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'WooHeart',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
        ),
      );

      // Mostrar Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      return {
        'success': true,
        'message': '¡Suscripción activada! Bienvenido a $planName 🎉',
      };
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return {'success': false, 'message': 'Suscripción cancelada'};
      }
      return {
        'success': false,
        'message': 'Error: ${e.error.localizedMessage ?? "Error desconocido"}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ============================================
  // ADOPCIÓN MENSUAL - ADOPTAR (CrearScreen)
  // ============================================
  Future<Map<String, dynamic>> createAdopcionSubscription({
    required BuildContext context,
    required String plan, // '5', '10', '20'
    required String planName,
    String? petId, // Opcional: ID de la mascota
  }) async {
    try {
      final token = AuthService().token;
      if (token == null) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para adoptar',
        };
      }

      // ✅ RUTA CORRECTA + BODY CORRECTO
      final response = await http
          .post(
            Uri.parse('$baseUrl/payments/adopcion'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'plan': plan, // Backend espera: '5', '10', '20'
              if (petId != null) 'petId': petId,
            }),
          )
          .timeout(Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al crear la adopción',
        };
      }

      final clientSecret = data['data']['clientSecret'];

      // Inicializar Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'WooHeart',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
        ),
      );

      // Mostrar Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      return {
        'success': true,
        'message': '¡Adopción activada! Bienvenido a $planName 🎉',
      };
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return {'success': false, 'message': 'Adopción cancelada'};
      }
      return {
        'success': false,
        'message': 'Error: ${e.error.localizedMessage ?? "Error desconocido"}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ============================================
  // HELPER: Mostrar resultados
  // ============================================
  static void showPaymentResult(
    BuildContext context,
    Map<String, dynamic> result,
  ) {
    final isSuccess = result['success'] ?? false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Operación completada'),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
