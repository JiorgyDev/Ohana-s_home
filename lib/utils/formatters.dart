// lib/utils/formatters.dart

/// Clase con funciones de formateo reutilizables
class Formatters {
  // Constructor privado para evitar instancias
  Formatters._();

  /// Formatea números grandes a formato compacto (1.5K, 2.3M)
  ///
  /// Ejemplos:
  /// - 999 → "999"
  /// - 1500 → "1.5K"
  /// - 2300000 → "2.3M"
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Formatea números sin decimales (1K en lugar de 1.0K)
  ///
  /// Ejemplos:
  /// - 1000 → "1K" (en lugar de "1.0K")
  /// - 1500 → "1.5K"
  /// - 2000000 → "2M"
  static String formatNumberCompact(int number) {
    if (number >= 1000000) {
      final value = number / 1000000;
      return value % 1 == 0
          ? '${value.toInt()}M'
          : '${value.toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      final value = number / 1000;
      return value % 1 == 0
          ? '${value.toInt()}K'
          : '${value.toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
