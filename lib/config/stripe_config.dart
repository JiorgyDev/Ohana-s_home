class StripeConfig {
  // ============================================
  // CLAVES PÚBLICAS DE STRIPE
  // ============================================

  // ⚠️ REEMPLAZA ESTO CON TU PUBLISHABLE KEY REAL
  static const String publishableKey =
      'pk_test_51ScqRw5AM2wN9Wkr3uVdzuToZlGklTL2l090F4pWFcCcDMz9dTzEWe3oPdi1lMv2bmmCrvvzBBcH66ImsDE07wNw00yEUiMVBr';

  // ============================================
  // ADOPTAR - Planes Mensuales (CrearScreen)
  // ============================================
  static const String adoptarGuardian =
      'price_1SedOV5AM2wN9Wkr1cI7t1oq'; // $5/mes
  static const String adoptarProtector =
      'price_1SedPU5AM2wN9WkrdlaM1nxd'; // $10/mes
  static const String adoptarAngel =
      'price_1SedPU5AM2wN9WkrhLRT3r7y'; // $20/mes

  // ============================================
  // SUSCRIBIR - Planes Mensuales (SuscScreen)
  // ============================================
  static const String suscribir5 = 'price_1SedQC5AM2wN9Wkroe5eXGXo'; // $5/mes
  static const String suscribir10 = 'price_1SedR75AM2wN9WkrAs7zQ5Zg'; // $10/mes
  static const String suscribir60 = 'price_1SedR75AM2wN9Wkrjzauq7Zi'; // $60/mes
  static const String suscribir150 =
      'price_1SedR75AM2wN9WkrbpGEyZyc'; // $150/mes

  // ============================================
  // APOYAR - Pago único (AdoptarScreen)
  // ============================================
  // No necesita price_id, usa monto personalizado
}
