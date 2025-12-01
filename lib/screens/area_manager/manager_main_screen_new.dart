import 'package:flutter/material.dart';
import 'manager_home_tab.dart';
import '../common/chat_list_screen.dart';
import 'manager_tasks_tab.dart';
import 'manager_team_tab.dart';
import 'manager_profile_tab.dart';
import '../../widgets/chat_floating_button.dart';
import '../../config/theme_config.dart';

/// Manager Main Screen - Versión optimizada con chat accesible
class ManagerMainScreenNew extends StatefulWidget {
  const ManagerMainScreenNew({super.key});

  @override
  State<ManagerMainScreenNew> createState() => _ManagerMainScreenNewState();
}

class _ManagerMainScreenNewState extends State<ManagerMainScreenNew> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = [
    const ManagerHomeTab(),
    const ChatListScreen(),
    const ManagerTasksTab(),
    const ManagerTeamTab(),
    const ManagerProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index, bool isDark) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _navigateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryBlue : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.primaryBlue : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChatFloatingButtonWrapper(
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkScaffold : AppTheme.lightScaffold,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceRegular,
                vertical: AppTheme.spaceSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Panel', 0, isDark),
                  _buildNavItem(Icons.chat_outlined, Icons.chat_rounded, 'Chat', 1, isDark),
                  _buildNavItem(Icons.task_alt_outlined, Icons.task_alt_rounded, 'Tareas', 2, isDark),
                  _buildNavItem(Icons.groups_outlined, Icons.groups_rounded, 'Equipo', 3, isDark),
                  _buildNavItem(Icons.person_outlined, Icons.person_rounded, 'Perfil', 4, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}