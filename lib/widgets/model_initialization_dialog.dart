import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../core/theme/controllers/theme_controller.dart';
import '../pages/routes.dart';

/// Premium dialog to prompt user to initialize model with advanced visual effects
class ModelInitializationDialog extends HookWidget {
  final String title;
  final String message;
  final VoidCallback? onCancel;

  const ModelInitializationDialog({
    super.key,
    this.title = 'Model Not Initialized',
    this.message =
        'You need to download or import a model first to use AI features.',
    this.onCancel,
  });

  static Future<void> show({
    String? title,
    String? message,
    VoidCallback? onCancel,
  }) async {
    await Get.dialog(
      ModelInitializationDialog(
        title: title ?? 'Model Not Initialized',
        message: message ??
            'You need to download or import a model first to use AI features.',
        onCancel: onCancel,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;

    // Animation controllers
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    final rotationController = useAnimationController(
      duration: const Duration(seconds: 8),
    );

    final pulseController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    // Animations
    final scaleAnimation = CurvedAnimation(
      parent: scaleController,
      curve: Curves.elasticOut,
    );

    final isPressed = useState(false);

    // Start animations
    useEffect(() {
      scaleController.forward();
      rotationController.repeat();
      pulseController.repeat(reverse: true);
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
              // Animated background gradient
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
                                theme.primary.withValues(alpha: 0.1),
                                theme.primary.withValues(alpha: 0.05),
                                theme.onBackground.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Floating particles for depth - wrapped with IgnorePointer
              ...List.generate(5, (index) {
                return IgnorePointer(
                  child: _FloatingOrb(
                    delay: Duration(milliseconds: index * 300),
                    duration: Duration(seconds: 4 + index),
                    color: theme.primary,
                  ),
                );
              }),

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
                        // Header with animated icon
                        Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              // Animated icon with multiple layers
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
                                    // Inner gradient circle
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
                                                .withValues(alpha: 0.2),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.download_for_offline_outlined,
                                        size: 40,
                                        color: theme.primary
                                            .withValues(alpha: 0.9),
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
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.primary.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: theme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Model Management Required',
                                      style: TextStyle(
                                        color: theme.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                  child: GestureDetector(
                                    onTapDown: (_) => isPressed.value = true,
                                    onTapUp: (_) => isPressed.value = false,
                                    onTapCancel: () => isPressed.value = false,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      transform: Matrix4.identity()
                                        ..scale(isPressed.value ? 0.95 : 1.0),
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: theme.onSurface
                                                .withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              theme.surface
                                                  .withValues(alpha: 0.5),
                                              theme.surface
                                                  .withValues(alpha: 0.3),
                                            ],
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              Get.back();
                                              onCancel?.call();
                                            },
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Center(
                                              child: Text(
                                                'CANCEL',
                                                style: TextStyle(
                                                  color: theme.onSurface
                                                      .withValues(alpha: 0.7),
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
                                const SizedBox(width: 16),
                              ],

                              // Primary action button with glow effect
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
                                              Icons.settings_outlined,
                                              color: theme.onPrimary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'MANAGE MODELS',
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating orb animation for ambient effect
class _FloatingOrb extends HookWidget {
  final Duration delay;
  final Duration duration;
  final Color color;

  const _FloatingOrb({
    required this.delay,
    required this.duration,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: duration,
    );

    final floatController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    useEffect(() {
      Future.delayed(delay, () {
        if (context.mounted) {
          controller.repeat();
          floatController.repeat(reverse: true);
        }
      });
      return null;
    }, []);

    return AnimatedBuilder(
      animation: Listenable.merge([controller, floatController]),
      builder: (context, child) {
        final value = controller.value;
        final floatValue = floatController.value;
        return Positioned(
          left: 30 + (360 * math.sin(value * 2 * math.pi)),
          top: 50 + (400 * value) % 500,
          child: Container(
            width: 8 + (floatValue * 4),
            height: 8 + (floatValue * 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.4 * (1 - value)),
                  color.withValues(alpha: 0.1 * (1 - value)),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                    alpha: 0.5 * (1 - value),
                  ),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

