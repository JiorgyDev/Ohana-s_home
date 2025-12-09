import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ohanas_app/screens/LoginScreen.dart';
import 'package:ohanas_app/screens/email_verification_screen.dart';
import 'dart:convert';
import 'package:ohanas_app/services/auth_service.dart';
import '../widgets/translated_text.dart';
import 'package:ohanas_app/screens/terms_and_conditions_screen.dart';

class OhanasRegister extends StatefulWidget {
  const OhanasRegister({Key? key}) : super(key: key);

  @override
  State<OhanasRegister> createState() => _OhanasRegisterState();
}

class _OhanasRegisterState extends State<OhanasRegister> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _celularController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estado
  String _codigoPais = '+591';
  String _generoSeleccionado = 'Masculino';
  bool _aceptaTerminos = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _celularController.dispose();
    _fechaNacimientoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistro() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      _mostrarMensaje(
        'Por favor completa todos los campos correctamente',
        error: true,
      );
      return;
    }

    if (!_aceptaTerminos) {
      _mostrarMensaje('Debes aceptar los Términos y Condiciones', error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final datos = {
        'name': _nombreController.text.trim(),
        'email': _correoController.text.trim().toLowerCase(),
        'password': _passwordController.text,
      };

      print('📤 Enviando datos: $datos');

      final response = await http
          .post(
            Uri.parse(
              'https://wooheartc-back.onrender.com/api/v1/auth/register',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(datos),
          )
          .timeout(Duration(seconds: 10));

      print('📥 Respuesta: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respuesta = jsonDecode(response.body);

        await AuthService().login(
          username: _nombreController.text.trim(),
          email: _correoController.text.trim(),
          userId: respuesta['data']?['user']?['_id']?.toString(),
          token: respuesta['token'],
        );

        _mostrarMensaje('¡Registro exitoso! Verifica tu email 📧');

        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: _correoController.text.trim(),
                username: _nombreController.text.trim(),
              ),
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        _mostrarMensaje(
          error['message'] ?? 'Error en el registro',
          error: true,
        );
      }
    } catch (e) {
      print('❌ Error completo: $e');
      String mensaje = 'Algo salió mal. Intenta de nuevo.';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        mensaje = 'Sin conexión a internet. Verifica tu red.';
      } else if (e.toString().contains('FormatException')) {
        mensaje = 'Error al procesar la respuesta del servidor.';
      }

      _mostrarMensaje(mensaje, error: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFB42C1C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFFC98).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 40,
                        color: Color(0xFFFE8043),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TranslatedText(
                      'REGÍSTRATE ES GRATIS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB42C1C),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Formulario
              _TranslatedTextField(
                controller: _nombreController,
                labelKey: 'Nombre y Apellidos',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _TranslatedTextField(
                controller: _apellidosController,
                labelKey: 'Usuario',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El usuario es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'El usuario debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Número de celular con código de país
              _buildPhoneField(),

              const SizedBox(height: 16),

              _TranslatedTextField(
                controller: _fechaNacimientoController,
                labelKey: 'Fecha de Nacimiento',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(
                      Duration(days: 365 * 18),
                    ),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(0xFFFE8043),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    _fechaNacimientoController.text =
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La fecha de nacimiento es requerida';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _TranslatedTextField(
                controller: _correoController,
                labelKey: 'Correo',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo es requerido';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Campo de contraseña con botón para ver/ocultar
              _TranslatedTextField(
                controller: _passwordController,
                labelKey: 'Contraseña',
                icon: Icons.lock,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Color(0xFFFE8043),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es requerida';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _TranslatedDropdown(
                value: _generoSeleccionado,
                labelKey: 'Género',
                icon: Icons.person,
                items: ['Masculino', 'Femenino', 'Otro'],
                onChanged: (value) {
                  setState(() {
                    _generoSeleccionado = value ?? 'Masculino';
                  });
                },
              ),

              const SizedBox(height: 24),

              // Términos y Condiciones
              Row(
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    onChanged: (value) {
                      setState(() {
                        _aceptaTerminos = value ?? false;
                      });
                    },
                    activeColor: Color(0xFFB42C1C),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _aceptaTerminos = !_aceptaTerminos;
                        });
                      },
                      child: Row(
                        children: [
                          TranslatedText(
                            'Acepto los ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TermsAndConditionsScreen(),
                                ),
                              );
                            },
                            child: TranslatedText(
                              'Términos y Condiciones',
                              style: TextStyle(
                                color: Color(0xFFB42C1C),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botón Registrarse
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_aceptaTerminos && !_isLoading)
                      ? _handleRegistro
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFE8043),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey[300],
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
                          'Registrarme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Link para ir al login
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: TranslatedText(
                    '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(
                      color: Color(0xFFB42C1C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
        Container(
          width: 100,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _codigoPais,
              items: ['+591', '+51', '+56', '+54']
                  .map(
                    (codigo) =>
                        DropdownMenuItem(value: codigo, child: Text(codigo)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _codigoPais = value ?? '+591';
                });
              },
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _TranslatedTextField(
            controller: _celularController,
            labelKey: 'Número de celular',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El celular es requerido';
              }
              if (value.length < 8) {
                return 'Número inválido';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

// Widget helper que usa TranslatedText para el label
class _TranslatedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelKey;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _TranslatedTextField({
    required this.controller,
    required this.labelKey,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Crear un TranslatedText invisible solo para obtener el texto traducido
        String translatedLabel = labelKey;

        return TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          decoration: InputDecoration(
            label: TranslatedText(labelKey),
            prefixIcon: Icon(icon, color: Color(0xFFFE8043)),
            suffixIcon: suffixIcon,
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
              borderSide: BorderSide(color: Color(0xFFFE8043), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFB42C1C), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        );
      },
    );
  }
}

// Widget helper para dropdown con TranslatedText
class _TranslatedDropdown extends StatelessWidget {
  final String value;
  final String labelKey;
  final IconData icon;
  final List<String> items;
  final void Function(String?) onChanged;

  const _TranslatedDropdown({
    required this.value,
    required this.labelKey,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        label: TranslatedText(labelKey),
        prefixIcon: Icon(icon, color: Color(0xFFFE8043)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFE8043), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem(value: item, child: TranslatedText(item)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
