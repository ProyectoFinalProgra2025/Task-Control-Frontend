import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_home_tab.dart';
import 'admin_chats_tab.dart';
import 'admin_tasks_tab.dart';
import 'admin_profile_tab.dart';
import '../../widgets/create_task_modal.dart';
import '../../widgets/premium_widgets.dart';
import '../../config/theme_config.dart';
import '../../providers/chat_provider.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminHomeTab(onNavigateToTasks: () => setState(() => _currentIndex = 2)),
      const AdminChatsTab(),
      const AdminTasksTab(),
      const AdminProfileTab(),
    ];
  }

  void _showCreateTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateTaskModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final unreadCount = chatProvider.totalUnreadCount;
          
          return Container(
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
                  horizontal: AppTheme.spaceSmall,
                  vertical: AppTheme.spaceSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    PremiumNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      isActive: _currentIndex == 0,
                      activeColor: AppTheme.primaryBlue,
                      isDark: isDark,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    PremiumNavItem(
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Chats',
                      isActive: _currentIndex == 1,
                      activeColor: AppTheme.primaryBlue,
                      isDark: isDark,
                      badgeCount: unreadCount,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                // Center FAB for creating tasks
                _buildCenterFAB(),
                PremiumNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: 'Tasks',
                  isActive: _currentIndex == 2,
                  activeColor: AppTheme.primaryBlue,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                PremiumNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 3,
                  activeColor: AppTheme.primaryBlue,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
        );
        },
      ),
    );
  }

  Widget _buildCenterFAB() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppTheme.gradientBlue,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showCreateTaskModal,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
