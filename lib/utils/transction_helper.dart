import 'package:flutter/material.dart';
import 'package:ohanas_app/utils/logger.dart';

/// Helper para manejar transacciones con rollback automático
class TransactionHelper {
  /// Ejecuta una transacción con UI optimista y rollback automático
  static Future<Map<String, dynamic>> executeWithRollback({
    required BuildContext context,
    required String transactionName,
    required Future<Map<String, dynamic>> Function() operation,
    required VoidCallback onOptimisticUpdate,
    required VoidCallback onRollback,
    Color? loadingColor,
  }) async {
    Logger.info('🔄 Iniciando transacción: $transactionName');

    // 1. Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: loadingColor ?? const Color(0xFFFE8043),
        ),
      ),
    );

    // 2. Aplicar cambio optimista
    onOptimisticUpdate();
    Logger.info('✅ Update optimista aplicado');

    try {
      // 3. Ejecutar operación
      final result = await operation();

      // 4. Cerrar loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 5. Verificar resultado
      if (result['success'] == true) {
        Logger.success('✅ Transacción exitosa: $transactionName');
        return result;
      } else {
        // 6. Si falló, hacer rollback
        Logger.warning('⚠️ Transacción fallida, haciendo rollback');
        onRollback();
        return result;
      }
    } catch (e) {
      // 7. Error: cerrar loading y hacer rollback
      Logger.error('❌ Error en transacción: $transactionName', e);

      if (context.mounted) {
        Navigator.pop(context);
      }

      onRollback();

      return {
        'success': false,
        'message': 'Error de conexión. Intenta de nuevo.',
      };
    }
  }

  /// Muestra el resultado de una transacción
  static void showResult(
    BuildContext context,
    Map<String, dynamic> result, {
    VoidCallback? onSuccess,
  }) {
    if (!context.mounted) return;

    final success = result['success'] == true;
    final message =
        result['message'] ??
        (success ? 'Operación exitosa' : 'Error en la operación');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: success ? 2 : 4),
        action: success
            ? null
            : SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
      ),
    );

    if (success && onSuccess != null) {
      Future.delayed(Duration(milliseconds: 500), onSuccess);
    }
  }
}
