import 'package:flutter/material.dart';
import '../models/enums/estado_tarea.dart';
import '../config/theme_config.dart';

class TaskProgressIndicator extends StatefulWidget {
  final EstadoTarea estadoActual;
  final Color? primaryColor;
  final bool showLabels;
  final double height;

  const TaskProgressIndicator({
    super.key,
    required this.estadoActual,
    this.primaryColor,
    this.showLabels = true,
    this.height = 60,
  });

  @override
  State<TaskProgressIndicator> createState() => _TaskProgressIndicatorState();
}

class _TaskProgressIndicatorState extends State<TaskProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _getProgressValue(widget.estadoActual),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(TaskProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.estadoActual != widget.estadoActual) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: _getProgressValue(widget.estadoActual),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getProgressValue(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return 0.0;
      case EstadoTarea.asignada:
        return 0.33;
      case EstadoTarea.aceptada:
        return 0.66;
      case EstadoTarea.finalizada:
        return 1.0;
      case EstadoTarea.cancelada:
        return 0.0;
    }
  }

  String _getStageLabel(int stage) {
    switch (stage) {
      case 0:
        return 'Asignada';
      case 1:
        return 'Aceptada';
      case 2:
        return 'Finalizada';
      default:
        return '';
    }
  }

  bool _isStageActive(int stage) {
    final progress = _getProgressValue(widget.estadoActual);
    return progress >= (stage + 1) * 0.33;
  }

  bool _isStagePartial(int stage) {
    final progress = _getProgressValue(widget.estadoActual);
    final stageProgress = (stage + 1) * 0.33;
    return progress > stage * 0.33 && progress < stageProgress;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.primaryColor ?? AppTheme.primaryBlue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar with stages
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Background track
                  Positioned(
                    left: 0,
                    right: 0,
                    top: widget.showLabels ? 28 : 18,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkBorder.withOpacity(0.3)
                            : AppTheme.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Animated progress track
                  Positioned(
                    left: 0,
                    right: MediaQuery.of(context).size.width *
                        (1 - _progressAnimation.value),
                    top: widget.showLabels ? 28 : 18,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stage indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (index) {
                      final isActive = _isStageActive(index);
                      final isPartial = _isStagePartial(index);
                      final isCurrent =
                          _getProgressValue(widget.estadoActual) ==
                              (index + 1) * 0.33;

                      return Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stage indicator circle
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 500),
                              tween: Tween(
                                begin: 0.0,
                                end: isActive || isCurrent ? 1.0 : 0.0,
                              ),
                              builder: (context, value, child) {
                                return Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isActive || isPartial
                                        ? LinearGradient(
                                            colors: [
                                              primaryColor,
                                              primaryColor.withOpacity(0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isActive || isPartial
                                        ? null
                                        : isDark
                                            ? AppTheme.darkBorder
                                                .withOpacity(0.3)
                                            : AppTheme.lightBorder,
                                    border: Border.all(
                                      color: isCurrent
                                          ? primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: isActive || isCurrent
                                        ? [
                                            BoxShadow(
                                              color: primaryColor
                                                  .withOpacity(0.4 * value),
                                              blurRadius: 12 * value,
                                              spreadRadius: 2 * value,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: isActive
                                          ? Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: Colors.white,
                                              key: ValueKey('check_$index'),
                                            )
                                          : Container(
                                              key: ValueKey('empty_$index'),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Stage label
                            if (widget.showLabels) ...[
                              const SizedBox(height: 8),
                              Text(
                                _getStageLabel(index),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isActive || isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive || isCurrent
                                      ? isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary
                                      : isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),

        // Current stage info
        if (widget.showLabels) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (widget.primaryColor ?? AppTheme.primaryBlue)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (widget.primaryColor ?? AppTheme.primaryBlue)
                    .withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.primaryColor ?? AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_getProgressValue(widget.estadoActual) * 100).toInt()}% Completado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryColor ?? AppTheme.primaryBlue,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
