import 'package:flutter/material.dart';
import 'dart:math' as math;

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
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFC1FF72),
                  const Color(0xFFB5F562),
                  const Color(0xFFA8E84F),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
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
                                // Logo con sombra
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(35),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 40,
                                        offset: const Offset(0, 15),
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(35),
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
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Tagline
                                Text(
                                  'Gestiona tus tareas fácilmente',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black.withOpacity(0.6),
                                    letterSpacing: 0.2,
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
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black.withOpacity(0.4),
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
        top: -100,
        right: -80,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.5 + (_backgroundController.value * 0.5),
              child: Opacity(
                opacity: 0.15,
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
      // Círculo inferior izquierdo
      Positioned(
        bottom: -120,
        left: -100,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.5 + (_backgroundController.value * 0.5),
              child: Opacity(
                opacity: 0.12,
                child: Container(
                  width: 350,
                  height: 350,
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
      // Círculo pequeño decorativo
      Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: 30,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _backgroundController.value * math.pi * 0.5,
              child: Opacity(
                opacity: 0.1,
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
      // Otro círculo pequeño
      Positioned(
        bottom: MediaQuery.of(context).size.height * 0.35,
        right: 40,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.rotate(
              angle: -_backgroundController.value * math.pi * 0.3,
              child: Opacity(
                opacity: 0.08,
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
    ];
  }
}
