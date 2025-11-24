import 'package:flutter/material.dart';
import 'manager_home_tab.dart';
import 'manager_chats_tab.dart';
import 'manager_tasks_tab.dart';
import 'manager_team_tab.dart';
import 'manager_profile_tab.dart';
import '../../widgets/create_task_modal.dart';

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
    const ManagerChatsTab(),
    const ManagerTasksTab(),
    const ManagerTeamTab(),
    const ManagerProfileTab(),
  ];

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF192233) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Chats',
                  index: 1,
                ),
                // Center FAB for creating tasks
                _buildCenterFAB(),
                _buildNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Tasks',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Team',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? const Color(0xFF135bec)
                    : (isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b)),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF135bec)
                      : (isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFAB() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: FloatingActionButton(
        onPressed: _showCreateTaskModal,
        backgroundColor: const Color(0xFF135bec),
        elevation: 2,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
