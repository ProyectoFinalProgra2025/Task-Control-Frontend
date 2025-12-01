import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/theme_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _backgroundController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animación del fondo
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Animación del logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Iniciar animaciones
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward();
    });

    // Navegación al login
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF1A3A5C),
                  Color(0xFF0D47A1),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Ondas decorativas animadas
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _backgroundController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(size.width, 200),
                        painter: _WavePainter(
                          color: Colors.white.withOpacity(0.03),
                          amplitude: 30,
                          phase: _backgroundController.value * math.pi * 2,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _backgroundController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(size.width, 150),
                        painter: _WavePainter(
                          color: Colors.white.withOpacity(0.05),
                          amplitude: 20,
                          phase: _backgroundController.value * math.pi * 2 + math.pi / 2,
                        ),
                      );
                    },
                  ),
                ),
                
                // Círculos decorativos animados
                ..._buildDecorativeCircles(),

                // Contenido principal
                Center(
                  child: AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo con sombra premium
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryBlue.withOpacity(0.3),
                                        blurRadius: 40,
                                        offset: const Offset(0, 15),
                                        spreadRadius: 5,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Image.asset(
                                        'assets/images/TaskControl_logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Nombre de la app
                                const Text(
                                  'TaskControl',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Tagline
                                Text(
                                  'Manage your tasks efficiently',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Indicador de carga en la parte inferior
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildDecorativeCircles() {
    return [
      // Círculo superior derecho
      Positioned(
        top: -80,
        right: -60,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.5 + (_backgroundController.value * 0.5),
              child: Opacity(
                opacity: 0.08,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Círculo inferior izquierdo
      Positioned(
        bottom: -100,
        left: -80,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.5 + (_backgroundController.value * 0.5),
              child: Opacity(
                opacity: 0.06,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Círculo pequeño decorativo superior
      Positioned(
        top: MediaQuery.of(context).size.height * 0.25,
        left: 40,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _backgroundController.value * math.pi * 0.5,
              child: Opacity(
                opacity: 0.05,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Otro círculo pequeño
      Positioned(
        bottom: MediaQuery.of(context).size.height * 0.3,
        right: 30,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.rotate(
              angle: -_backgroundController.value * math.pi * 0.3,
              child: Opacity(
                opacity: 0.04,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

// Custom painter para las ondas
class _WavePainter extends CustomPainter {
  final Color color;
  final double amplitude;
  final double phase;

  _WavePainter({
    required this.color,
    this.amplitude = 20,
    this.phase = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height -
          amplitude -
          amplitude * math.sin((x / size.width * 2 * math.pi) + phase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => 
      oldDelegate.phase != phase;
}
