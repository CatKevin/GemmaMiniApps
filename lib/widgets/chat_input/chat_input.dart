import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/theme/controllers/theme_controller.dart';

class ChatInput extends HookWidget {
  final Function(String) onSendMessage;
  final bool enabled;
  final bool showToolbar;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
    this.showToolbar = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    final textController = useTextEditingController();
    final focusNode = useFocusNode();
    final isEmpty = useState(true);
    final isFocused = useState(false);
    final characterCount = useState(0);
    final isPressed = useState(false);

    // Animation controllers
    final focusAnimationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    final sendButtonScaleController = useAnimationController(
      duration: const Duration(milliseconds: 150),
    );
    final breathingController = useAnimationController(
      duration: const Duration(seconds: 3),
    );
    final fadeInController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.98,
      upperBound: 1.0,
    );

    // Initial fade-in animation
    useEffect(() {
      fadeInController.forward();
      scaleController.value = 1.0;
      return null;
    }, []);

    // Breathing animation only when focused
    useEffect(() {
      if (isFocused.value) {
        breathingController.repeat(reverse: true);
        scaleController.forward();
      } else {
        breathingController.stop();
        breathingController.reset();
        scaleController.reverse();
      }
      return null;
    }, [isFocused.value]);

    // Listen to text changes
    useEffect(() {
      void listener() {
        final text = textController.text;
        isEmpty.value = text.trim().isEmpty;
        characterCount.value = text.length;
      }

      textController.addListener(listener);
      return () => textController.removeListener(listener);
    }, [textController]);

    // Listen to focus changes
    useEffect(() {
      void listener() {
        isFocused.value = focusNode.hasFocus;
        if (focusNode.hasFocus) {
          focusAnimationController.forward();
        } else {
          focusAnimationController.reverse();
        }
      }

      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    void handleSend() async {
      final text = textController.text.trim();
      if (text.isNotEmpty && enabled) {
        // Haptic feedback
        HapticFeedback.selectionClick();

        // Button animation
        await sendButtonScaleController.forward();
        sendButtonScaleController.reverse();

        // Send message
        onSendMessage(text);
        textController.clear();
        isEmpty.value = true;
        characterCount.value = 0;

        // Keep focus
        focusNode.requestFocus();
      }
    }

    return AnimatedBuilder(
      animation: fadeInController,
      builder: (context, child) {
        return Opacity(
          opacity: fadeInController.value,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Main input container
                    Expanded(
                      child: Obx(() {
                        final theme = themeController.currentThemeConfig;

                        return AnimatedBuilder(
                          animation: Listenable.merge([
                            focusAnimationController,
                            breathingController,
                            scaleController,
                          ]),
                          builder: (context, child) {
                            final breathingValue = breathingController.value;
                            final scale = scaleController.value;

                            return Transform.scale(
                                scale: scale,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 52,
                                    maxHeight: 120,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.inputBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.inputBorder.withValues(
                                        alpha: isFocused.value
                                            ? theme.borderOpacityFocused +
                                                (0.1 * breathingValue)
                                            : theme.borderOpacity,
                                      ),
                                      width: 1,
                                    ),
                                    boxShadow: isFocused.value
                                        ? [
                                            BoxShadow(
                                              color: theme.glowColor
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 24,
                                              spreadRadius: -10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Stack(
                                    children: [
                                      // Text field
                                      TextField(
                                        controller: textController,
                                        focusNode: focusNode,
                                        enabled: enabled,
                                        maxLines: 5,
                                        minLines: 1,
                                        keyboardType: TextInputType.multiline,
                                        textInputAction: TextInputAction.send,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: theme.inputText,
                                          fontWeight: FontWeight.w400,
                                          height: 1.5,
                                          letterSpacing: -0.2,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Message',
                                          hintStyle: TextStyle(
                                            fontSize: 16,
                                            color: theme.inputHint.withValues(
                                              alpha: isFocused.value
                                                  ? 0.7
                                                  : theme.hintOpacity,
                                            ),
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: -0.2,
                                          ),
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          focusedErrorBorder: InputBorder.none,
                                          filled: false,
                                          contentPadding: const EdgeInsets.only(
                                            left: 16,
                                            right: 60,
                                            top: 15,
                                            bottom: 15,
                                          ),
                                        ),
                                        onSubmitted: (_) => handleSend(),
                                      ),

                                      // Character count
                                      if (characterCount.value > 0)
                                        Positioned(
                                          right: 16,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: AnimatedOpacity(
                                              opacity:
                                                  isFocused.value ? 0.5 : 0,
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: Text(
                                                '${characterCount.value}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme.inputHint,
                                                  fontFamily: 'SF Mono',
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ));
                          },
                        );
                      }),
                    ),

                    const SizedBox(width: 12),

                    // Send button - Floating Pearl Design
                    Obx(() {
                      final theme = themeController.currentThemeConfig;

                      return GestureDetector(
                        onTapDown: (_) {
                          if (!isEmpty.value && enabled) {
                            isPressed.value = true;
                            sendButtonScaleController.forward();
                          }
                        },
                        onTapUp: (_) {
                          if (!isEmpty.value && enabled) {
                            isPressed.value = false;
                            handleSend();
                          }
                        },
                        onTapCancel: () {
                          isPressed.value = false;
                          sendButtonScaleController.reverse();
                        },
                        child: AnimatedBuilder(
                          animation: sendButtonScaleController,
                          builder: (context, child) {
                            final scale =
                                1.0 - (0.1 * sendButtonScaleController.value);

                            return Transform.scale(
                              scale: scale,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isEmpty.value || !enabled
                                      ? theme.buttonUnselected
                                      : isLoading
                                          ? theme.surface
                                          : theme.buttonSelected,
                                  border: isEmpty.value || !enabled
                                      ? Border.all(
                                          color: theme.buttonBorder.withValues(
                                              alpha: isFocused.value
                                                  ? 0.25
                                                  : theme.borderOpacity),
                                          width: 1,
                                        )
                                      : null,
                                  boxShadow: isEmpty.value || !enabled
                                      ? null
                                      : [
                                          // Elevation shadow
                                          BoxShadow(
                                            color: theme.shadowColor.withValues(
                                                alpha: isLoading ? 0.1 : 0.2),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                            spreadRadius: -8,
                                          ),
                                          // Glow effect
                                          if (isPressed.value || isLoading)
                                            BoxShadow(
                                              color: theme.glowColor
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 24,
                                              spreadRadius: -8,
                                            ),
                                        ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Loading animation
                                    if (isLoading)
                                      LoadingAnimationWidget.staggeredDotsWave(
                                        color: theme.onPrimary,
                                        size: 20,
                                      ),
                                    // Icon with fade transition
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: isLoading
                                          ? const SizedBox(
                                              key: ValueKey('loading'),
                                              width: 20,
                                              height: 20,
                                            )
                                          : Icon(
                                              Icons.arrow_upward,
                                              key: ValueKey(
                                                  'arrow-${isEmpty.value}'),
                                              size: 20,
                                              color: isEmpty.value || !enabled
                                                  ? theme.inputHint.withValues(
                                                      alpha: theme.iconOpacity)
                                                  : theme.onPrimary,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
