import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../utils/theme/app_theme.dart';

class MessageBubble extends HookWidget {
  final String text;
  final bool isUser;
  final bool isTyping;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    // Animation controller for press effect
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 100),
    );
    
    // Animation controller for typing dots
    final typingController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    // State for long press
    final isPressed = useState(false);

    useEffect(() {
      if (isTyping) {
        typingController.repeat();
      }
      return null;
    }, [isTyping]);

    void handleTapDown(_) {
      isPressed.value = true;
      scaleController.forward();
      HapticFeedback.lightImpact();
    }

    void handleTapUp(_) {
      isPressed.value = false;
      scaleController.reverse();
    }

    void handleTapCancel() {
      isPressed.value = false;
      scaleController.reverse();
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTapDown: handleTapDown,
        onTapUp: handleTapUp,
        onTapCancel: handleTapCancel,
        child: AnimatedBuilder(
          animation: scaleController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 - (scaleController.value * 0.05),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTyping ? 24 : 20,
                    vertical: isTyping ? 16 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.pureWhite
                        : AppTheme.darkGray,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser 
                          ? const Radius.circular(20) 
                          : const Radius.circular(4),
                      bottomRight: isUser 
                          ? const Radius.circular(4) 
                          : const Radius.circular(20),
                    ),
                    boxShadow: isPressed.value
                        ? [
                            BoxShadow(
                              color: isUser
                                  ? AppTheme.pureWhite.withOpacity(0.3)
                                  : AppTheme.pureWhite.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : isUser
                            ? AppTheme.subtleShadow
                            : [
                                BoxShadow(
                                  color: AppTheme.pureWhite.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: -5,
                                ),
                              ],
                    border: !isUser
                        ? Border.all(
                            color: AppTheme.pureWhite.withOpacity(0.1),
                            width: 0.5,
                          )
                        : null,
                  ),
                  child: isTyping
                      ? _buildTypingIndicator(typingController)
                      : SelectableText(
                          text,
                          style: AppTheme.bodyText1.copyWith(
                            color: isUser 
                                ? AppTheme.pureBlack 
                                : AppTheme.pureWhite.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(AnimationController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final double progress = controller.value;
            final double delay = index * 0.2;
            final double dotProgress = ((progress + delay) % 1.0);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.pureWhite.withOpacity(
                  0.3 + (0.7 * _calculateDotOpacity(dotProgress)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.pureWhite.withOpacity(
                      0.5 * _calculateDotOpacity(dotProgress),
                    ),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  double _calculateDotOpacity(double progress) {
    if (progress < 0.5) {
      return progress * 2;
    } else {
      return 2 - (progress * 2);
    }
  }
}