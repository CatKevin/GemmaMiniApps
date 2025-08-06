import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../core/theme/controllers/theme_controller.dart';
import '../services/gemma/model_manager_service.dart';
import '../pages/routes.dart';

/// Premium dialog to prompt user to load/run a model with advanced visual effects
class ModelLoadPromptDialog extends HookWidget {
  final String title;
  final String message;
  final VoidCallback? onCancel;

  const ModelLoadPromptDialog({
    super.key,
    this.title = 'Model Not Running',
    this.message =
        'A model needs to be running to use AI features. Please select and load a model to continue.',
    this.onCancel,
  });

  static Future<void> show({
    String? title,
    String? message,
    VoidCallback? onCancel,
  }) async {
    await Get.dialog(
      ModelLoadPromptDialog(
        title: title ?? 'Model Not Running',
        message: message ??
            'A model needs to be running to use AI features. Please select and load a model to continue.',
        onCancel: onCancel,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final modelManager = ModelManagerService();

    // Animation controllers
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    final rotationController = useAnimationController(
      duration: const Duration(seconds: 10),
    );

    final pulseController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    final playIconController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    // Animations
    final scaleAnimation = CurvedAnimation(
      parent: scaleController,
      curve: Curves.elasticOut,
    );

    // Start animations
    useEffect(() {
      scaleController.forward();
      rotationController.repeat();
      pulseController.repeat(reverse: true);
      playIconController.repeat();
      return null;
    }, []);

    return ScaleTransition(
      scale: scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Stack(
            children: [
              // Animated background gradient with green theme - wrapped with IgnorePointer
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: rotationController.value * 2 * math.pi,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.primary.withValues(alpha: 0.08),
                                theme.primary.withValues(alpha: 0.04),
                                theme.primary.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Glassmorphic container
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.surface.withValues(alpha: 0.9),
                          theme.surface.withValues(alpha: 0.8),
                        ],
                      ),
                      border: Border.all(
                        color: theme.onSurface.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.05),
                          blurRadius: 50,
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with animated play icon
                        Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              // Animated play icon with multiple layers
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer pulsing ring
                                    AnimatedBuilder(
                                      animation: pulseController,
                                      builder: (context, child) {
                                        return Container(
                                          width: 100 *
                                              (1 + pulseController.value * 0.2),
                                          height: 100 *
                                              (1 + pulseController.value * 0.2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: theme.primary.withValues(
                                                alpha: 0.3 *
                                                    (1 - pulseController.value),
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // Middle rotating ring
                                    AnimatedBuilder(
                                      animation: playIconController,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: playIconController.value *
                                              math.pi *
                                              2,
                                          child: Container(
                                            width: 90,
                                            height: 90,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: SweepGradient(
                                                colors: [
                                                  theme.primary
                                                      .withValues(alpha: 0),
                                                  theme.primary
                                                      .withValues(alpha: 0.15),
                                                  theme.primary
                                                      .withValues(alpha: 0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // Inner gradient circle with play icon
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            theme.primary
                                                .withValues(alpha: 0.2),
                                            theme.primary
                                                .withValues(alpha: 0.05),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primary
                                                .withValues(alpha: 0.4),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: AnimatedBuilder(
                                        animation: pulseController,
                                        builder: (context, child) {
                                          return Icon(
                                            Icons.play_circle_outline,
                                            size: 40 +
                                                (pulseController.value * 4),
                                            color: theme.primary
                                                .withValues(alpha: 0.9),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Title with gradient text effect
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    theme.onSurface,
                                    theme.onSurface.withValues(alpha: 0.8),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  title.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: theme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Message with premium styling
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              Text(
                                message,
                                style: TextStyle(
                                  color: theme.onSurface.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  height: 1.6,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              // Status indicator with glassmorphic effect
                              if (modelManager.hasAnyModelAvailable()) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.primary.withValues(alpha: 0.03),
                                        theme.primary.withValues(alpha: 0.01),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          theme.primary.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.primary
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_circle_outline,
                                          size: 20,
                                          color: theme.primary
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Models Available',
                                              style: TextStyle(
                                                color: theme.primary
                                                    .withValues(alpha: 0.9),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Select a model to load and run',
                                              style: TextStyle(
                                                color: theme.onSurface
                                                    .withValues(alpha: 0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.onSurface.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: theme.onSurface
                                          .withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: theme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No Models Downloaded',
                                        style: TextStyle(
                                          color: theme.onSurface
                                              .withValues(alpha: 0.7),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Actions with premium buttons
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.background.withValues(alpha: 0.3),
                                theme.background.withValues(alpha: 0.5),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Cancel button with glassmorphic effect
                              if (onCancel != null) ...[
                                Expanded(
                                  child: _GlassmorphicButton(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Get.back();
                                      onCancel?.call();
                                    },
                                    label: 'CANCEL',
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],

                              // Primary action button with green theme
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      Get.back();
                                      Routes.toModelManagement();
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.primary,
                                            theme.primary.withValues(alpha: 0.8),
                                          ],
                                        ),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.play_circle_outline,
                                              color: theme.onPrimary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'SELECT MODEL',
                                              style: TextStyle(
                                                color: theme.onPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Animated wave pattern background - wrapped with IgnorePointer
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _WavePatternPainter(
                      animation: rotationController,
                      color: theme.primary.withValues(alpha: 0.02),
                    ),
                  ),
                ),
              ),

              // Floating particles effect - wrapped with IgnorePointer
              ...List.generate(3, (index) {
                return IgnorePointer(
                  child: _FloatingParticle(
                    delay: Duration(milliseconds: index * 400),
                    duration: Duration(seconds: 3 + index),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for animated wave pattern
class _WavePatternPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _WavePatternPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 30.0;
    final waveCount = 3;

    for (int i = 0; i < waveCount; i++) {
      final offsetY = size.height * (0.2 + i * 0.3);
      path.moveTo(0, offsetY);

      for (double x = 0; x <= size.width; x += 1) {
        final y = offsetY +
            math.sin((x / size.width * 4 * math.pi) +
                    (animation.value * 2 * math.pi) +
                    (i * math.pi / 2)) *
                waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
      path.reset();
    }
  }

  @override
  bool shouldRepaint(covariant _WavePatternPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Glassmorphic button for secondary actions
class _GlassmorphicButton extends HookWidget {
  final VoidCallback onTap;
  final String label;

  const _GlassmorphicButton({
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final isPressed = useState(false);

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) {
        isPressed.value = false;
        onTap();
      },
      onTapCancel: () => isPressed.value = false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(isPressed.value ? 0.95 : 1.0),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.onSurface.withValues(alpha: 0.2),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.surface.withValues(alpha: 0.5),
                theme.surface.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: theme.onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Floating particle animation for ambient effect
class _FloatingParticle extends HookWidget {
  final Duration delay;
  final Duration duration;

  const _FloatingParticle({
    required this.delay,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final controller = useAnimationController(
      duration: duration,
    );

    useEffect(() {
      Future.delayed(delay, () {
        if (context.mounted) {
          controller.repeat();
        }
      });
      return null;
    }, []);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        return Positioned(
          left: 50 + (200 * math.sin(value * 2 * math.pi)),
          top: 100 + (300 * value),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primary.withValues(
                alpha: 0.2 * (1 - value),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withValues(
                    alpha: 0.3 * (1 - value),
                  ),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
