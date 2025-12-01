import 'package:flutter/material.dart';
import '../config/theme_config.dart';

// ═══════════════════════════════════════════════════════════════════
// PREMIUM DESIGN SYSTEM WIDGETS
// Componentes reutilizables con diseño premium y moderno
// ═══════════════════════════════════════════════════════════════════

/// Card premium con gradiente y glassmorphism effect
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool isDark;
  final List<Color>? gradientColors;
  final bool enableGlow;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    required this.isDark,
    this.gradientColors,
    this.enableGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spaceRegular),
      decoration: BoxDecoration(
        gradient: gradientColors != null
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradientColors == null
            ? (isDark ? AppTheme.darkCard : AppTheme.lightCard)
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withOpacity(0.3)
              : AppTheme.lightBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (enableGlow && gradientColors != null)
                ? gradientColors!.first.withOpacity(0.25)
                : Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: enableGlow ? 16 : 8,
            offset: Offset(0, enableGlow ? 6 : 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: widget,
      );
    }

    return widget;
  }
}

/// Stat card para métricas con iconos y colores
class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      isDark: isDark,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: AppTheme.iconRegular),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          // Value and title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXXLarge,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXSmall),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gradient button premium
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color>? gradientColors;
  final IconData? icon;
  final bool isOutlined;
  final bool isFullWidth;
  final bool isLoading;
  final bool isCompact;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradientColors,
    this.icon,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.isLoading = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [AppTheme.primaryBlue, AppTheme.primaryBlue];

    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: isCompact ? 14 : 16,
            height: isCompact ? 14 : 16,
            child: CircularProgressIndicator(
              strokeWidth: isCompact ? 1.5 : 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: isCompact ? 16 : AppTheme.iconSmall),
            SizedBox(width: isCompact ? 6 : AppTheme.spaceSmall),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: isCompact ? 14 : AppTheme.fontSizeMedium,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.first,
          side: BorderSide(color: colors.first, width: 1.5),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppTheme.spaceMedium : AppTheme.spaceXLarge,
            vertical: isCompact ? AppTheme.spaceSmall : AppTheme.spaceMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: buttonChild,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppTheme.spaceMedium : AppTheme.spaceXLarge,
            vertical: isCompact ? AppTheme.spaceSmall : AppTheme.spaceMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}

/// App Bar premium con avatar y acciones
class PremiumAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? avatar;
  final List<Widget> actions;
  final bool isDark;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.avatar,
    this.actions = const [],
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row con avatar y acciones
          Row(
            children: [
              if (avatar != null) ...[
                avatar!,
                const Spacer(),
              ],
              ...actions.map((action) => Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spaceSmall),
                    child: action,
                  )),
            ],
          ),
          const SizedBox(height: AppTheme.spaceRegular),
          // Título y subtítulo
          Text(
            title,
            style: TextStyle(
              fontSize: AppTheme.fontSizeHuge,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              height: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spaceXSmall),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom Navigation Item mejorado
class PremiumNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  final int? badgeCount;

  const PremiumNavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: AnimatedContainer(
          duration: AppTheme.animationNormal,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon con background animado y badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: AppTheme.animationNormal,
                    padding: isActive
                        ? const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceMedium,
                            vertical: AppTheme.spaceXSmall,
                          )
                        : EdgeInsets.zero,
                    decoration: isActive
                        ? BoxDecoration(
                            color: activeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          )
                        : null,
                    child: Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? activeColor : inactiveColor,
                      size: AppTheme.iconRegular,
                    ),
                  ),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          badgeCount! > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXSmall),
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXSmall,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Task badge con estado
class TaskStateBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool showGlow;

  const TaskStateBadge({
    super.key,
    required this.text,
    required this.color,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMedium,
        vertical: AppTheme.spaceXSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Info row con icono y texto
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final Color? iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    required this.isDark,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppTheme.iconSmall,
          color: iconColor ?? textColor,
        ),
        const SizedBox(width: AppTheme.spaceXSmall),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Avatar circular premium con gradiente opcional
class PremiumAvatar extends StatelessWidget {
  final String? initials;
  final IconData? icon;
  final double radius;
  final List<Color>? gradientColors;
  final Color? backgroundColor;
  final String? imageUrl;

  const PremiumAvatar({
    super.key,
    this.initials,
    this.icon,
    this.radius = 24,
    this.gradientColors,
    this.backgroundColor,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: gradientColors != null
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: backgroundColor ?? AppTheme.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (gradientColors?.first ?? AppTheme.primaryBlue)
                .withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildContent(),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (icon != null) {
      return Icon(
        icon,
        color: gradientColors != null ? Colors.white : AppTheme.primaryBlue,
        size: radius * 0.8,
      );
    }

    return Center(
      child: Text(
        initials ?? '?',
        style: TextStyle(
          color: gradientColors != null ? Colors.white : AppTheme.primaryBlue,
          fontSize: radius * 0.65,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Empty state elegante
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? action;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceHuge),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard.withOpacity(0.3) : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceRegular),
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextTertiary)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppTheme.iconXLarge,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceRegular),
          Text(
            title,
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppTheme.spaceRegular),
            action!,
          ],
        ],
      ),
    );
  }
}
