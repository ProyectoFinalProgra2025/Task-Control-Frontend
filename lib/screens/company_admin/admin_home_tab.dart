import 'package:flutter/material.dart';
import '../../widgets/create_task_modal.dart';
import '../../widgets/theme_toggle_button.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  String _selectedTab = 'Ongoing';

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
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF135bec).withOpacity(0.1),
                          child: Icon(Icons.person, color: const Color(0xFF135bec)),
                        ),
                        const Spacer(),
                        const ThemeToggleButton(),
                        IconButton(
                          icon: Icon(Icons.notifications_outlined, color: textPrimary),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Good Morning, Admin',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Action Grid
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.add_task,
                      title: 'Create Task',
                      description: 'Assign new tasks',
                      color: const Color(0xFF135bec),
                      cardColor: cardColor,
                      textColor: textPrimary,
                      descColor: textSecondary,
                      onTap: _showCreateTaskModal,
                    ),
                    _buildQuickActionCard(
                      icon: Icons.group,
                      title: 'View Team',
                      description: 'Manage members',
                      color: const Color(0xFF7C3AED),
                      cardColor: cardColor,
                      textColor: textPrimary,
                      descColor: textSecondary,
                      onTap: () => _showComingSoon('View Team'),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.account_tree,
                      title: 'Workflows',
                      description: 'Automate processes',
                      color: const Color(0xFFEC4899),
                      cardColor: cardColor,
                      textColor: textPrimary,
                      descColor: textSecondary,
                      onTap: () => _showComingSoon('Workflows'),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.bar_chart,
                      title: 'Reports',
                      description: 'View analytics',
                      color: const Color(0xFFF59E0B),
                      cardColor: cardColor,
                      textColor: textPrimary,
                      descColor: textSecondary,
                      onTap: () => _showComingSoon('Reports'),
                    ),
                  ],
                ),
              ),

              // Task Summary Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Task Summary',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),

              // Task Summary Card with Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF324467) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? const Color(0xFF324467) : const Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildTab('Ongoing', textPrimary, textSecondary),
                            _buildTab('Overdue', textPrimary, textSecondary),
                            _buildTab('Completed', textPrimary, textSecondary),
                          ],
                        ),
                      ),
                      // Task List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 3,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDark ? const Color(0xFF324467) : const Color(0xFFE5E7EB),
                        ),
                        itemBuilder: (context, index) => _buildTaskItem(
                          title: 'Task ${index + 1}',
                          assignee: 'John Doe',
                          dueDate: 'Nov ${18 + index}',
                          status: index == 0 ? 'In Progress' : 'Pending',
                          statusColor: index == 0 ? const Color(0xFF135bec) : const Color(0xFFF59E0B),
                          textColor: textPrimary,
                          descColor: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100), // Extra space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color descColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: descColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, Color textPrimary, Color textSecondary) {
    final isSelected = _selectedTab == title;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF135bec) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF135bec) : textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String assignee,
    required String dueDate,
    required String status,
    required Color statusColor,
    required Color textColor,
    required Color descColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        '$assignee • Due: $dueDate',
        style: TextStyle(
          fontSize: 14,
          color: descColor,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
