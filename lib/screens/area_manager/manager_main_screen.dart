import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'manager_home_tab.dart';
import '../common/chat_list_screen.dart';
import 'manager_tasks_tab.dart';
import 'manager_team_tab.dart';
import 'manager_profile_tab.dart';
import '../../widgets/create_task_modal.dart';
import '../../widgets/premium_widgets.dart';
import '../../config/theme_config.dart';
import '../../providers/chat_provider.dart';

/// Main screen for Area Managers (ManagerDepartamento)
/// Combines functionality from both AdminEmpresa and Usuario (Worker)
class ManagerMainScreen extends StatefulWidget {
  const ManagerMainScreen({super.key});

  @override
  State<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ManagerHomeTab(),
    const ChatListScreen(),
    const ManagerTasksTab(),
    const ManagerTeamTab(),
    const ManagerProfileTab(),
  ];

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
    // Refresh chats when navigating to chat tab
    if (index == 1) {
      _refreshChats();
    }
  }

  void _refreshChats() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.refreshChats();
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
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Floating FAB above navbar
          Positioned(
            left: 0,
            right: 0,
            bottom: 10, // Slightly above navbar, better integrated
            child: Center(
              child: _buildFloatingFAB(isDark),
            ),
          ),
        ],
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
                  horizontal: AppTheme.spaceRegular,
                  vertical: AppTheme.spaceSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    PremiumNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      isActive: _currentIndex == 0,
                      activeColor: AppTheme.successGreen,
                      isDark: isDark,
                      onTap: () => _navigateTo(0),
                    ),
                    PremiumNavItem(
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Chats',
                      isActive: _currentIndex == 1,
                      activeColor: AppTheme.successGreen,
                      isDark: isDark,
                      badgeCount: unreadCount,
                      onTap: () => _navigateTo(1),
                    ),
                PremiumNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: 'Tasks',
                  isActive: _currentIndex == 2,
                  activeColor: AppTheme.successGreen,
                  isDark: isDark,
                  onTap: () => _navigateTo(2),
                ),
                PremiumNavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people_rounded,
                  label: 'Team',
                  isActive: _currentIndex == 3,
                  activeColor: AppTheme.successGreen,
                  isDark: isDark,
                  onTap: () => _navigateTo(3),
                ),
                PremiumNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  activeColor: AppTheme.successGreen,
                  isDark: isDark,
                  onTap: () => _navigateTo(4),
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

  Widget _buildFloatingFAB(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.successGreen, Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreen.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showCreateTaskModal,
          borderRadius: BorderRadius.circular(28),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
