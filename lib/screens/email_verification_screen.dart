import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../widgets/translated_text.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String username;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.username,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _canResend = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _reenviarCodigo() async {
    setState(() => _isLoading = true);

    final resultado = await AuthService().sendVerificationCode(widget.email);

    setState(() => _isLoading = false);

    if (resultado['success']) {
      _startCountdown();
      _mostrarMensaje('Código reenviado exitosamente');
      // Limpiar campos
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    } else {
      _mostrarMensaje(resultado['message'], error: true);
    }
  }

  Future<void> _verificarCodigo() async {
    final codigo = _controllers.map((c) => c.text).join();

    if (codigo.length != 6) {
      _mostrarMensaje('Ingresa el código de 6 dígitos', error: true);
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await AuthService().verifyEmail(widget.email, codigo);

    setState(() => _isLoading = false);

    if (resultado['success']) {
      _mostrarMensaje('¡Email verificado exitosamente! 🎉');
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      _mostrarMensaje(resultado['message'], error: true);
      // Limpiar campos en error
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _mostrarMensaje(String mensaje, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Color(0xFFB42C1C) : Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFB42C1C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),

            // Icono
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFFFFFC98).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read,
                size: 50,
                color: Color(0xFFFE8043),
              ),
            ),

            SizedBox(height: 24),

            // Título
            TranslatedText(
              'Verifica tu email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A1617),
              ),
            ),

            SizedBox(height: 12),

            // Descripción
            Text(
              'Hemos enviado un código de verificación a y revisa tu bandeja de spam',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            SizedBox(height: 4),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFE8043),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 40),

            // Campos de código
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A1617),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFFE8043),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }

                      // Auto-verificar cuando se completen los 6 dígitos
                      if (index == 5 && value.isNotEmpty) {
                        _verificarCodigo();
                      }
                    },
                  ),
                );
              }),
            ),

            SizedBox(height: 40),

            // Botón verificar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verificarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFE8043),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : TranslatedText(
                        'Verificar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 24),

            // Reenviar código
            _canResend
                ? TextButton(
                    onPressed: _reenviarCodigo,
                    child: TranslatedText(
                      '¿No recibiste el código? Reenviar',
                      style: TextStyle(
                        color: Color(0xFFFE8043),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Text(
                    'Reenviar código en $_countdown segundos',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
          ],
        ),
      ),
    );
  }
}
