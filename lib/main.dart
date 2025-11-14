import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TaskControlApp());
}

class TaskControlApp extends StatelessWidget {
  const TaskControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // 👇 Usamos rutas nombradas para poder añadir SignUp y Home luego
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        // Más adelante:
        // '/signup': (context) => const SignUpScreen(),
        // '/home': (context) => const HomeScreen(),
      },
    );
  }
}
