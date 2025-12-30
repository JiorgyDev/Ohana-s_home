import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ohanas_app/screens/homePage.dart';
import 'package:ohanas_app/screens/ohanas_login.dart';
import 'package:ohanas_app/screens/LoginScreen.dart';
import 'package:ohanas_app/screens/ohanas_register.dart';
import 'services/translation_service.dart';
import 'services/auth_service.dart';
import 'config/stripe_config.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Stripe
  Stripe.publishableKey = StripeConfig.publishableKey;

  await AuthService().init();
  await TranslationService().loadLanguage();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Quicksand',
        // ✅ Configurar TextTheme completo
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Quicksand'),
          displayMedium: TextStyle(fontFamily: 'Quicksand'),
          displaySmall: TextStyle(fontFamily: 'Quicksand'),
          headlineLarge: TextStyle(fontFamily: 'Quicksand'),
          headlineMedium: TextStyle(fontFamily: 'Quicksand'),
          headlineSmall: TextStyle(fontFamily: 'Quicksand'),
          titleLarge: TextStyle(fontFamily: 'Quicksand'),
          titleMedium: TextStyle(fontFamily: 'Quicksand'),
          titleSmall: TextStyle(fontFamily: 'Quicksand'),
          bodyLarge: TextStyle(fontFamily: 'Quicksand'),
          bodyMedium: TextStyle(fontFamily: 'Quicksand'),
          bodySmall: TextStyle(fontFamily: 'Quicksand'),
          labelLarge: TextStyle(fontFamily: 'Quicksand'),
          labelMedium: TextStyle(fontFamily: 'Quicksand'),
          labelSmall: TextStyle(fontFamily: 'Quicksand'),
        ),
        // ✅ Configurar AppBarTheme
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // ✅ Configurar InputDecorationTheme
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(fontFamily: 'Quicksand'),
          hintStyle: TextStyle(fontFamily: 'Quicksand'),
          helperStyle: TextStyle(fontFamily: 'Quicksand'),
          errorStyle: TextStyle(fontFamily: 'Quicksand'),
        ),
        // ✅ Configurar ButtonTheme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontFamily: 'Quicksand'),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(fontFamily: 'Quicksand'),
          ),
        ),
      ),
      routes: {
        '/': (context) => const SplashScreen(),
        '/loginScreen': (context) => LoginScreen(),
        '/register': (context) => OhanasRegister(),
        '/home': (context) => OhanasHome(),
      },
      initialRoute: '/',
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotateController);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });

    _goToHome();
  }

  Future<void> _goToHome() async {
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      final hasSession = await AuthService().checkSession();

      if (hasSession) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/loginScreen');
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFC98), Color(0xFFFFF4D6), Color(0xFFFFE8B8)],
          ),
        ),
        child: Stack(
          children: [
            _buildFloatingCircles(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(75),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFE8043).withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _rotateAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotateAnimation.value,
                                  child: CustomPaint(
                                    size: const Size(150, 150),
                                    painter: CirclePainter(),
                                  ),
                                );
                              },
                            ),
                            const Icon(
                              Icons.pets,
                              size: 80,
                              color: Color(0xFFFE8043),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          "WooHeart",
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A1617),
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "🐾 Amor que conecta 💝",
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFFE8043).withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCustomLoader(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCircles() {
    return Stack(
      children: [
        Positioned(
          top: 80,
          left: 30,
          child: AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  math.sin(_rotateController.value * 2 * math.pi) * 10,
                  math.cos(_rotateController.value * 2 * math.pi) * 10,
                ),
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: 40,
          child: AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -math.sin(_rotateController.value * 2 * math.pi) * 15,
                  -math.cos(_rotateController.value * 2 * math.pi) * 15,
                ),
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFE8043).withOpacity(0.15),
                    const Color(0xFFFE8043).withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 150,
          right: 60,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_pulseAnimation.value - 1.0) * 2,
                child: child,
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomLoader() {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: List.generate(8, (index) {
          return AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              final angle =
                  (index * math.pi / 4) +
                  (_rotateController.value * 2 * math.pi);
              final opacity =
                  (math.sin(
                        _rotateController.value * 2 * math.pi + index * 0.5,
                      ) +
                      1) /
                  2;

              return Transform.rotate(
                angle: angle,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFE8043).withOpacity(opacity * 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFE8043,
                          ).withOpacity(opacity * 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFE8043).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    for (int i = 0; i < 6; i++) {
      final startAngle = i * math.pi / 3;
      const sweepAngle = math.pi / 6;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
