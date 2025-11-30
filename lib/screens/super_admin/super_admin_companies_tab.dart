import 'package:flutter/material.dart';
import '../../services/empresa_service.dart';
import '../../models/empresa_model.dart';
import '../../config/theme_config.dart';
import '../../widgets/premium_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadEmpresas();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
            // Header Section responsive
            LayoutBuilder(
              builder: (context, constraints) {
                final isVerySmallScreen = constraints.maxWidth < 300;
                final isSmallScreen = constraints.maxWidth < 350;

                return Padding(
                  padding: EdgeInsets.all(isVerySmallScreen ? 8 : AppTheme.spaceRegular),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título responsive con gradiente
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppTheme.gradientPurple,
                        ).createShader(bounds),
                        child: Text(
                          isVerySmallScreen ? 'Empresas' : 'Gestión de Empresas',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 24 : (isSmallScreen ? 28 : AppTheme.fontSizeHuge),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: isSmallScreen ? -0.3 : -0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 6 : AppTheme.spaceXSmall),
                      Text(
                        isVerySmallScreen
                            ? 'Administrar empresas'
                            : 'Aprobar, rechazar o eliminar empresas del sistema',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : AppTheme.fontSizeMedium,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Modern Tab Bar responsive
            LayoutBuilder(
              builder: (context, constraints) {
                final isVerySmallScreen = constraints.maxWidth < 300;
                final isSmallScreen = constraints.maxWidth < 350;

                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 8 : AppTheme.spaceRegular,
                  ),
                  padding: EdgeInsets.all(isVerySmallScreen ? 4 : AppTheme.spaceXSmall),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(isVerySmallScreen ? 8 : AppTheme.radiusLarge),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder.withOpacity(0.5)
                          : AppTheme.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: isSmallScreen ? 6 : 10,
                        offset: Offset(0, isSmallScreen ? 1 : 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildModernTab('Pending', isVerySmallScreen ? 'Pend.' : 'Pendientes', Icons.pending_actions_rounded, isDark, isCompact: isVerySmallScreen),
                      _buildModernTab('Approved', isVerySmallScreen ? 'Aprob.' : 'Aprobadas', Icons.check_circle_rounded, isDark, isCompact: isVerySmallScreen),
                      _buildModernTab('Rejected', isVerySmallScreen ? 'Rech.' : 'Rechazadas', Icons.cancel_rounded, isDark, isCompact: isVerySmallScreen),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.spaceRegular),

            // Company List responsive
            Expanded(
              child: _isLoading
                  ? Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isVerySmallScreen = constraints.maxWidth < 300;
                          final isSmallScreen = constraints.maxWidth < 350;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: isVerySmallScreen ? 50 : 60,
                                height: isVerySmallScreen ? 50 : 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppTheme.gradientPurple,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryPurple.withOpacity(0.3),
                                      blurRadius: isSmallScreen ? 12 : 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: isSmallScreen ? 2.5 : 3,
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 12 : AppTheme.spaceRegular),
                              Text(
                                isVerySmallScreen ? 'Cargando...' : 'Cargando empresas...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallScreen ? 14 : AppTheme.fontSizeMedium,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  : _empresas.isEmpty
                      ? Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isVerySmallScreen = constraints.maxWidth < 300;

                              return PremiumEmptyState(
                                icon: Icons.business_rounded,
                                title: 'No hay empresas',
                                subtitle: _selectedTab == "Pending"
                                    ? (isVerySmallScreen ? "Sin pendientes" : "No hay empresas pendientes de aprobación")
                                    : _selectedTab == "Approved"
                                        ? (isVerySmallScreen ? "Sin aprobadas" : "No hay empresas aprobadas")
                                        : (isVerySmallScreen ? "Sin rechazadas" : "No hay empresas rechazadas"),
                                isDark: isDark,
                              );
                            },
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEmpresas,
                          color: AppTheme.primaryPurple,
                          strokeWidth: 3,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isVerySmallScreen = constraints.maxWidth < 300;

                              return ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                  isVerySmallScreen ? 8 : AppTheme.spaceRegular,
                                  0,
                                  isVerySmallScreen ? 8 : AppTheme.spaceRegular,
                                  100,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: _empresas.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: isVerySmallScreen ? 8 : AppTheme.spaceMedium),
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
                                        isCompact: isVerySmallScreen,
                                      ),
                                    ),
                                  );
                                },
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

  Widget _buildModernTab(String value, String label, IconData icon, bool isDark, {bool isCompact = false}) {
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
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 8 : AppTheme.spaceMedium,
            horizontal: isCompact ? 4 : 8,
          ),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      getTabColor(),
                      getTabColor().withOpacity(0.8),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(isCompact ? 6 : AppTheme.radiusMedium),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: getTabColor().withOpacity(0.3),
                      blurRadius: isCompact ? 4 : 8,
                      offset: Offset(0, isCompact ? 1 : 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isCompact ? 14 : 18,
                color: isActive
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
              if (!isCompact) ...[
                const SizedBox(width: AppTheme.spaceXSmall),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : AppTheme.fontSizeSmall,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCompanyCard({
    required EmpresaModel empresa,
    required bool isDark,
    bool isCompact = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmallScreen = constraints.maxWidth < 300;
        final isSmallScreen = constraints.maxWidth < 350;
        final useCompactLayout = isCompact || isVerySmallScreen;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : AppTheme.radiusXLarge),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder.withOpacity(0.5)
                  : AppTheme.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: isSmallScreen ? 6 : 10,
                offset: Offset(0, isSmallScreen ? 2 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(useCompactLayout ? 12 : AppTheme.spaceRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header responsivo
                Row(
                  children: [
                    // Icon con gradiente responsivo
                    Container(
                      padding: EdgeInsets.all(useCompactLayout ? 10 : AppTheme.spaceMedium),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppTheme.gradientPurple,
                        ),
                        borderRadius: BorderRadius.circular(useCompactLayout ? 10 : AppTheme.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                            blurRadius: isSmallScreen ? 6 : 8,
                            offset: Offset(0, isSmallScreen ? 1 : 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: useCompactLayout ? 18 : 24,
                      ),
                    ),
                    SizedBox(width: useCompactLayout ? 10 : AppTheme.spaceMedium),
                    // Info responsiva
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            empresa.nombre,
                            style: TextStyle(
                              fontSize: useCompactLayout ? 14 : (isSmallScreen ? 16 : AppTheme.fontSizeLarge),
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                            maxLines: isVerySmallScreen ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (empresa.direccion != null && !useCompactLayout) ...[
                            SizedBox(height: isSmallScreen ? 2 : AppTheme.spaceXSmall),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: isSmallScreen ? 12 : 14,
                                  color: isDark
                                      ? AppTheme.darkTextTertiary
                                      : AppTheme.lightTextTertiary,
                                ),
                                SizedBox(width: isSmallScreen ? 4 : AppTheme.spaceXSmall),
                                Expanded(
                                  child: Text(
                                    empresa.direccion!,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : AppTheme.fontSizeSmall,
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
                    if (!useCompactLayout) ...[
                      SizedBox(width: isSmallScreen ? 6 : AppTheme.spaceSmall),
                      // Status badge
                      TaskStateBadge(
                        text: empresa.estadoDisplayName,
                        color: _getStatusColor(empresa.estado),
                      ),
                    ],
                  ],
                ),

                // Teléfono responsivo
                if (empresa.telefono != null && !useCompactLayout) ...[
                  SizedBox(height: isSmallScreen ? 8 : AppTheme.spaceMedium),
                  InfoRow(
                    icon: Icons.phone_rounded,
                    text: empresa.telefono!,
                    isDark: isDark,
                  ),
                ],

                SizedBox(height: useCompactLayout ? 10 : AppTheme.spaceRegular),

                // Action Buttons responsivos
                if (_selectedTab == 'Pending') ...[
                  if (useCompactLayout) ...[
                    // Compact vertical layout for very small screens
                    Column(
                      children: [
                        PremiumButton(
                          text: 'Aprobar',
                          onPressed: () => _aprobarEmpresa(empresa.id, empresa.nombre),
                          gradientColors: [AppTheme.successGreen, const Color(0xFF059669)],
                          icon: Icons.check_rounded,
                          isFullWidth: true,
                          isCompact: true,
                        ),
                        SizedBox(height: isSmallScreen ? 6 : AppTheme.spaceSmall),
                        PremiumButton(
                          text: 'Rechazar',
                          onPressed: () => _rechazarEmpresa(empresa.id, empresa.nombre),
                          gradientColors: [AppTheme.dangerRed, const Color(0xFFDC2626)],
                          icon: Icons.close_rounded,
                          isFullWidth: true,
                          isCompact: true,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Normal horizontal layout
                    Row(
                      children: [
                        Expanded(
                          child: PremiumButton(
                            text: 'Aprobar',
                            onPressed: () => _aprobarEmpresa(empresa.id, empresa.nombre),
                            gradientColors: [AppTheme.successGreen, const Color(0xFF059669)],
                            icon: Icons.check_rounded,
                            isFullWidth: true,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : AppTheme.spaceSmall),
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
                    ),
                  ],
                ] else if (!useCompactLayout) ...[
                  // Delete button for non-pending companies
                  PremiumButton(
                    text: 'Eliminar',
                    onPressed: () => _eliminarEmpresa(empresa.id, empresa.nombre),
                    gradientColors: [AppTheme.dangerRed, const Color(0xFFDC2626)],
                    icon: Icons.delete_rounded,
                    isFullWidth: true,
                  ),
                ] else ...[
                  // Compact delete button
                  PremiumButton(
                    text: 'Eliminar',
                    onPressed: () => _eliminarEmpresa(empresa.id, empresa.nombre),
                    gradientColors: [AppTheme.dangerRed, const Color(0xFFDC2626)],
                    icon: Icons.delete_rounded,
                    isFullWidth: true,
                    isCompact: true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
