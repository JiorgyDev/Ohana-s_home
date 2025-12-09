import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class LanguageSwitcher extends StatefulWidget {
  final Function()? onLanguageChanged;

  const LanguageSwitcher({Key? key, this.onLanguageChanged}) : super(key: key);

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  String _currentLang = 'es';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    await TranslationService().loadLanguage();
    setState(() {
      _currentLang = TranslationService().currentLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: Colors.white),
      onSelected: (String language) async {
        await TranslationService().changeLanguage(language);
        setState(() {
          _currentLang = language;
        });

        // Mostrar mensaje
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                language == 'es'
                    ? 'Idioma cambiado a Español 🇪🇸'
                    : 'Language changed to English 🇺🇸',
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFFFE8043),
            ),
          );
        }

        // Llamar callback para recargar la pantalla
        if (widget.onLanguageChanged != null) {
          widget.onLanguageChanged!();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'es',
          child: Row(
            children: [
              Text('🇪🇸 Español', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              if (_currentLang == 'es')
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'en',
          child: Row(
            children: [
              Text('🇺🇸 English', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              if (_currentLang == 'en')
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
            ],
          ),
        ),
      ],
    );
  }
}
