import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  String _currentLanguage = 'es'; // Idioma por defecto: español

  // Cache para no traducir el mismo texto varias veces
  final Map<String, Map<String, String>> _cache = {};

  // Obtener idioma actual
  String get currentLanguage => _currentLanguage;

  // Cargar idioma guardado
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'es';
    notifyListeners(); // ← NOTIFICAR A LOS WIDGETS
  }

  // Cambiar idioma
  Future<void> changeLanguage(String newLanguage) async {
    if (_currentLanguage == newLanguage) return; // No hacer nada si es el mismo

    _currentLanguage = newLanguage;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLanguage);
    _cache.clear();
    notifyListeners(); // ← NOTIFICAR A TODOS LOS WIDGETS
  }

  // Traducir texto usando Google Translate API (gratis)
  Future<String> translate(String text) async {
    // Si el idioma es español, devolver texto original
    if (_currentLanguage == 'es') return text;

    // Verificar cache
    if (_cache[_currentLanguage]?.containsKey(text) == true) {
      return _cache[_currentLanguage]![text]!;
    }

    try {
      // Llamar a la API de Google Translate
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=es&tl=$_currentLanguage&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final translatedText = jsonResponse[0][0][0] as String;

        // Guardar en cache
        _cache[_currentLanguage] ??= {};
        _cache[_currentLanguage]![text] = translatedText;

        return translatedText;
      } else {
        print('Error en traducción: ${response.statusCode}');
        return text;
      }
    } catch (e) {
      print('Error traduciendo: $e');
      return text;
    }
  }
}
