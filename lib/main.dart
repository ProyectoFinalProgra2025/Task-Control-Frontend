import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/company_admin/admin_main_screen.dart';
import 'screens/area_manager/manager_main_screen.dart';
import 'screens/super_admin/super_admin_main_screen.dart';
import 'screens/worker/worker_main_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'services/storage_service.dart';
import 'services/chat_hub_service.dart';
import 'config/theme_config.dart';
import 'providers/theme_provider.dart' as theme_prov;
import 'providers/tarea_provider.dart';
import 'providers/admin_tarea_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  
  // Crear instancia singleton del servicio de SignalR
  final chatHubService = ChatHubService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => theme_prov.ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TareaProvider()),
        ChangeNotifierProvider(create: (_) => AdminTareaProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider(hub: chatHubService)),
      ],
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
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/home': (context) => const HomeScreen(),
            '/admin': (context) => const AdminMainScreen(),
            '/manager': (context) => const ManagerMainScreen(),
            '/super-admin': (context) => const SuperAdminMainScreen(),
            '/worker': (context) => const WorkerMainScreen(),
            '/chat': (context) => const ChatListScreen(),
            // Las rutas de chat detail y new requieren parámetros complejos
            // Se navegan mediante Navigator.push con los parámetros necesarios
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

    // Verificar token almacenado
    final token = await _storage.getAccessToken();
    
    if (token != null && token.isNotEmpty) {
      debugPrint('✅ Usuario autenticado - Verificando sesión...');
      
      // Si hay token, verificar el rol y redirigir
      final userData = await _storage.getUserData();
      if (userData != null) {
        // Determinar ruta según rol
        final rol = userData['rol'] as String?;
        String route = '/home';
        
        if (rol == 'AdminGeneral') {
          route = '/super-admin';
        } else if (rol == 'AdminEmpresa') {
          route = '/admin';
        } else if (rol == 'ManagerDepartamento') {
          route = '/manager';
        } else {
          route = '/home';
        }
        
        Navigator.of(context).pushReplacementNamed(route);
        return;
      }
    }
    
    // Si no hay token o no hay userData, ir al login
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
