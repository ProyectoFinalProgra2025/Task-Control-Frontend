import 'package:flutter/material.dart';
import 'admin_home_tab.dart';
import '../common/chat_list_screen.dart';
import 'admin_tasks_tab.dart';
import 'admin_profile_tab.dart';
import '../../widgets/chat_floating_button.dart';
import '../../config/theme_config.dart';

/// Admin Main Screen - Versión optimizada con chat accesible
class AdminMainScreenNew extends StatefulWidget {
  const AdminMainScreenNew({super.key});

  @override
  State<AdminMainScreenNew> createState() => _AdminMainScreenNewState();
}

class _AdminMainScreenNewState extends State<AdminMainScreenNew> {
  int _currentIndex = 0;
  late PageController _pageController;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      AdminHomeTab(onNavigateToTasks: () => _navigateTo(2)),
      const ChatListScreen(),
      const AdminTasksTab(),
      const AdminProfileTab(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
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
                  _buildNavItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings_rounded, 'Admin', 3, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}