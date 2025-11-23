import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';
import '../../services/empresa_service.dart';
import '../../models/usuario.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final StorageService _storage = StorageService();
  final AuthService _authService = AuthService();
  final UsuarioService _usuarioService = UsuarioService();
  final EmpresaService _empresaService = EmpresaService();
  
  Map<String, dynamic>? _userData;
  Usuario? _usuarioCompleto;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Obtener datos actualizados desde el backend
      _usuarioCompleto = await _usuarioService.getMe();
      
      // Obtener nombre de la empresa usando el empresaId
      String? nombreEmpresa;
      final empresaId = _usuarioCompleto?.empresaId ?? await _storage.getEmpresaId();
      
      if (empresaId != null) {
        try {
          final estadisticas = await _empresaService.obtenerEstadisticas(empresaId);
          nombreEmpresa = estadisticas['nombreEmpresa']?.toString();
        } catch (e) {
          nombreEmpresa = null;
        }
      }
      
      // Combinar datos del backend
      setState(() {
        _userData = {
          'id': _usuarioCompleto!.id,
          'email': _usuarioCompleto!.email,
          'nombreCompleto': _usuarioCompleto!.nombreCompleto,
          'telefono': _usuarioCompleto!.telefono,
          'rol': _usuarioCompleto!.rol,
          'empresaId': _usuarioCompleto!.empresaId,
          'nombreEmpresa': nombreEmpresa,
          'departamento': _usuarioCompleto!.departamento,
        };
        _isLoading = false;
      });
    } catch (e) {
      // Si falla el backend, usar datos locales
      final localUserData = await _storage.getUserData();
      setState(() {
        _userData = localUserData;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf0f2f5);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Mi Perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),

              // Profile Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF005A9C).withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF005A9C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userData?['nombreCompleto'] ?? 'Admin User',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Company Admin',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005A9C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Editar Perfil'),
                    ),
                  ],
                ),
              ),

              // Personal Information Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Personal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoItem(
                            icon: Icons.person,
                            label: 'Nombre Completo',
                            value: _userData?['nombreCompleto'] ?? 'N/A',
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                          _buildInfoItem(
                            icon: Icons.badge,
                            label: 'Titulo de Trabajo',
                            value: 'Project Manager',
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                          _buildInfoItem(
                            icon: Icons.email,
                            label: 'Correo Electronico',
                            value: _userData?['email'] ?? 'N/A',
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                          _buildInfoItem(
                            icon: Icons.phone,
                            label: 'Telefono',
                            value: _userData?['telefono'] ?? 'N/A',
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Company Information Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de la Empresa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoItem(
                            icon: Icons.business,
                            label: 'Nombre de la Empresa',
                            value: _userData?['nombreEmpresa'] ?? 'N/A',
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                          _buildInfoItem(
                            icon: Icons.admin_panel_settings,
                            label: 'Rol',
                            value: _userData?['rol'] ?? 'Admin',
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Logout Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD93025),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                ),
              ),
              const SizedBox(height: 100), // Extra space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF005A9C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF005A9C)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
