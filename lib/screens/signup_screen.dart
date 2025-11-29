import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  // Controladores para datos del administrador
  final TextEditingController _nombreCompletoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Controladores para datos de la empresa
  final TextEditingController _nombreEmpresaController = TextEditingController();
  final TextEditingController _direccionEmpresaController = TextEditingController();
  final TextEditingController _telefonoEmpresaController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreEmpresaController.dispose();
    _direccionEmpresaController.dispose();
    _telefonoEmpresaController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email.trim());
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
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> onRegisterPressed() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registerEmpresa(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nombreCompleto: _nombreCompletoController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        nombreEmpresa: _nombreEmpresaController.text.trim(),
        direccionEmpresa: _direccionEmpresaController.text.trim().isEmpty
            ? null
            : _direccionEmpresaController.text.trim(),
        telefonoEmpresa: _telefonoEmpresaController.text.trim().isEmpty
            ? null
            : _telefonoEmpresaController.text.trim(),
      );

      if (!mounted) return;

      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFC1FF72).withOpacity(0.2),
                        const Color(0xFFA8E84F).withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF66BB6A),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Registro enviado!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu solicitud de registro ha sido enviada exitosamente.\n\n'
                  'Nuestro equipo revisará tu solicitud y te notificaremos por email cuando sea aprobada.\n\n'
                  'Podrás iniciar sesión después de la aprobación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC1FF72),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Error al registrar';
      if (e.toString().contains('email ya está registrado') ||
          e.toString().contains('already exists')) {
        errorMessage = 'Este email ya está registrado';
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header con gradiente verde
          _buildHeader(size),

          // Formulario
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),

                      // Sección: Información Personal
                      _buildSectionTitle('Información Personal', Icons.person_outline_rounded),
                      const SizedBox(height: 20),

                      // Nombre completo
                      _buildFormField(
                        controller: _nombreCompletoController,
                        label: 'Full Name',
                        hint: 'Tu nombre completo',
                        prefixIcon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email
                      _buildFormField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'nombre@empresa.com',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El email es requerido';
                          }
                          if (!isValidEmail(value)) {
                            return 'Formato de email inválido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Teléfono (opcional)
                      _buildFormField(
                        controller: _telefonoController,
                        label: 'Phone (Optional)',
                        hint: '+1 234 567 890',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      // Password
                      _buildFormField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Mínimo 8 caracteres',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La contraseña es requerida';
                          }
                          if (value.length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Confirmar Password
                      _buildFormField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Repite tu contraseña',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Sección: Información de la Empresa
                      _buildSectionTitle('Información de la Empresa', Icons.business_outlined),
                      const SizedBox(height: 20),

                      // Nombre empresa
                      _buildFormField(
                        controller: _nombreEmpresaController,
                        label: 'Company Name',
                        hint: 'Nombre de tu empresa',
                        prefixIcon: Icons.apartment_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre de empresa es requerido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Dirección empresa
                      _buildFormField(
                        controller: _direccionEmpresaController,
                        label: 'Address (Optional)',
                        hint: 'Dirección de la empresa',
                        prefixIcon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 16),

                      // Teléfono empresa
                      _buildFormField(
                        controller: _telefonoEmpresaController,
                        label: 'Company Phone (Optional)',
                        hint: '+1 234 567 890',
                        prefixIcon: Icons.phone_in_talk_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 36),

                      // Botón Register
                      _buildRegisterButton(),

                      const SizedBox(height: 24),

                      // Link a login
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                              children: const [
                                TextSpan(text: '¿Ya tienes cuenta? '),
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                    color: Color(0xFF66BB6A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      height: size.height * 0.22,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFC1FF72),
            Color(0xFFB5F562),
            Color(0xFFA8E84F),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Círculos decorativos
            Positioned(
              right: -50,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Botón back
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registra tu empresa y comienza a gestionar tareas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFC1FF72).withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF66BB6A),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? obscureText : false,
          style: const TextStyle(fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.grey[500],
              size: 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[500],
                      size: 22,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFC1FF72),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              height: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onRegisterPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC1FF72),
          foregroundColor: Colors.black87,
          elevation: 0,
          shadowColor: const Color(0xFFC1FF72).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black87,
                ),
              )
            : const Text(
                'Create Account',
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
