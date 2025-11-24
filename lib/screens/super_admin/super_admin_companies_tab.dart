import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/empresa_service.dart';
import '../../models/empresa_model.dart';
import '../../config/theme_config.dart';
import '../../widgets/premium_widgets.dart';
import '../../providers/realtime_provider.dart';

class SuperAdminCompaniesTab extends StatefulWidget {
  const SuperAdminCompaniesTab({super.key});

  @override
  State<SuperAdminCompaniesTab> createState() => _SuperAdminCompaniesTabState();
}

class _SuperAdminCompaniesTabState extends State<SuperAdminCompaniesTab>
    with SingleTickerProviderStateMixin {
  final EmpresaService _empresaService = EmpresaService();
  String _selectedTab = 'Pending';
  List<EmpresaModel> _empresas = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  StreamSubscription? _empresaEventSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadEmpresas();
    _connectRealtime();
    _subscribeToRealtimeEvents();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _empresaEventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _connectRealtime() async {
    final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
    if (!realtimeProvider.isConnected) {
      try {
        await realtimeProvider.connect(isSuperAdmin: true);
        print('SuperAdminCompaniesTab: ✅ Real-time enabled');
      } catch (e) {
        print('SuperAdminCompaniesTab: ⚠️ Real-time not available: $e');
        // Continue without real-time
      }
    }
  }

  void _subscribeToRealtimeEvents() {
    final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
    
    _empresaEventSubscription = realtimeProvider.empresaEventStream.listen((event) {
      print('SuperAdminCompaniesTab: 🏢 Empresa ${event['eventType']}');
      _loadEmpresas();
      
      if (mounted) {
        final eventType = event['eventType'] as String;
        final nombre = event['nombre'] as String? ?? 'Empresa';
        String message = '';
        
        switch (eventType) {
          case 'created':
            message = '🆕 Nueva empresa: $nombre';
            break;
          case 'approved':
            message = '✅ Empresa aprobada: $nombre';
            break;
          case 'rejected':
            message = '❌ Empresa rechazada: $nombre';
            break;
        }
        
        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppTheme.primaryPurple,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  Future<void> _loadEmpresas() async {
    setState(() => _isLoading = true);
    _animationController.reset();
    try {
      final empresas = await _empresaService.listarEmpresas(estado: _selectedTab);
      setState(() {
        _empresas = empresas;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(child: Text('Error al cargar empresas: $e')),
              ],
            ),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  Future<void> _aprobarEmpresa(String id, String nombre) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Text(
                'Aprobar Empresa',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Deseas aprobar la empresa "$nombre"?\n\nEsta empresa podrá acceder a todas las funcionalidades del sistema.',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            PremiumButton(
              text: 'Aprobar',
              onPressed: () => Navigator.of(context).pop(true),
              gradientColors: [AppTheme.successGreen, const Color(0xFF059669)],
              icon: Icons.check_rounded,
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _empresaService.aprobarEmpresa(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(child: Text('Empresa "$nombre" aprobada exitosamente')),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
          _loadEmpresas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.dangerRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _rechazarEmpresa(String id, String nombre) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  color: AppTheme.dangerRed,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Text(
                'Rechazar Empresa',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Deseas rechazar la empresa "$nombre"?',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            PremiumButton(
              text: 'Rechazar',
              onPressed: () => Navigator.of(context).pop(true),
              gradientColors: [AppTheme.dangerRed, const Color(0xFFDC2626)],
              icon: Icons.close_rounded,
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _empresaService.rechazarEmpresa(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.white),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(child: Text('Empresa "$nombre" rechazada')),
                ],
              ),
              backgroundColor: AppTheme.dangerRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
          _loadEmpresas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.dangerRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _eliminarEmpresa(String id, String nombre) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppTheme.dangerRed,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Text(
                'Eliminar Empresa',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de eliminar permanentemente "$nombre"?\n\nEsta acción no se puede deshacer y se eliminarán todos los datos asociados.',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            PremiumButton(
              text: 'Eliminar',
              onPressed: () => Navigator.of(context).pop(true),
              gradientColors: [AppTheme.dangerRed, const Color(0xFFDC2626)],
              icon: Icons.delete_rounded,
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _empresaService.eliminarEmpresa(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.white),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(child: Text('Empresa "$nombre" eliminada')),
                ],
              ),
              backgroundColor: AppTheme.dangerRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
          _loadEmpresas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.dangerRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título con gradiente
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppTheme.gradientPurple,
                    ).createShader(bounds),
                    child: Text(
                      'Gestión de Empresas',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeHuge,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    'Aprobar, rechazar o eliminar empresas del sistema',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Modern Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceRegular),
              padding: const EdgeInsets.all(AppTheme.spaceXSmall),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkBorder.withOpacity(0.5)
                      : AppTheme.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildModernTab('Pending', 'Pendientes', Icons.pending_actions_rounded, isDark),
                  _buildModernTab('Approved', 'Aprobadas', Icons.check_circle_rounded, isDark),
                  _buildModernTab('Rejected', 'Rechazadas', Icons.cancel_rounded, isDark),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceRegular),

            // Company List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppTheme.gradientPurple,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceRegular),
                          Text(
                            'Cargando empresas...',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _empresas.isEmpty
                      ? Center(
                          child: PremiumEmptyState(
                            icon: Icons.business_rounded,
                            title: 'No hay empresas',
                            subtitle: _selectedTab == "Pending"
                                ? "No hay empresas pendientes de aprobación"
                                : _selectedTab == "Approved"
                                    ? "No hay empresas aprobadas"
                                    : "No hay empresas rechazadas",
                            isDark: isDark,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEmpresas,
                          color: AppTheme.primaryPurple,
                          strokeWidth: 3,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.spaceRegular,
                              0,
                              AppTheme.spaceRegular,
                              100,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: _empresas.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppTheme.spaceMedium),
                            itemBuilder: (context, index) {
                              return FadeTransition(
                                opacity: _animationController,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(_animationController),
                                  child: _buildPremiumCompanyCard(
                                    empresa: _empresas[index],
                                    isDark: isDark,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTab(String value, String label, IconData icon, bool isDark) {
    final isActive = _selectedTab == value;

    Color getTabColor() {
      if (value == 'Pending') return AppTheme.warningOrange;
      if (value == 'Approved') return AppTheme.successGreen;
      return AppTheme.dangerRed;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = value);
          _loadEmpresas();
        },
        child: AnimatedContainer(
          duration: AppTheme.animationNormal,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      getTabColor(),
                      getTabColor().withOpacity(0.8),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: getTabColor().withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
              const SizedBox(width: AppTheme.spaceXSmall),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCompanyCard({
    required EmpresaModel empresa,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withOpacity(0.5)
              : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Icon con gradiente
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppTheme.gradientPurple,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empresa.nombre,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (empresa.direccion != null) ...[
                        const SizedBox(height: AppTheme.spaceXSmall),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: isDark
                                  ? AppTheme.darkTextTertiary
                                  : AppTheme.lightTextTertiary,
                            ),
                            const SizedBox(width: AppTheme.spaceXSmall),
                            Expanded(
                              child: Text(
                                empresa.direccion!,
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeSmall,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                // Status badge
                TaskStateBadge(
                  text: empresa.estadoDisplayName,
                  color: _getStatusColor(empresa.estado),
                ),
              ],
            ),

            if (empresa.telefono != null) ...[
              const SizedBox(height: AppTheme.spaceMedium),
              InfoRow(
                icon: Icons.phone_rounded,
                text: empresa.telefono!,
                isDark: isDark,
              ),
            ],

            const SizedBox(height: AppTheme.spaceRegular),

            // Action Buttons
            Row(
              children: [
                if (_selectedTab == 'Pending') ...[
                  Expanded(
                    child: PremiumButton(
                      text: 'Aprobar',
                      onPressed: () => _aprobarEmpresa(empresa.id, empresa.nombre),
                      gradientColors: [AppTheme.successGreen, const Color(0xFF059669)],
                      icon: Icons.check_rounded,
                      isFullWidth: true,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: PremiumButton(
                      text: 'Rechazar',
                      onPressed: () => _rechazarEmpresa(empresa.id, empresa.nombre),
                      gradientColors: [AppTheme.dangerRed, const Color(0xFFDC2626)],
                      icon: Icons.close_rounded,
                      isFullWidth: true,
                    ),
                  ),
                ],
                if (_selectedTab != 'Pending') ...[
                  Expanded(
                    child: PremiumButton(
                      text: 'Eliminar',
                      onPressed: () => _eliminarEmpresa(empresa.id, empresa.nombre),
                      gradientColors: [AppTheme.dangerRed, const Color(0xFFDC2626)],
                      icon: Icons.delete_rounded,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Pending':
        return AppTheme.warningOrange;
      case 'Approved':
        return AppTheme.successGreen;
      case 'Rejected':
        return AppTheme.dangerRed;
      default:
        return AppTheme.lightTextTertiary;
    }
  }
}
