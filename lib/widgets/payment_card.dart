import 'package:flutter/material.dart';
import 'package:ohanas_app/config/app_colors.dart';
import 'package:ohanas_app/widgets/translated_text.dart';

/// Widget genérico para mostrar planes de pago (Adopciones y Suscripciones)
class PaymentCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final List<String> benefits;
  final Color color;
  final IconData icon;
  final bool isPopular;
  final bool isRecommended;
  final VoidCallback onTap;

  const PaymentCard({
    Key? key,
    required this.title,
    required this.price,
    required this.description,
    required this.benefits,
    required this.color,
    required this.icon,
    required this.onTap,
    this.isPopular = false,
    this.isRecommended = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isPopular ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isPopular ? 16 : 12),
        border: Border.all(
          color: isPopular || isRecommended ? color : Colors.grey.shade300,
          width: isPopular || isRecommended ? 2 : 1,
        ),
        boxShadow: isPopular || isRecommended
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: isPopular ? 12 : 8,
                  offset: Offset(0, isPopular ? 4 : 2),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // ✅ HEADER con gradient (solo para planes populares)
          if (isPopular) _buildPopularHeader(),

          // ✅ CONTENIDO
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(isPopular ? 16 : 12),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(isPopular ? 20 : 16),
                child: isPopular
                    ? _buildPopularContent()
                    : _buildRegularContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header para planes populares (con gradient)
  Widget _buildPopularHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Column(
        children: [
          // Badge "MÁS POPULAR"
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TranslatedText(
              '⭐ MÁS POPULAR',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),

          // Título
          TranslatedText(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),

          // Descripción
          TranslatedText(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          SizedBox(height: 12),

          // Precio
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: TranslatedText(
                  ' USD/mes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Contenido para planes populares
  Widget _buildPopularContent() {
    return Column(
      children: [
        // Beneficios
        ...benefits.map(
          (benefit) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: color, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: TranslatedText(
                    benefit,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Botón
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: TranslatedText(
              'Seleccionar plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  /// Contenido para planes regulares
  Widget _buildRegularContent() {
    return Row(
      children: [
        // Icono
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(width: 16),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TranslatedText(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (isRecommended) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TranslatedText(
                        'RECOMENDADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4),
              TranslatedText(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),

        // Precio
        Column(
          children: [
            Text(
              '\$$price',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text('USD', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
