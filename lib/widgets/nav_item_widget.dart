import 'package:flutter/material.dart';
import '../config/theme_config.dart';

/// Navigation item con estilo premium y soporte responsive
class PremiumNavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool isCompact;

  const PremiumNavItem({
    super.key,
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
    this.badgeCount,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = isCompact ? 20 : 22;
    final double fontSize = isCompact ? 10 : 11;
    final containerPadding = isCompact
        ? const EdgeInsets.symmetric(vertical: 6, horizontal: 8)
        : const EdgeInsets.symmetric(vertical: 8, horizontal: 12);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animationNormal,
        padding: containerPadding,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [activeColor, activeColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive
              ? null
              : Colors.transparent,
          borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: isCompact ? 4 : 8,
                    offset: Offset(0, isCompact ? 1 : 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Icon and label
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? (activeIcon ?? icon) : icon,
                  size: iconSize,
                  color: isActive
                      ? Colors.white
                      : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
                ),
                if (!isCompact && label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : (isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary),
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            // Badge
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                right: isCompact ? -2 : 0,
                top: isCompact ? -2 : -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? Colors.white : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.dangerRed.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badgeCount! > 9 ? '9+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
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
}