import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/company_admin/admin_main_screen.dart';
import 'screens/super_admin/super_admin_main_screen.dart';
import 'screens/worker/worker_main_screen.dart';
import 'services/storage_service.dart';
import 'models/user_model.dart';
import 'config/theme_config.dart';
import 'providers/theme_provider.dart' as theme_prov;

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => theme_prov.ThemeProvider(),
      child: const TaskControlApp(),
    ),
  );
}

class TaskControlApp extends StatelessWidget {
  const TaskControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<theme_prov.ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'TaskControl',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeProvider.themeMode,
          home: const InitialRouteHandler(),
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/home': (context) => const HomeScreen(),
            '/admin': (context) => const AdminMainScreen(),
            '/super-admin': (context) => const SuperAdminMainScreen(),
            '/worker': (context) => const WorkerMainScreen(),
          },
        );
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

    // ════════════════════════════════════════════════════════════
    // MODO DESARROLLO: SIEMPRE MOSTRAR ONBOARDING
    // TODO: Comentar línea siguiente y descomentar bloque para producción
    // ════════════════════════════════════════════════════════════
    Navigator.of(context).pushReplacementNamed('/onboarding');

    // ════════════════════════════════════════════════════════════
    // LÓGICA ORIGINAL - Descomentar para producción
    // ════════════════════════════════════════════════════════════
    /*
    // 1. Verificar si está autenticado
    final isAuthenticated = await _storage.isAuthenticated();
    
    if (isAuthenticated) {
      // Verificar el rol del usuario para enviarlo a la pantalla correcta
      final userData = await _storage.getUserData();
      if (userData != null) {
        final user = UserModel.fromJson(userData);
        
        if (user.isAdminGeneral) {
          // Admin General va al dashboard de super admin
          Navigator.of(context).pushReplacementNamed('/super-admin');
        } else if (user.isAdminEmpresa) {
          // Admin de Empresa va al dashboard de admin
          Navigator.of(context).pushReplacementNamed('/admin');
        } else {
          // Usuario normal va al home
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Si no hay userData, ir al login
        Navigator.of(context).pushReplacementNamed('/login');
      }
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
    */
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
