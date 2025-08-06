import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../services/gemma/image_picker_service.dart';

class ChatInput extends HookWidget {
  final Function(String) onSendMessage;
  final bool enabled;
  final bool showToolbar;
  final bool isLoading;
  final Function(Uint8List)? onAddImage;
  final RxList<Uint8List>? selectedImages;
  final Function(int)? onRemoveImage;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
    this.showToolbar = false,
    this.isLoading = false,
    this.onAddImage,
    this.selectedImages,
    this.onRemoveImage,
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
      final hasImages = selectedImages?.isNotEmpty ?? false;
      if ((text.isNotEmpty || hasImages) && enabled) {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selected images preview
                  if (selectedImages != null)
                    Obx(() {
                      if (selectedImages!.isEmpty) return const SizedBox.shrink();
                      final theme = themeController.currentThemeConfig;
                      return Container(
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image count indicator with Add more button
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 16,
                                    color: theme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${selectedImages!.length} image${selectedImages!.length == 1 ? '' : 's'} selected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (selectedImages!.length < 5)
                                    GestureDetector(
                                      onTap: () async {
                                        HapticFeedback.lightImpact();
                                        final images = await ImagePickerService.showImageSourceDialog(context);
                                        if (images.isNotEmpty) {
                                          for (final image in images) {
                                            if (selectedImages!.length < 5) {
                                              onAddImage!(image);
                                            }
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add,
                                              size: 14,
                                              color: theme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Add more',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Image thumbnails with preview on tap
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: selectedImages!.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: EdgeInsets.only(right: index < selectedImages!.length - 1 ? 8 : 0),
                                    width: 80,
                                    height: 80,
                                    child: Stack(
                                      children: [
                                        // Image with tap to preview
                                        GestureDetector(
                                          onTap: () {
                                            // Show full screen preview like demo project
                                            showDialog(
                                              context: context,
                                              barrierColor: Colors.black87,
                                              builder: (context) => Dialog.fullscreen(
                                                backgroundColor: Colors.black,
                                                child: Stack(
                                                  children: [
                                                    Center(
                                                      child: InteractiveViewer(
                                                        child: Image.memory(selectedImages![index]),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: MediaQuery.of(context).padding.top + 8,
                                                      right: 16,
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 32,
                                                        ),
                                                        onPressed: () => Navigator.of(context).pop(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.memory(
                                              selectedImages![index],
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                            ),
                                          ),
                                        ),
                                        // Remove button
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              onRemoveImage?.call(index);
                                            },
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Add image button
                    if (onAddImage != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8, bottom: 1),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: enabled ? () async {
                              HapticFeedback.lightImpact();
                              // Show image source dialog like demo project
                              final images = await ImagePickerService.showImageSourceDialog(context);
                              print('DEBUG ChatInput: Received ${images.length} images from picker');
                              if (images.isNotEmpty) {
                                for (int i = 0; i < images.length; i++) {
                                  final image = images[i];
                                  print('DEBUG ChatInput: Adding image ${i + 1}/${images.length}, size: ${image.length} bytes');
                                  onAddImage!(image);
                                }
                                print('DEBUG ChatInput: All images added via onAddImage callback');
                              } else {
                                print('DEBUG ChatInput: No images to add');
                              }
                            } : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Obx(() {
                              final theme = themeController.currentThemeConfig;
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.surface.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.onSurface.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.shadowColor.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 22,
                                  color: enabled
                                      ? theme.primary
                                      : theme.onSurface.withValues(alpha: 0.3),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
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
                          if (!isEmpty.value && enabled && !isLoading) {
                            isPressed.value = true;
                            sendButtonScaleController.forward();
                          }
                        },
                        onTapUp: (_) {
                          if (!isEmpty.value && enabled && !isLoading) {
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
                                  border: isEmpty.value || !enabled || isLoading
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
                                      : isLoading
                                          ? [
                                              // Subtle shadow for loading state
                                              BoxShadow(
                                                color: theme.shadowColor.withValues(alpha: 0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                                spreadRadius: -4,
                                              ),
                                              // Soft glow effect for loading
                                              BoxShadow(
                                                color: theme.glowColor.withValues(alpha: 0.2),
                                                blurRadius: 16,
                                                spreadRadius: -6,
                                              ),
                                            ]
                                          : [
                                              // Elevation shadow for active state
                                              BoxShadow(
                                                color: theme.shadowColor.withValues(alpha: 0.2),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                                spreadRadius: -8,
                                              ),
                                              // Glow effect when pressed
                                              if (isPressed.value)
                                                BoxShadow(
                                                  color: theme.glowColor.withValues(alpha: 0.4),
                                                  blurRadius: 24,
                                                  spreadRadius: -8,
                                                ),
                                            ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
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
                                      ? LoadingAnimationWidget.staggeredDotsWave(
                                          key: const ValueKey('loading'),
                                          color: theme.onSurface,
                                          size: 20,
                                        )
                                      : Icon(
                                          Icons.arrow_upward,
                                          key: ValueKey('arrow-${isEmpty.value}'),
                                          size: 20,
                                          color: isEmpty.value || !enabled
                                              ? theme.inputHint.withValues(
                                                  alpha: theme.iconOpacity)
                                              : theme.onPrimary,
                                        ),
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
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}
