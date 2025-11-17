import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/company_admin/admin_main_screen.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const TaskControlApp());
}

class TaskControlApp extends StatelessWidget {
  const TaskControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const InitialRouteHandler(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminMainScreen(),
      },
    );
  }
}

class InitialRouteHandler extends StatefulWidget {
  const InitialRouteHandler({super.key});

  @override
  State<InitialRouteHandler> createState() => _InitialRouteHandlerState();
}

class _InitialRouteHandlerState extends State<InitialRouteHandler> {
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    // Pequeña pausa para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 1. Verificar si está autenticado
    final isAuthenticated = await _storage.isAuthenticated();
    
    if (isAuthenticated) {
      // Si está autenticado, ir directo al home
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    // 2. Verificar si ya completó el onboarding
    final hasCompletedOnboarding = await _storage.hasCompletedOnboarding();
    
    if (hasCompletedOnboarding) {
      // Si ya vio el onboarding, ir al login con un pequeño delay para transición suave
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      // Si no ha visto el onboarding, mostrarlo
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
