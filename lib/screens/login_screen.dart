import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? emailError;
  String? passwordError;

  bool _obscurePassword = true; 
  bool _isLoading = false; // 👈 NUEVO: loading del botón

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ───────────────────────── VALIDACIÓN EMAIL ─────────────────────────
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email.trim());
  }

  // ───────────────────────── VALIDACIONES ─────────────────────────
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

  // ───────────────────────── LOGIN (con loading) ─────────────────────────
  Future<void> onLoginPressed() async {
    if (_isLoading) return; // evitar toques dobles

    if (!validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulamos llamada a backend
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Intentando iniciar sesión..."),
      ),
    );
  }

  // ───────────────────────── BUILD ─────────────────────────
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
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

                  _buildInputField(
                    controller: _emailController,
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                    errorText: emailError,
                  ),

                  const SizedBox(height: 14),

                  _buildPasswordField(),
                  const SizedBox(height: 20),

                  // BOTÓN CON LOADING
                  _buildGradientButton(
                    text: "Iniciar sesión",
                    onTap: onLoginPressed,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {},
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

  // ───────────────────────── PASSWORD FIELD ─────────────────────────
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

  // ───────────────────────── EMAIL FIELD ─────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            prefixIcon: Icon(icon, color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: errorText != null ? Colors.redAccent : Colors.white70,
                width: 1,
              ),
            ),
          ),
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              errorText!,
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

  // ───────────────────────── BOTÓN CON LOADING ─────────────────────────
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
