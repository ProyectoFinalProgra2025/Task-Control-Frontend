import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../config/theme_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final rememberMe = await _storageService.getRememberMe();
    if (rememberMe) {
      final credentials = await _storageService.getSavedCredentials();
      if (credentials != null && mounted) {
        setState(() {
          _rememberMe = true;
          _emailController.text = credentials['email'] ?? '';
          _passwordController.text = credentials['password'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email.trim());
  }

  bool validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !isValidEmail(email)) {
      _showErrorSnackBar('Por favor ingresa un email válido');
      return false;
    }

    if (password.isEmpty) {
      _showErrorSnackBar('Por favor ingresa tu contraseña');
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

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

      // Guardar credenciales si Remember Me está activado
      await _storageService.saveRememberMe(
        rememberMe: _rememberMe,
        email: _rememberMe ? email : null,
        password: _rememberMe ? password : null,
      );

      if (!mounted) return;

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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('¡Bienvenido, ${authResponse.usuario.nombreCompleto}!'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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
        errorMessage = 'No se puede conectar al servidor';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // Fondo azul con ondas
              _buildBlueBackground(size),

              // Contenido
              SafeArea(
                child: Column(
                  children: [
                    // Header con logo y título
                    _buildHeader(size),

                    // Formulario blanco
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildFormCard(size),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlueBackground(Size size) {
    return Container(
      height: size.height * 0.45,
      width: double.infinity,
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
          // Ondas decorativas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size.width, 120),
              painter: WavePainter(
                color: Colors.white.withOpacity(0.05),
                amplitude: 20,
                phase: 0,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size.width, 100),
              painter: WavePainter(
                color: Colors.white.withOpacity(0.08),
                amplitude: 15,
                phase: math.pi / 2,
              ),
            ),
          ),
          // Círculos decorativos
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 50,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      height: size.height * 0.28,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Logo
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/TaskControl_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Título
          const Text(
            'Hello!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicia sesión con tu\nemail y contraseña.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(Size size) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del formulario
            const Text(
              'Sign in',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 28),

            // Campo Email
            _buildTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              hint: 'Enter your email',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              nextFocus: _passwordFocus,
            ),

            const SizedBox(height: 18),

            // Campo Password
            _buildTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              onSubmitted: (_) => onLoginPressed(),
            ),

            const SizedBox(height: 16),

            // Remember me y Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remember me
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _rememberMe = !_rememberMe;
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _rememberMe
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Forgot password
                GestureDetector(
                  onTap: () {
                    // TODO: Implementar forgot password
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Botón Sign in
            _buildSignInButton(),

            const SizedBox(height: 24),

            // Link a registro
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/signup'),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                    children: [
                      const TextSpan(text: "Don't have an account?  "),
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    FocusNode? nextFocus,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppTheme.primaryBlue.withOpacity(0.5)
              : Colors.grey.shade200,
          width: focusNode.hasFocus ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: isPassword ? obscureText : false,
        style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 255, 255, 255)),
        textInputAction:
            nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onSubmitted: onSubmitted ??
            (_) {
              if (nextFocus != null) {
                FocusScope.of(context).requestFocus(nextFocus);
              }
            },
        onTap: () => setState(() {}),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.grey.shade500,
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onLoginPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

// Custom painter para las ondas
class WavePainter extends CustomPainter {
  final Color color;
  final double amplitude;
  final double phase;

  WavePainter({
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
