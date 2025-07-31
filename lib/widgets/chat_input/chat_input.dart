import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../utils/theme/app_theme.dart';

class ChatInput extends HookWidget {
  final Function(String) onSendMessage;
  final bool enabled;
  final bool showToolbar;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
    this.showToolbar = false,
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.deepGray.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: AppTheme.pureWhite.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toolbar area (future implementation)
            if (showToolbar)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildToolButton(
                      icon: Icons.image_outlined,
                      label: 'Image',
                      onTap: () {},
                    ),
                    _buildToolButton(
                      icon: Icons.attach_file_outlined,
                      label: 'File',
                      onTap: () {},
                    ),
                    _buildToolButton(
                      icon: Icons.code_outlined,
                      label: 'Code',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

            // Input area
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.pureWhite.withOpacity(
                                0.1 + (0.2 * glowController.value),
                              ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.pureWhite.withOpacity(
                                  0.05 * glowController.value,
                                ),
                                blurRadius: 10,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                                    color: AppTheme.lightGray.withOpacity(0.7),
                                  ),
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor:
                                      AppTheme.mediumGray.withOpacity(0.3),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  suffixIcon: AnimatedOpacity(
                                    opacity: isFocused.value &&
                                            characterCount.value > 0
                                        ? 1.0
                                        : 0.0,
                                    duration: AppTheme.shortAnimation,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${characterCount.value}',
                                            style: AppTheme.caption.copyWith(
                                              color: AppTheme.lightGray
                                                  .withOpacity(0.7),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
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
                            ),
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
                      final scale = 0.9 + (0.1 * sendButtonController.value);

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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: isEmpty.value || !enabled
                                  ? null
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.pureWhite,
                                        AppTheme.pureWhite.withOpacity(0.9),
                                      ],
                                    ),
                              color: isEmpty.value || !enabled
                                  ? AppTheme.mediumGray.withOpacity(0.5)
                                  : null,
                              border: isEmpty.value || !enabled
                                  ? Border.all(
                                      color:
                                          AppTheme.lightGray.withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                              boxShadow: isEmpty.value || !enabled
                                  ? null
                                  : [
                                      BoxShadow(
                                        color:
                                            AppTheme.pureWhite.withOpacity(0.2),
                                        blurRadius: 10,
                                        spreadRadius: -5,
                                      ),
                                    ],
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 20,
                              color: isEmpty.value || !enabled
                                  ? AppTheme.lightGray.withOpacity(0.5)
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
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.pureWhite.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: AppTheme.pureWhite.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.pureWhite.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
