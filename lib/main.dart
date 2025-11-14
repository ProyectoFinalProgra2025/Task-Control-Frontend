import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart'; // 👈 NUEVO

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
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(), // 👈 NUEVO
        // En el futuro:
        // '/home': (context) => const HomeScreen(),
      },
    );
  }
}
