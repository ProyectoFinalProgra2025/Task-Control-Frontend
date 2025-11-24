import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/chat_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? emailError;
  String? passwordError;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────── VALIDACIÓN EMAIL ───────────────────────
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email.trim());
  }

  // ─────────────────────── VALIDACIÓN GENERAL ───────────────────────
  bool validateInputs() {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    bool valid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      emailError = "El correo es obligatorio";
      valid = false;
    } else if (!isValidEmail(email)) {
      emailError = "Correo inválido";
      valid = false;
    }

    if (password.isEmpty) {
      passwordError = "La contraseña es obligatoria";
      valid = false;
    }

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor corrige los errores antes de continuar"),
        ),
      );
    }

    setState(() {});
    return valid;
  }

  // ─────────────────────── LOGIN CON BACKEND REAL ───────────────────────
  Future<void> onLoginPressed() async {
    if (_isLoading) return;
    if (!validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final authResponse = await _authService.login(email, password);

      if (!mounted) return;

      // Inicializar ChatProvider automáticamente después del login
      try {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.connectSignalR();
        chatProvider.loadChats();
        debugPrint('✅ ChatProvider initialized after login');
      } catch (e) {
        debugPrint('⚠️ Error initializing ChatProvider: $e');
        // Continuar aunque falle
      }

      // Login exitoso - navegar según el rol del usuario
      String route = '/home';
      if (authResponse.usuario.isAdminGeneral) {
        route = '/super-admin';
      } else if (authResponse.usuario.isAdminEmpresa) {
        route = '/admin';
      } else if (authResponse.usuario.isManagerDepartamento) {
        route = '/manager';
      } else {
        route = '/home';
      }

      Navigator.pushReplacementNamed(context, route);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenido, ${authResponse.usuario.nombreCompleto}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Error al iniciar sesión';
      if (e.toString().contains('Credenciales incorrectas')) {
        errorMessage = 'Credenciales incorrectas';
      } else if (e.toString().contains('Connection refused') || 
                 e.toString().contains('Failed host lookup')) {
        errorMessage = 'No se pudo conectar al servidor. Verifica que el backend esté ejecutándose.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ─────────────────────── BUILD ───────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A6CFF),
              Color(0xFF11C3FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // LOGO + TÍTULO
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/TaskControl_logo.png',
                          height: 300,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bienvenido',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // EMAIL
                  _buildEmailField(),

                  const SizedBox(height: 14),

                  // PASSWORD
                  _buildPasswordField(),

                  const SizedBox(height: 20),

                  // BOTÓN LOGIN
                  _buildGradientButton(
                    text: "Iniciar sesión",
                    onTap: onLoginPressed,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 10),

                  // IR A SIGNUP
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      '¿No tienes cuenta? Regístrate',
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── UI: EMAIL FIELD ───────────────────────
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: emailError != null ? Colors.redAccent : Colors.white70,
                width: 1,
              ),
            ),
          ),
        ),

        if (emailError != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              emailError!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────── UI: PASSWORD FIELD ───────────────────────
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),

            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: passwordError != null ? Colors.redAccent : Colors.white70,
                width: 1,
              ),
            ),
          ),
        ),

        if (passwordError != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              passwordError!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────── UI: BOTÓN ───────────────────────
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A6CFF),
            Color(0xFF11C3FF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
