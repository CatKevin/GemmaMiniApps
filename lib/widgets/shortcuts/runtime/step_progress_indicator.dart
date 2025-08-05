import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Advanced step progress indicator
class StepProgressIndicator extends HookWidget {
  final int currentStep;
  final int totalSteps;
  final String? currentStepTitle;
  final VoidCallback? onStepTapped;
  final bool showStepLabels;
  final bool allowStepTapping;
  
  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.currentStepTitle,
    this.onStepTapped,
    this.showStepLabels = true,
    this.allowStepTapping = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    
    useEffect(() {
      animationController.forward();
      return null;
    }, [currentStep]);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Step text
          if (showStepLabels) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${currentStep + 1} of $totalSteps',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (currentStepTitle != null)
                  Expanded(
                    child: Text(
                      currentStepTitle!,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Background track
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Progress fill
                  AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      final progress = (currentStep + 1) / totalSteps;
                      return Container(
                        height: 4,
                        width: constraints.maxWidth * progress * animationController.value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Step dots
                  if (totalSteps <= 6) ...[
                    Positioned.fill(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(totalSteps, (index) {
                          return _StepDot(
                            index: index,
                            currentStep: currentStep,
                            isActive: index <= currentStep,
                            onTap: allowStepTapping && onStepTapped != null
                                ? () => onStepTapped!()
                                : null,
                            animationController: animationController,
                          );
                        }),
                      ),
                    ),
                  ],
                  
                  // Shimmer effect
                  AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      if (animationController.value < 1) {
                        return Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  theme.colorScheme.primary.withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                                stops: [
                                  animationController.value - 0.3,
                                  animationController.value,
                                  animationController.value + 0.3,
                                ].map((e) => e.clamp(0.0, 1.0)).toList(),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Individual step dot
class _StepDot extends StatelessWidget {
  final int index;
  final int currentStep;
  final bool isActive;
  final VoidCallback? onTap;
  final AnimationController animationController;
  
  const _StepDot({
    required this.index,
    required this.currentStep,
    required this.isActive,
    this.onTap,
    required this.animationController,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          final delay = index * 0.1;
          final dotAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animationController,
            curve: Interval(
              delay.clamp(0.0, 1.0),
              (delay + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOutBack,
            ),
          ));
          
          return Transform.scale(
            scale: 0.5 + (0.5 * dotAnimation.value),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: isCurrent ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ] : null,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: theme.colorScheme.onPrimary,
                          key: const ValueKey('check'),
                        )
                      : isCurrent
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.onPrimary,
                              ),
                              key: const ValueKey('current'),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('empty'),
                            ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Minimalist progress bar
class MinimalProgressBar extends StatelessWidget {
  final double progress;
  final Color? progressColor;
  final Color? backgroundColor;
  final double height;
  final bool showPercentage;
  
  const MinimalProgressBar({
    super.key,
    required this.progress,
    this.progressColor,
    this.backgroundColor,
    this.height = 2,
    this.showPercentage = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualProgress = progress.clamp(0.0, 1.0);
    
    return Column(
      children: [
        if (showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${(actualProgress * 100).toInt()}%',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Stack(
          children: [
            // Background
            Container(
              height: height,
              decoration: BoxDecoration(
                color: backgroundColor ?? 
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Progress
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: height,
                  width: constraints.maxWidth * actualProgress,
                  decoration: BoxDecoration(
                    color: progressColor ?? theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Circular progress indicator with percentage
class CircularStepProgress extends HookWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? child;
  
  const CircularStepProgress({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 6,
    this.progressColor,
    this.backgroundColor,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1000),
    );
    
    useEffect(() {
      animationController.forward();
      return null;
    }, [progress]);
    
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _CircularProgressPainter(
              progress: progress * animationController.value,
              strokeWidth: strokeWidth,
              progressColor: progressColor ?? theme.colorScheme.primary,
              backgroundColor: backgroundColor ?? 
                  theme.colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: child ?? Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
        child: this.child,
      ),
    );
  }
}

/// Custom painter for circular progress
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  
  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -90 * (3.14159 / 180);
    final sweepAngle = 360 * progress * (3.14159 / 180);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}