import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translatedText = '';
  bool _isLoading = true;
  final _translationService = TranslationService();

  @override
  void initState() {
    super.initState();
    _loadTranslation();
    // ← ESCUCHAR CAMBIOS DE IDIOMA
    _translationService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    // ← DEJAR DE ESCUCHAR AL DESTRUIR EL WIDGET
    _translationService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    // Cuando cambia el idioma, volver a traducir
    _loadTranslation();
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _loadTranslation();
    }
  }

  Future<void> _loadTranslation() async {
    setState(() => _isLoading = true);
    final translated = await _translationService.translate(widget.text);
    if (mounted) {
      setState(() {
        _translatedText = translated;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mientras traduce, mostrar el texto original
    return Text(
      _isLoading ? widget.text : _translatedText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
