import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../models/theme_mode.dart';

class ThemeSwitcher extends HookWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.to;
    final rotationController = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    final isPressed = useState(false);

    // Initialize scale
    useEffect(() {
      scaleController.value = 1.0;
      return null;
    }, []);

    void handleTap() {
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      // Animate
      rotationController.forward(from: 0);
      scaleController.forward().then((_) {
        scaleController.reverse();
      });
      
      // Toggle theme
      controller.toggleTheme();
    }

    void handleTapDown(_) {
      isPressed.value = true;
      scaleController.reverse();
    }

    void handleTapUp(_) {
      isPressed.value = false;
      handleTap();
    }

    void handleTapCancel() {
      isPressed.value = false;
      scaleController.forward();
    }

    return GestureDetector(
      onTapDown: handleTapDown,
      onTapUp: handleTapUp,
      onTapCancel: handleTapCancel,
      child: Obx(() {
        final isDark = controller.themeMode == AppThemeMode.dark;
        final theme = controller.currentThemeConfig;
        
        return AnimatedBuilder(
          animation: Listenable.merge([rotationController, scaleController]),
          builder: (context, child) {
            return Transform.scale(
              scale: scaleController.value,
              child: Transform.rotate(
                angle: rotationController.value * 2 * 3.14159,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: theme.onBackground.withOpacity(
                        isPressed.value ? 0.4 : 0.2,
                      ),
                      width: 1,
                    ),
                    boxShadow: isPressed.value
                        ? [
                            BoxShadow(
                              color: theme.glowColor.withOpacity(0.2),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sun/Moon icon with smooth transition
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          key: ValueKey(isDark),
                          size: 20,
                          color: theme.onBackground.withOpacity(0.8),
                        ),
                      ),
                      // Rotating glow effect when pressed
                      if (isPressed.value)
                        ...List.generate(4, (index) {
                          final angle = (index * 90) * 3.14159 / 180;
                          return Transform.rotate(
                            angle: angle + rotationController.value * 3.14159,
                            child: Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.glowColor.withOpacity(0.6),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.glowColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}