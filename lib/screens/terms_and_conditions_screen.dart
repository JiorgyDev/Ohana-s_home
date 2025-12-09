import 'package:flutter/material.dart';
import '../widgets/translated_text.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFB42C1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Términos y Condiciones',
          style: TextStyle(
            color: Color(0xFFB42C1C),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFFFFFC98).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(Icons.pets, size: 40, color: Color(0xFFFE8043)),
              ),
            ),
            const SizedBox(height: 20),

            // Fecha de actualización
            Center(
              child: Text(
                'Última actualización: Diciembre 2024',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Contenido
            _buildSection(
              '1. Aceptación de los Términos',
              'Al acceder y utilizar WooHeart, aceptas estar sujeto a estos Términos y Condiciones. Si no estás de acuerdo con alguna parte de estos términos, no debes utilizar nuestra aplicación.',
            ),

            _buildSection(
              '2. Descripción del Servicio',
              'WooHeart es una plataforma dedicada a la conexión entre personas y animales, permitiendo suscribir, apoyar y adoptar mascotas de manera responsable. Nuestro objetivo es promover el bienestar animal y facilitar la adopción responsable.',
            ),

            _buildSection(
              '3. Registro de Usuario',
              'Para utilizar ciertas funciones de WooHeart, debes registrarte y crear una cuenta. Te comprometes a:\n\n'
                  '• Proporcionar información verdadera, precisa y actualizada\n'
                  '• Mantener la seguridad de tu contraseña\n'
                  '• Ser responsable de todas las actividades en tu cuenta\n'
                  '• Notificarnos inmediatamente sobre cualquier uso no autorizado',
            ),

            _buildSection(
              '4. Uso Aceptable',
              'Al usar WooHeart, te comprometes a:\n\n'
                  '• No publicar contenido ofensivo, ilegal o inapropiado\n'
                  '• No acosar, intimidar o dañar a otros usuarios\n'
                  '• No usar la plataforma para actividades fraudulentas\n'
                  '• Respetar los derechos de propiedad intelectual\n'
                  '• Cumplir con todas las leyes locales, nacionales e internacionales',
            ),

            _buildSection(
              '5. Contenido del Usuario',
              'Eres responsable del contenido que publicas en WooHeart. Al publicar contenido, garantizas que tienes los derechos necesarios y otorgas a WooHeart una licencia para usar, modificar y mostrar ese contenido en la plataforma.',
            ),

            _buildSection(
              '6. Adopciones y Bienestar Animal',
              'WooHeart facilita la conexión entre adoptantes y animales, pero no somos responsables de las transacciones o acuerdos finales. Los usuarios deben:\n\n'
                  '• Verificar la información de los animales\n'
                  '• Cumplir con las leyes locales de adopción\n'
                  '• Comprometerse al cuidado responsable de los animales\n'
                  '• Reportar cualquier situación de maltrato animal',
            ),

            _buildSection(
              '7. Suscripciones y Pagos',
              'Si decides suscribirte a servicios premium:\n\n'
                  '• Los pagos se procesan de forma segura\n'
                  '• Las suscripciones se renuevan automáticamente\n'
                  '• Puedes cancelar en cualquier momento\n'
                  '• Los reembolsos están sujetos a nuestra política',
            ),

            _buildSection(
              '8. Privacidad',
              'Tu privacidad es importante para nosotros. Consulta nuestra Política de Privacidad para entender cómo recopilamos, usamos y protegemos tu información personal.',
            ),

            _buildSection(
              '9. Propiedad Intelectual',
              'Todo el contenido de WooHeart, incluyendo diseño, logotipos, textos y código, está protegido por derechos de autor y otras leyes de propiedad intelectual. No puedes copiar, modificar o distribuir nuestro contenido sin autorización.',
            ),

            _buildSection(
              '10. Limitación de Responsabilidad',
              'WooHeart se proporciona "tal cual" sin garantías de ningún tipo. No somos responsables de:\n\n'
                  '• Daños directos o indirectos por el uso de la plataforma\n'
                  '• Pérdida de datos o información\n'
                  '• Interacciones entre usuarios\n'
                  '• Problemas técnicos o interrupciones del servicio',
            ),

            _buildSection(
              '11. Modificaciones',
              'Nos reservamos el derecho de modificar estos Términos y Condiciones en cualquier momento. Te notificaremos sobre cambios significativos y tu uso continuado de la plataforma constituye la aceptación de los nuevos términos.',
            ),

            _buildSection(
              '12. Terminación',
              'Podemos suspender o terminar tu cuenta si violas estos términos. También puedes eliminar tu cuenta en cualquier momento desde la configuración de tu perfil.',
            ),

            _buildSection(
              '13. Contacto',
              'Si tienes preguntas sobre estos Términos y Condiciones, puedes contactarnos a través de:\n\n'
                  'Email: soporte@wooheart.com\n'
                  'O dentro de la aplicación mediante la sección de ayuda.',
            ),

            const SizedBox(height: 40),

            // Botón de aceptación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFE8043),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Entendido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB42C1C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
