import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Colors for message bubbles
    final userBubbleColor = colorScheme.primary;
    final aiBubbleColor = colorScheme.surfaceVariant;
    final userTextColor = colorScheme.onPrimary;
    final aiTextColor = colorScheme.onSurfaceVariant;

    // Animation for typing indicator
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1000),
    );

    useEffect(() {
      if (isTyping) {
        animationController.repeat();
      }
      return null;
    }, [isTyping]);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Card(
          elevation: 1,
          color: isUser ? userBubbleColor : aiBubbleColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: isTyping
                ? AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final delay = index * 0.2;
                          final animation = Tween<double>(
                            begin: 0,
                            end: 1,
                          ).animate(
                            CurvedAnimation(
                              parent: animationController,
                              curve: Interval(
                                delay,
                                delay + 0.4,
                                curve: Curves.easeInOut,
                              ),
                            ),
                          );
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: FadeTransition(
                              opacity: animation,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: aiTextColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  )
                : SelectableText(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser ? userTextColor : aiTextColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}