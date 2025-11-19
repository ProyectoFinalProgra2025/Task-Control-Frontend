import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../services/storage_service.dart';
import '../config/theme_config.dart';
import '../widgets/theme_toggle_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final StorageService _storage = StorageService();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'TaskControl Pro',
      description:
          'Sistema integral de gestión empresarial. Administra empresas, trabajadores y tareas desde un solo lugar.',
      icon: Icons.business_center,
      gradient: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    ),
    OnboardingPage(
      title: 'Gestión Multinivel',
      description:
          'Super Admins aprueban empresas. Admins de Empresa crean tareas con capacidades requeridas. Trabajadores ejecutan y reportan.',
      icon: Icons.supervisor_account,
      gradient: [Color(0xFF135BEC), Color(0xFF7C3AED)],
    ),
    OnboardingPage(
      title: 'Asignación Inteligente',
      description:
          'Asigna tareas según capacidades del trabajador. Establece prioridades, fechas límite y departamentos específicos.',
      icon: Icons.assignment_turned_in,
      gradient: [Color(0xFFEC4899), Color(0xFFF59E0B)],
    ),
    OnboardingPage(
      title: 'Seguimiento Completo',
      description:
          'Estados de tareas: Pendiente, Asignada, Aceptada, En Progreso, Finalizada. Visualiza estadísticas y progreso en tiempo real.',
      icon: Icons.analytics,
      gradient: [Color(0xFF10B981), Color(0xFF135BEC)],
    ),
    OnboardingPage(
      title: 'Comunicación Directa',
      description:
          'Chat integrado para coordinación. Los trabajadores pueden reportar avances y solicitar ayuda directamente desde las tareas.',
      icon: Icons.chat_bubble_outline,
      gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await _storage.markOnboardingCompleted();
    if (!mounted) return;
    // Pequeña pausa para transición visual suave
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Theme Toggle + Skip Button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceRegular),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ThemeToggleButton(),
                  TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceRegular,
                        vertical: AppTheme.spaceSmall,
                      ),
                    ),
                    child: Text(
                      'Saltar',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView with pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLarge),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: AppTheme.primaryPurple,
                  dotColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
            ),

            // Next/Get Started Button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: AppTheme.elevationNone,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Comenzar'
                        : 'Siguiente',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(90),
              boxShadow: [
                BoxShadow(
                  color: page.gradient[0].withOpacity(isDark ? 0.5 : 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: AppTheme.iconLarge * 2.5,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppTheme.spaceXXLarge),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTheme.fontSizeXXLarge,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              height: 1.2,
            ),
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
