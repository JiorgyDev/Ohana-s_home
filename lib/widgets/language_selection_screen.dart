import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../widgets/translated_text.dart';

class LanguageSelectionScreen extends StatefulWidget {
  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final _translationService = TranslationService();
  String _currentLang = 'es';

  @override
  void initState() {
    super.initState();
    _currentLang = _translationService.currentLanguage;
    // Escuchar cambios de idioma
    _translationService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _translationService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _currentLang = _translationService.currentLanguage;
      });
    }
  }

  Future<void> _changeLanguage(String newLang) async {
    await _translationService.changeLanguage(newLang);

    // Mostrar mensaje de confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newLang == 'es'
                ? 'Idioma cambiado a Español 🇪🇸'
                : 'Language changed to English 🇺🇸',
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFFFE8043),
        ),
      );

      // Esperar un momento y volver atrás
      await Future.delayed(Duration(milliseconds: 800));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Seleccionar idioma',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 16),
        children: [
          // Opción Español
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFFE8043).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('🇪🇸', style: TextStyle(fontSize: 24)),
              ),
            ),
            title: Text(
              'Español',
              style: TextStyle(
                fontSize: 18,
                fontWeight: _currentLang == 'es'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              'Spanish',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            trailing: _currentLang == 'es'
                ? Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28)
                : Icon(
                    Icons.circle_outlined,
                    color: Colors.grey[400],
                    size: 28,
                  ),
            onTap: () => _changeLanguage('es'),
          ),
          Divider(height: 1),

          // Opción Inglés
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFFE8043).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('🇺🇸', style: TextStyle(fontSize: 24)),
              ),
            ),
            title: Text(
              'English',
              style: TextStyle(
                fontSize: 18,
                fontWeight: _currentLang == 'en'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              'Inglés',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            trailing: _currentLang == 'en'
                ? Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28)
                : Icon(
                    Icons.circle_outlined,
                    color: Colors.grey[400],
                    size: 28,
                  ),
            onTap: () => _changeLanguage('en'),
          ),
          Divider(height: 1),

          // Información adicional
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.translate, size: 48, color: Colors.grey[400]),
                SizedBox(height: 12),
                TranslatedText(
                  'Los textos se traducirán automáticamente',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
