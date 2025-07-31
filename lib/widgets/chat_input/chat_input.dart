import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../utils/theme/app_theme.dart';

class ChatInput extends HookWidget {
  final Function(String) onSendMessage;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController();
    final focusNode = useFocusNode();
    final isEmpty = useState(true);
    final isFocused = useState(false);
    final characterCount = useState(0);

    // Animation controllers
    final glowController = useAnimationController(
      duration: AppTheme.mediumAnimation,
    );
    final sendButtonController = useAnimationController(
      duration: AppTheme.shortAnimation,
    );

    // Listen to text changes
    useEffect(() {
      void listener() {
        final text = textController.text.trim();
        isEmpty.value = text.isEmpty;
        characterCount.value = text.length;

        if (!isEmpty.value) {
          sendButtonController.forward();
        } else {
          sendButtonController.reverse();
        }
      }

      textController.addListener(listener);
      return () => textController.removeListener(listener);
    }, [textController]);

    // Listen to focus changes
    useEffect(() {
      void listener() {
        isFocused.value = focusNode.hasFocus;
        if (focusNode.hasFocus) {
          glowController.forward();
        } else {
          glowController.reverse();
        }
      }

      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    void handleSend() {
      final text = textController.text.trim();
      if (text.isNotEmpty && enabled) {
        HapticFeedback.lightImpact();
        onSendMessage(text);
        textController.clear();
        isEmpty.value = true;
        characterCount.value = 0;
        focusNode.requestFocus();
      }
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: AppTheme.mediumAnimation,
          curve: AppTheme.smoothCurve,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.pureBlack.withOpacity(0.7),
                AppTheme.deepGray.withOpacity(0.9),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.pureWhite.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text input field
                  Expanded(
                    child: AnimatedBuilder(
                      animation: glowController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.pureWhite.withOpacity(
                                  0.1 * glowController.value,
                                ),
                                blurRadius: 20,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: textController,
                            focusNode: focusNode,
                            enabled: enabled,
                            maxLines: null,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            style: AppTheme.bodyText1.copyWith(
                              color: AppTheme.pureWhite,
                            ),
                            decoration: InputDecoration(
                              hintText: enabled
                                  ? 'Message Gemma...'
                                  : 'Processing...',
                              hintStyle: AppTheme.bodyText2.copyWith(
                                color: AppTheme.lightGray,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: AppTheme.pureWhite.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              filled: true,
                              fillColor: AppTheme.mediumGray.withOpacity(0.5),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              suffixIcon: AnimatedOpacity(
                                opacity: isFocused.value ? 1.0 : 0.0,
                                duration: AppTheme.shortAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Text(
                                    '${characterCount.value}',
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.lightGray,
                                    ),
                                  ),
                                ),
                              ),
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 0,
                              ),
                            ),
                            onSubmitted: (_) {
                              if (!isEmpty.value) {
                                handleSend();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  AnimatedBuilder(
                    animation: sendButtonController,
                    builder: (context, child) {
                      final scale = 0.8 + (0.2 * sendButtonController.value);
                      final opacity = 0.5 + (0.5 * sendButtonController.value);

                      return Transform.scale(
                        scale: scale,
                        child: GestureDetector(
                          onTapDown: (_) {
                            if (!isEmpty.value && enabled) {
                              HapticFeedback.lightImpact();
                            }
                          },
                          onTap: isEmpty.value || !enabled ? null : handleSend,
                          child: AnimatedContainer(
                            duration: AppTheme.shortAnimation,
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isEmpty.value || !enabled
                                  ? null
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.pureWhite,
                                        AppTheme.paleGray,
                                      ],
                                    ),
                              color: isEmpty.value || !enabled
                                  ? AppTheme.mediumGray
                                  : null,
                              boxShadow: isEmpty.value || !enabled
                                  ? null
                                  : [
                                      BoxShadow(
                                        color:
                                            AppTheme.pureWhite.withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: -5,
                                      ),
                                    ],
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 24,
                              color: isEmpty.value || !enabled
                                  ? AppTheme.lightGray.withOpacity(opacity)
                                  : AppTheme.pureBlack,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
