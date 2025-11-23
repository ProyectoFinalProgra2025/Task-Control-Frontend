import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/usuario_provider.dart';
import '../../models/capacidad_nivel_item.dart';
import '../../config/capacidades.dart';

class WorkerProfileTab extends StatefulWidget {
  const WorkerProfileTab({super.key});

  @override
  State<WorkerProfileTab> createState() => _WorkerProfileTabState();
}

class _WorkerProfileTabState extends State<WorkerProfileTab> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsuarioProvider>(context, listen: false).cargarPerfil();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf0f2f5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Consumer<UsuarioProvider>(
        builder: (context, usuarioProvider, child) {
          if (usuarioProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final usuario = usuarioProvider.usuario;
          if (usuario == null) {
            return const Center(
              child: Text('No se pudo cargar el perfil'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  usuario.nombreCompleto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
                          ),
                    color: isDark ? const Color(0xFF192233) : null,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark
                        ? Border.all(color: const Color(0xFF324467))
                        : null,
                  ),
                  child: Text(
                    usuario.departamento ?? 'Sin departamento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF92A4C9) : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Capacidades Section
                _buildSection(
                  title: 'Mis Capacidades',
                  isDark: isDark,
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF005A9C)),
                    onPressed: () => _showAddCapacidadDialog(),
                  ),
                  children: [
                    if (usuario.capacidades.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No tienes capacidades registradas',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF92A4C9) : const Color(0xFF666666),
                          ),
                        ),
                      )
                    else
                      ...usuario.capacidades.map((cap) => Column(
                            children: [
                              _buildCapacidadTile(
                                nombre: cap.nombre,
                                nivel: cap.nivel,
                                capacidadId: cap.capacidadId,
                                isDark: isDark,
                              ),
                              if (cap != usuario.capacidades.last)
                                const Divider(height: 1),
                            ],
                          )),
                  ],
                ),
                const SizedBox(height: 24),

                // Personal Information Section
                _buildSection(
                  title: 'Información Personal',
                  isDark: isDark,
                  children: [
                    _buildInfoTile(
                      icon: Icons.mail,
                      label: 'Email',
                      value: usuario.email,
                      isDark: isDark,
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.phone,
                      label: 'Teléfono',
                      value: usuario.telefono ?? 'No registrado',
                      isDark: isDark,
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.business,
                      label: 'Departamento',
                      value: usuario.departamento ?? 'Sin departamento',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Account & Security Section
                _buildSection(
                  title: 'Cuenta y Seguridad',
                  isDark: isDark,
                  children: [
                    _buildInfoTile(
                      icon: Icons.badge,
                      label: 'ID de Usuario',
                      value: usuario.id.toString(),
                      isDark: isDark,
                    ),
                    const Divider(height: 1),
                    _buildSettingTile(
                      icon: Icons.lock,
                      title: 'Cambiar Contraseña',
                      isDark: isDark,
                      onTap: () {
                        // TODO: Change password
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Settings Section
                _buildSection(
                  title: 'Configuración',
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.notifications,
                      title: 'Notificaciones Push',
                      value: _notificationsEnabled,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingTile(
                      icon: Icons.help_outline,
                      title: 'Ayuda y Soporte',
                      isDark: isDark,
                      onTap: () {
                        // TODO: Help screen
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD93025),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
        },
      ),
    );
  }

  Widget _buildCapacidadTile({
    required String nombre,
    required int nivel,
    required String? capacidadId,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFF3F4F6), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDark ? const Color(0xFF0F1419) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          index < nivel ? Icons.star : Icons.star_border,
                          size: 16,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (capacidadId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: const Color(0xFFEF4444),
                onPressed: () => _deleteCapacidad(capacidadId),
                tooltip: 'Eliminar',
              ),
          ],
        ),
      ),
    );
  }

  void _showAddCapacidadDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CapacidadesWorkerSelectorSheet(
        usuarioProvider: Provider.of<UsuarioProvider>(context, listen: false),
      ),
    );
  }

  Future<void> _deleteCapacidad(String capacidadId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Capacidad'),
        content: const Text('¿Estás seguro de que deseas eliminar esta capacidad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final usuarioProvider =
          Provider.of<UsuarioProvider>(context, listen: false);
      final success = await usuarioProvider.eliminarCapacidad(capacidadId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capacidad eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(usuarioProvider.error ?? 'Error al eliminar capacidad'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [Color(0xFF192233), Color(0xFF1a2942)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.white, Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF324467) : const Color(0xFFE2E8F0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    letterSpacing: 0.3,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Column(children: children),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92A4C9) : const Color(0xFF64748b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF135bec).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF135bec),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF135bec).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF135bec),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF135bec),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD93025),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}

// Bottom Sheet para seleccionar capacidades predefinidas
class _CapacidadesWorkerSelectorSheet extends StatefulWidget {
  final UsuarioProvider usuarioProvider;

  const _CapacidadesWorkerSelectorSheet({
    required this.usuarioProvider,
  });

  @override
  State<_CapacidadesWorkerSelectorSheet> createState() =>
      _CapacidadesWorkerSelectorSheetState();
}

class _CapacidadesWorkerSelectorSheetState
    extends State<_CapacidadesWorkerSelectorSheet> {
  String? _selectedCapacidad;
  int _nivelSeleccionado = 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF4F6F8) : const Color(0xFF212529);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF6C757D);
    final borderColor = isDark ? const Color(0xFF324467) : const Color(0xFFE2E8F0);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 2)),
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? textSecondary : Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Agregar Capacidad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? textPrimary : Colors.white,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _selectedCapacidad != null
                          ? () async {
                              Navigator.of(context).pop();
                              
                              final capacidad = CapacidadNivelItem(
                                nombre: _selectedCapacidad!,
                                nivel: _nivelSeleccionado,
                              );

                              final success =
                                  await widget.usuarioProvider.agregarCapacidad(capacidad);

                              if (!mounted) return;

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Capacidad agregada exitosamente'),
                                    backgroundColor: Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      widget.usuarioProvider.error ??
                                          'Error al agregar capacidad',
                                    ),
                                    backgroundColor: const Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(
                        'Agregar',
                        style: TextStyle(
                          color: _selectedCapacidad != null
                              ? (isDark ? const Color(0xFF6366F1) : Colors.white)
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Nivel selector
              if (_selectedCapacidad != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? cardColor : const Color(0xFFF1F5F9),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionada: $_selectedCapacidad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nivel de dominio:',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (index) => IconButton(
                                icon: Icon(
                                  index < _nivelSeleccionado
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: const Color(0xFFF59E0B),
                                  size: 28,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _nivelSeleccionado = index + 1;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // List of capacidades
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    ...Capacidades.porCategoria.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...entry.value.map((capacidad) {
                            final isSelected = _selectedCapacidad == capacidad;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCapacidad = capacidad;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isSelected ? null : cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF6366F1)
                                          : borderColor,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  const Color(0xFF6366F1).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          capacidad,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : textPrimary,
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
