import 'package:flutter/material.dart';
import 'super_admin_home_tab.dart';
import 'super_admin_companies_tab.dart';
import 'super_admin_chats_tab.dart';
import 'super_admin_profile_tab.dart';
import '../../widgets/premium_widgets.dart';
import '../../config/theme_config.dart';

class SuperAdminMainScreen extends StatefulWidget {
  const SuperAdminMainScreen({super.key});

  @override
  State<SuperAdminMainScreen> createState() => _SuperAdminMainScreenState();
}

class _SuperAdminMainScreenState extends State<SuperAdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SuperAdminHomeTab(),
    const SuperAdminCompaniesTab(),
    const SuperAdminChatsTab(),
    const SuperAdminProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          border: Border(
            top: BorderSide(
              color: isDark
                ? AppTheme.darkBorder.withOpacity(0.3)
                : AppTheme.lightBorder,
              width: 1,
            ),
          ),
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
                PremiumNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  activeColor: AppTheme.primaryPurple,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                PremiumNavItem(
                  icon: Icons.business_outlined,
                  activeIcon: Icons.business_rounded,
                  label: 'Empresas',
                  isActive: _currentIndex == 1,
                  activeColor: AppTheme.primaryPurple,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                PremiumNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Chats',
                  isActive: _currentIndex == 2,
                  activeColor: AppTheme.primaryPurple,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                PremiumNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Perfil',
                  isActive: _currentIndex == 3,
                  activeColor: AppTheme.primaryPurple,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
