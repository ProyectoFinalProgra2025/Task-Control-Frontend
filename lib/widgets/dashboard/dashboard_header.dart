import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../theme_toggle_button.dart';

/// Header unificado para dashboards de CompanyAdmin y AreaManager
class DashboardHeader extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? companyName;
  final String? departmentName;
  final Color roleColor;
  final IconData roleIcon;
  final VoidCallback? onNotificationTap;
  final List<Widget>? extraActions;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.userRole,
    this.companyName,
    this.departmentName,
    this.roleColor = AppTheme.primaryBlue,
    this.roleIcon = Icons.business_rounded,
    this.onNotificationTap,
    this.extraActions,
  });

  String get _firstName => userName.split(' ').first;

  String get _initials {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkBorder.withOpacity(0.3)
                : AppTheme.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar + Actions
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: roleColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Actions
              const ThemeToggleButton(),
              const SizedBox(width: 8),
              if (extraActions != null) ...extraActions!,
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorder.withOpacity(0.3)
                        : AppTheme.lightBorder,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  onPressed: onNotificationTap ?? () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Welcome text
          Text(
            'Bienvenido, $_firstName',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              letterSpacing: -0.5,
            ),
          ),

          // Company/Department badge
          if (companyName != null || departmentName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, size: 14, color: roleColor),
                      const SizedBox(width: 6),
                      Text(
                        companyName ?? departmentName ?? userRole,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: roleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
