import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PaymentService {
  static const String baseUrl = 'https://wooheartc-back-zz5h.onrender.com/api/v1';

  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // ============================================
  // PAGO ÚNICO - APOYO
  // ============================================
  Future<Map<String, dynamic>> createOneTimePayment({
    required BuildContext context,
    required double amount,
    required String description,
  }) async {
    try {
      if (amount < 1) {
        return {'success': false, 'message': 'El monto mínimo es \$1.00 USD'};
      }

      final token = AuthService().token;
      if (token == null) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para hacer un apoyo',
        };
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/payments/apoyo'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'amount': amount}),
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

      // ✅ Para pagos únicos usamos paymentIntentClientSecret
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'WooHeart',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
          billingDetails: BillingDetails(
            email: AuthService().email,
            name: AuthService().username,
          ),
        ),
      );

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
        'message':
            'Error de Stripe: ${e.error.localizedMessage ?? "Error desconocido"}',
      };
    } catch (e) {
      print('❌ Error en pago único: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ============================================
  // SUSCRIPCIÓN MENSUAL - SUSCRIBIR
  // ============================================
  Future<Map<String, dynamic>> createSuscripcionSubscription({
    required BuildContext context,
    required String plan,
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

      print('🔵 Iniciando suscripción - Plan: $plan');

      final response = await http
          .post(
            Uri.parse('$baseUrl/payments/suscripcion'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'plan': plan}),
          )
          .timeout(Duration(seconds: 15));

      print('🔵 Status code: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al crear la suscripción',
        };
      }

      final clientSecret = data['data']['clientSecret'];

      print('🔵 Client secret recibido: ${clientSecret.substring(0, 20)}...');

      // ✅ CRÍTICO: Para suscripciones con PaymentIntent inicial
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'WooHeart',
          paymentIntentClientSecret:
              clientSecret, // ✅ Tu backend usa PaymentIntent
          style: ThemeMode.light,
          billingDetails: BillingDetails(
            email: AuthService().email,
            name: AuthService().username,
          ),
        ),
      );

      print('🔵 Payment sheet inicializado');

      await Stripe.instance.presentPaymentSheet();

      print('🔵 Payment sheet completado exitosamente');

      return {
        'success': true,
        'message': '¡Suscripción activada! Bienvenido a $planName 🎉',
      };
    } on StripeException catch (e) {
      print('❌ StripeException: ${e.error.code} - ${e.error.localizedMessage}');

      if (e.error.code == FailureCode.Canceled) {
        return {'success': false, 'message': 'Suscripción cancelada'};
      }
      return {
        'success': false,
        'message':
            'Error de Stripe: ${e.error.localizedMessage ?? "Error desconocido"}',
      };
    } catch (e) {
      print('❌ Error general en suscripción: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ============================================
  // ADOPCIÓN MENSUAL - ADOPTAR
  // ============================================
  Future<Map<String, dynamic>> createAdopcionSubscription({
    required BuildContext context,
    required String plan,
    required String planName,
    String? petId,
  }) async {
    try {
      final token = AuthService().token;
      if (token == null) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para adoptar',
        };
      }

      print('🟢 Iniciando adopción - Plan: $plan, PetId: $petId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/payments/adopcion'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'plan': plan, if (petId != null) 'petId': petId}),
          )
          .timeout(Duration(seconds: 15));

      print('🟢 Status code: ${response.statusCode}');
      print('🟢 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al crear la adopción',
        };
      }

      final clientSecret = data['data']['clientSecret'];

      print('🟢 Client secret recibido: ${clientSecret.substring(0, 20)}...');

      // ✅ CRÍTICO: Para adopciones con PaymentIntent inicial
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'WooHeart',
          paymentIntentClientSecret:
              clientSecret, // ✅ Tu backend usa PaymentIntent
          style: ThemeMode.light,
          billingDetails: BillingDetails(
            email: AuthService().email,
            name: AuthService().username,
          ),
        ),
      );

      print('🟢 Payment sheet inicializado');

      await Stripe.instance.presentPaymentSheet();

      print('🟢 Payment sheet completado exitosamente');

      return {
        'success': true,
        'message': '¡Adopción activada! Bienvenido a $planName 🎉',
      };
    } on StripeException catch (e) {
      print('❌ StripeException: ${e.error.code} - ${e.error.localizedMessage}');

      if (e.error.code == FailureCode.Canceled) {
        return {'success': false, 'message': 'Adopción cancelada'};
      }
      return {
        'success': false,
        'message':
            'Error de Stripe: ${e.error.localizedMessage ?? "Error desconocido"}',
      };
    } catch (e) {
      print('❌ Error general en adopción: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

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
