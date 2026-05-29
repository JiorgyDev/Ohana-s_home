// lib/config/app_colors.dart

import 'package:flutter/material.dart';

/// Paleta de colores de la aplicación WooHeart
///
/// Centraliza todos los colores para fácil mantenimiento y consistencia
class AppColors {
  // Constructor privado para evitar instancias
  AppColors._();

  // ============================================
  // COLORES PRINCIPALES
  // ============================================

  /// Color primario naranja brillante
  /// Usado en: botones principales, highlights, iconos activos
  static const Color primary = Color(0xFFFE8043);

  /// Color secundario marrón oscuro
  /// Usado en: barra de navegación, fondos de headers
  static const Color secondary = Color(0xFF7C4C48);

  /// Color de fondo oscuro
  /// Usado en: fondos de pantallas oscuras, overlays
  static const Color darkBackground = Color(0xFF2A1617);

  // ============================================
  // COLORES DE ACENTO
  // ============================================

  /// Rojo intenso para likes activos
  static const Color likeActive = Color(0xFFB42C1C);

  /// Morado para planes/suscripciones
  static const Color purple = Color(0xFF9C27B0);

  /// Dorado para premium/destacados
  static const Color gold = Color(0xFFFFD700);

  /// Naranja dorado para badges premium
  static const Color goldOrange = Color(0xFFFFA500);

  // ============================================
  // COLORES DE ESTADO
  // ============================================

  /// Verde para éxito/activo
  static const Color success = Color(0xFF4CAF50);

  /// Rojo para errores/alertas
  static const Color error = Color(0xFFD32F2F);

  /// Naranja para advertencias
  static const Color warning = Color(0xFFFF9800);

  /// Azul para información
  static const Color info = Color(0xFF2196F3);

  // ============================================
  // COLORES DE TEXTO
  // ============================================

  /// Texto blanco principal
  static const Color textWhite = Colors.white;

  /// Texto negro principal
  static const Color textBlack = Colors.black;

  /// Texto gris claro
  static const Color textGrey = Color(0xFF757575);

  /// Texto gris oscuro
  static const Color textDarkGrey = Color(0xFF424242);

  // ============================================
  // GRADIENTES COMUNES
  // ============================================

  /// Gradiente para headers premium
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [gold, goldOrange],
  );

  /// Gradiente para botones primarios
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFFE8043)],
  );

  /// Gradiente para fondos oscuros
  static LinearGradient darkGradient = LinearGradient(
    colors: [secondary, darkBackground],
  );

  /// Gradiente para fondos premium sutiles
  static LinearGradient premiumBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary.withOpacity(0.1), gold.withOpacity(0.1)],
  );

  // ============================================
  // MÉTODOS DE AYUDA
  // ============================================

  /// Obtiene el color primario con opacidad
  static Color primaryWithOpacity(double opacity) {
    return primary.withOpacity(opacity);
  }

  /// Obtiene el color secundario con opacidad
  static Color secondaryWithOpacity(double opacity) {
    return secondary.withOpacity(opacity);
  }

  /// Obtiene el color de fondo oscuro con opacidad
  static Color darkBackgroundWithOpacity(double opacity) {
    return darkBackground.withOpacity(opacity);
  }
}
