import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import '../widgets/translated_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ✅ MÉTODO HELPER PARA TRADUCIR (para validadores y strings simples)
  String _t(String text) {
    final currentLang = TranslationService().currentLanguage;

    final translations = {
      'es': {
        // ... traducciones existentes ...

        // ✅ AGREGAR ESTAS NUEVAS:
        'Restablecer contraseña': 'Restablecer contraseña',
        'Ingresa el código de 6 dígitos que enviamos a tu correo y tu nueva contraseña.':
            'Ingresa el código de 6 dígitos que enviamos a tu correo y tu nueva contraseña.',
        'Código de verificación': 'Código de verificación',
        'Nueva Contraseña': 'Nueva Contraseña',
        'Por favor ingresa tu correo': 'Por favor ingresa tu correo',
        'Código enviado a tu correo': 'Código enviado a tu correo',
        'Por favor completa todos los campos':
            'Por favor completa todos los campos',
        'Contraseña actualizada. Inicia sesión con tu nueva contraseña':
            'Contraseña actualizada. Inicia sesión con tu nueva contraseña',
        'Restablecer': 'Restablecer',
        'Enviar código': 'Enviar código',
        'Ingresa tu correo electrónico y te enviaremos un código para restablecer tu contraseña.':
            'Ingresa tu correo electrónico y te enviaremos un código para restablecer tu contraseña.',
      },
      'en': {
        // ... traducciones existentes ...

        // ✅ AGREGAR ESTAS NUEVAS:
        'Restablecer contraseña': 'Reset Password',
        'Ingresa el código de 6 dígitos que enviamos a tu correo y tu nueva contraseña.':
            'Enter the 6-digit code we sent to your email and your new password.',
        'Código de verificación': 'Verification Code',
        'Nueva Contraseña': 'New Password',
        'Por favor ingresa tu correo': 'Please enter your email',
        'Código enviado a tu correo': 'Code sent to your email',
        'Por favor completa todos los campos': 'Please complete all fields',
        'Contraseña actualizada. Inicia sesión con tu nueva contraseña':
            'Password updated. Sign in with your new password',
        'Restablecer': 'Reset',
        'Enviar código': 'Send Code',
        'Ingresa tu correo electrónico y te enviaremos un código para restablecer tu contraseña.':
            'Enter your email and we will send you a code to reset your password.',
      },
    };

    return translations[currentLang]?[text] ?? text;
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A1617), // Marrón oscuro
              Color(0xFF7C4C48), // Marrón medio
              Color(0xFFEBCD81), // Dorado
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 15),

                      // Logo y título
                      _buildHeader(),

                      SizedBox(height: 22),

                      // Campos del formulario
                      _buildEmailField(),

                      SizedBox(height: 25),

                      _buildPasswordField(),

                      SizedBox(height: 15),

                      // Recordarme y Olvidé contraseña
                      _buildRememberAndForgot(),

                      SizedBox(height: 20),

                      // Botón de login
                      _buildLoginButton(),

                      SizedBox(height: 20),

                      // Divider
                      _buildDivider(),

                      SizedBox(height: 20),

                      // Botón de registro
                      _buildRegisterButton(),

                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo circular animado
        Hero(
          tag: 'app_logo',
          child: ClipOval(
            child: Image.asset(
              'assets/icons/logo.png',
              width: 130,
              height: 130,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 15),

        Text(
          'Golden LionHeart', // ← Nombre de la app, NO traducir
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 253, 247, 247),
            letterSpacing: 1.2,
          ),
        ),

        SizedBox(height: 15),

        TranslatedText(
          'Creación digital con corazón de león',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 253, 247, 247),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: _t('Correo Electrónico'),
          labelStyle: TextStyle(color: Color(0xFFFE8043)),
          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFFE8043)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return _t('Por favor ingresa tu correo');
          }
          if (!value.contains('@')) {
            return _t('Por favor ingresa un correo válido');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: _t('Contraseña'),
          labelStyle: TextStyle(color: Color(0xFFFE8043)),
          prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFFE8043)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFF2A1617),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return _t('Por favor ingresa tu contraseña');
          }
          if (value.length < 6) {
            return _t('La contraseña debe tener al menos 6 caracteres');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Recordarme
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: Color(0xFFFE8043),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(width: 8),
            TranslatedText(
              'Recordar',
              style: TextStyle(
                color: Color(0xFF7C4C48),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Olvidé contraseña
        TextButton(
          onPressed: () {
            _showForgotPasswordDialog();
          },
          child: TranslatedText(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(
              color: Color(0xFFFE8043),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Color(0xFFFE8043), Color(0xFFB42C1C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFEBCD81).withOpacity(0.5),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : TranslatedText(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Color(0xFFEBCD81).withOpacity(0.6),
            thickness: 1.5,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: TranslatedText(
            'o',
            style: TextStyle(
              color: Color(0xFF2A1617),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFEBCD81).withOpacity(0.6),
            thickness: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFEBCD81), width: 2.5),
        color: Colors.white,
      ),
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushReplacementNamed('/register');
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: TranslatedText(
          '¿No tienes cuenta? Regístrate',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A1617),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (result['success']) {
        await AuthService().login(
          username: result['user']['name'] ?? 'Usuario',
          email: result['user']['email'],
          userId: result['user']['_id'],
          token: result['token'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2A1617)),
                  SizedBox(width: 12),
                  TranslatedText(_t('¡Bienvenido de vuelta! 🐾')),
                ],
              ),
              backgroundColor: Color(0xFFEBCD81),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: TranslatedText(
                      result['message'] ?? _t('Credenciales incorrectas'),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFFFE8043),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('${_t("Error de conexión")}: $e')),
              ],
            ),
            backgroundColor: Color(0xFF7C4C48),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final codeController = TextEditingController();
    final passwordController = TextEditingController();
    bool isCodeSent = false;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.lock_reset, color: Color(0xFFEBCD81)),
                SizedBox(width: 8),
                Expanded(
                  child: TranslatedText(
                    isCodeSent
                        ? 'Restablecer contraseña'
                        : '¿Olvidaste tu contraseña?',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCodeSent) ...[
                    // PASO 1: Ingresar email
                    TranslatedText(
                      'Ingresa tu correo electrónico y te enviaremos un código para restablecer tu contraseña.',
                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: _t('Correo Electrónico'),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Color(0xFFEBCD81),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFEBCD81),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // PASO 2: Ingresar código y nueva contraseña
                    TranslatedText(
                      'Ingresa el código de 6 dígitos que enviamos a tu correo y tu nueva contraseña.',
                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: _t('Código de verificación'),
                        prefixIcon: Icon(
                          Icons.security,
                          color: Color(0xFFEBCD81),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFE8043),
                            width: 2,
                          ),
                        ),
                        counterText: '',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: _t('Nueva Contraseña'),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Color(0xFFEBCD81),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFE8043),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: TranslatedText(
                  'Cancelar',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!isCodeSent) {
                          // PASO 1: Enviar código
                          if (emailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: TranslatedText(
                                  'Por favor ingresa tu correo',
                                ),
                                backgroundColor: Color(0xFFB42C1C),
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          final result = await AuthService()
                              .sendPasswordResetCode(
                                emailController.text.trim(),
                              );

                          setState(() => isLoading = false);

                          if (result['success']) {
                            setState(() => isCodeSent = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: TranslatedText(
                                  'Código enviado a tu correo, revisa tu bandeja de spam',
                                ),
                                backgroundColor: Color(0xFFEBCD81),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: Color(0xFFB42C1C),
                              ),
                            );
                          }
                        } else {
                          // PASO 2: Verificar código y resetear contraseña
                          if (codeController.text.trim().isEmpty ||
                              passwordController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: TranslatedText(
                                  'Por favor completa todos los campos',
                                ),
                                backgroundColor: Color(0xFFFE8043),
                              ),
                            );
                            return;
                          }

                          if (passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: TranslatedText(
                                  'La contraseña debe tener al menos 6 caracteres',
                                ),
                                backgroundColor: Color(0xFFFE8043),
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          final result = await AuthService()
                              .resetPasswordWithCode(
                                email: emailController.text.trim(),
                                code: codeController.text.trim(),
                                newPassword: passwordController.text,
                              );

                          setState(() => isLoading = false);

                          if (result['success']) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: TranslatedText(
                                  'Contraseña actualizada. Inicia sesión con tu nueva contraseña',
                                  style: TextStyle(color: Color(0xFF2A1617)),
                                ),
                                backgroundColor: Color(0xFFEBCD81),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: Color(0xFF7C4C48),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEBCD81),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : TranslatedText(
                        isCodeSent ? 'Restablecer' : 'Enviar código',
                        style: TextStyle(
                          color: Color(0xFF2A1617),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
