import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../utils/theme/app_theme.dart';

class SelectableButton extends HookWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;

  const SelectableButton({
    super.key,
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Animation controllers
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    
    final glowController = useAnimationController(
      duration: const Duration(seconds: 3),
    );
    
    final selectionController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    
    final hoverController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );

    // State
    final isPressed = useState(false);
    final isHovered = useState(false);

    // Initialize animations based on selection state
    useEffect(() {
      if (isSelected) {
        selectionController.forward();
        glowController.repeat(reverse: true);
      } else {
        selectionController.reverse();
        glowController.stop();
        glowController.reset();
      }
      scaleController.value = 1.0;
      return null;
    }, [isSelected]);

    // Handle press states
    void handleTapDown(_) {
      if (!enabled) return;
      isPressed.value = true;
      scaleController.reverse();
      HapticFeedback.lightImpact();
    }

    void handleTapUp(_) {
      if (!enabled) return;
      isPressed.value = false;
      scaleController.forward();
      onTap();
    }

    void handleTapCancel() {
      isPressed.value = false;
      scaleController.forward();
    }

    return MouseRegion(
      onEnter: (_) {
        isHovered.value = true;
        hoverController.forward();
      },
      onExit: (_) {
        isHovered.value = false;
        hoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: handleTapDown,
        onTapUp: handleTapUp,
        onTapCancel: handleTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            scaleController,
            selectionController,
            glowController,
            hoverController,
          ]),
          builder: (context, child) {
            final scale = scaleController.value + 
                         (isSelected ? 0.02 * glowController.value : 0);
            final selectionProgress = selectionController.value;
            final glowIntensity = glowController.value;
            final hoverProgress = hoverController.value;

            return Transform.scale(
              scale: scale,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    AppTheme.pureBlack,
                    AppTheme.pureWhite,
                    selectionProgress,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.pureWhite.withOpacity(
                      isSelected 
                        ? 0.0 
                        : 0.2 + (0.1 * hoverProgress) + (isPressed.value ? 0.1 : 0),
                    ),
                    width: 1,
                  ),
                  boxShadow: [
                    // Base shadow
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.pureWhite.withOpacity(
                          0.2 + (0.1 * glowIntensity),
                        ),
                        blurRadius: 16 + (8 * glowIntensity),
                        spreadRadius: -8,
                      ),
                    // Pressed shadow
                    if (isPressed.value)
                      BoxShadow(
                        color: (isSelected ? AppTheme.pureWhite : AppTheme.pureWhite)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: Color.lerp(
                        AppTheme.pureWhite.withOpacity(0.5 + (0.2 * hoverProgress)),
                        AppTheme.pureBlack,
                        selectionProgress,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      text.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: Color.lerp(
                          AppTheme.pureWhite.withOpacity(0.5 + (0.2 * hoverProgress)),
                          AppTheme.pureBlack,
                          selectionProgress,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}