// lib/widgets/benefit_item.dart

import 'package:flutter/material.dart';
import 'translated_text.dart';

/// Widget reutilizable para mostrar un beneficio con icono de check
///
/// Usado en pantallas de planes de suscripción
class BenefitItem extends StatelessWidget {
  final String text;
  final Color? iconColor;
  final Color? textColor;
  final double? iconSize;
  final double? fontSize;

  const BenefitItem({
    Key? key,
    required this.text,
    this.iconColor,
    this.textColor,
    this.iconSize,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ Mejor alineación
        children: [
          Icon(
            Icons.check_circle,
            color: iconColor ?? Color(0xFFFE8043),
            size: iconSize ?? 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TranslatedText(
              text,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: fontSize ?? 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
