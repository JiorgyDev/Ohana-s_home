import 'package:ohanas_app/services/translation_service.dart';
import 'package:ohanas_app/utils/logger.dart';

class TranslationCache {
  static final TranslationCache _instance = TranslationCache._internal();
  factory TranslationCache() => _instance;
  TranslationCache._internal();

  // Cache: {language: {original: translated}}
  final Map<String, Map<String, String>> _cache = {'es': {}, 'en': {}};

  // ✅ Traducir con cache
  Future<String> translate(String text) async {
    if (text.isEmpty) return text;

    final currentLang = TranslationService().currentLanguage;

    // Si es español, no traducir
    if (currentLang == 'es') return text;

    // Revisar cache
    if (_cache[currentLang]?.containsKey(text) == true) {
      Logger.info('Cache HIT: ${text.substring(0, 20)}...');
      return _cache[currentLang]![text]!;
    }

    // Traducir y guardar en cache
    try {
      final translated = await TranslationService().translate(text);
      _cache[currentLang]![text] = translated;
      Logger.success('Cache MISS → Traducido: ${text.substring(0, 20)}...');
      return translated;
    } catch (e) {
      Logger.error('Error traduciendo', e);
      return text; // Retornar original si falla
    }
  }

  // ✅ Traducir múltiples textos en batch (más rápido)
  Future<List<String>> translateBatch(List<String> texts) async {
    final results = <String>[];

    for (var text in texts) {
      results.add(await translate(text));
    }

    return results;
  }

  // ✅ Limpiar cache (útil al cambiar idioma)
  void clearCache() {
    _cache['es']!.clear();
    _cache['en']!.clear();
    Logger.info('Translation cache limpiado');
  }

  // ✅ Precachear traducciones populares
  Future<void> precacheDescriptions(List<String> descriptions) async {
    Logger.info('Precacheando ${descriptions.length} descripciones...');
    await translateBatch(descriptions);
    Logger.success('Precache completo');
  }
}
