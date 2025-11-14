import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

                  // LOGO + TÍTULO aún MÁS arriba
                  Padding(
                    padding: const EdgeInsets.only(top: 0), // SUBIDO MÁS TODAVÍA
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/TaskControl_logo.png',
                          height: 300,
                          color: Colors.white,
                        ),

                        const SizedBox(height: 4), // Logito súper pegado al título

                        const Text(
                          'Bienvenido',           // ← NUEVO TEXTO
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,        // Tamaño mantenido
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),  // Formulario subido más

                  // INPUT Email
                  _buildInputField(
                    controller: _emailController,
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 14),

                  // INPUT Contraseña
                  _buildInputField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),

                  const SizedBox(height: 20),

                  // BOTÓN Iniciar sesión
                  _buildGradientButton(
                    text: 'Iniciar sesión',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login aún no implementado')),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Link registro
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

  // ───────────────────────────── INPUT HELPER ─────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
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
          borderSide: const BorderSide(color: Colors.white70, width: 1),
        ),
      ),
    );
  }

  // ───────────────────────────── BOTÓN HELPER ─────────────────────────────
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
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
