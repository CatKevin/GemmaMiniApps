import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';

class MessageBubble extends HookWidget {
  final String text;
  final bool isUser;
  final bool isTyping;
  final bool isSystem;
  final bool isError;
  final List<Uint8List>? images;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isTyping = false,
    this.isSystem = false,
    this.isError = false,
    this.images,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;

    // Debug logging
    useEffect(() {
      print('DEBUG MessageBubble: text="$text", isUser=$isUser, images=${images?.length ?? 0}');
      return null;
    }, [text, isUser, images]);

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

    return Obx(() {
      final theme = themeController.currentThemeConfig;

      // System messages are centered
      if (isSystem) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.onSurface.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
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
                      color: isError
                          ? theme.error.withValues(alpha: 0.1)
                          : isUser
                              ? theme.messageBubbleUser
                              : theme.messageBubbleAI,
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
                                color: theme.glowColor
                                    .withValues(alpha: isUser ? 0.3 : 0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: theme.shadowColor
                                    .withValues(alpha: isUser ? 0.2 : 0.05),
                                blurRadius: isUser ? 5 : 10,
                                offset:
                                    isUser ? const Offset(0, 2) : Offset.zero,
                                spreadRadius: isUser ? 0 : -5,
                              ),
                            ],
                      border: !isUser
                          ? Border.all(
                              color: theme.messageBubbleBorder.withValues(alpha: 0.1),
                              width: 0.5,
                            )
                          : null,
                    ),
                    child: isTyping
                        ? _buildTypingIndicator(typingController)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (images != null && images!.isNotEmpty) ...[
                                Builder(
                                  builder: (context) {
                                    print('DEBUG MessageBubble: Building image grid with ${images!.length} images');
                                    return _buildImageGrid(images!);
                                  },
                                ),
                                if (text.isNotEmpty) const SizedBox(height: 8),
                              ],
                              if (text.isNotEmpty)
                                MarkdownBody(
                                  data: text,
                                  selectable: true,
                                  styleSheet: _buildMarkdownStyleSheet(context, theme, isError, isUser),
                                ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildTypingIndicator(AnimationController controller) {
    final theme = ThemeController.to.currentThemeConfig;
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
                color: theme.onSurface.withValues(alpha:
                  0.3 + (0.7 * _calculateDotOpacity(dotProgress)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.glowColor.withValues(alpha:
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

  Widget _buildImageGrid(List<Uint8List> images) {
    print('DEBUG MessageBubble._buildImageGrid: Building grid with ${images.length} images');
    
    if (images.isEmpty) {
      print('DEBUG MessageBubble._buildImageGrid: No images to display');
      return const SizedBox.shrink();
    }

    if (images.length == 1) {
      print('DEBUG MessageBubble._buildImageGrid: Displaying single image');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          images.first,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('ERROR MessageBubble: Failed to display single image: $error');
            return Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            );
          },
        ),
      );
    }

    print('DEBUG MessageBubble._buildImageGrid: Displaying grid of ${images.length} images');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length > 4 ? 4 : images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR MessageBubble: Failed to display image at index $index: $error');
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 30, color: Colors.grey),
                    ),
                  );
                },
              ),
              if (index == 3 && images.length > 4)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+${images.length - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a themed Markdown style sheet
  MarkdownStyleSheet _buildMarkdownStyleSheet(
    BuildContext context,
    dynamic theme,
    bool isError,
    bool isUser,
  ) {
    final baseColor = isError
        ? theme.error
        : isUser
            ? theme.onPrimary
            : theme.onSurface.withValues(alpha: 0.9);

    final headingColor = isError
        ? theme.error
        : isUser
            ? theme.onPrimary.withValues(alpha: 0.95)
            : theme.onSurface.withValues(alpha: 0.95);

    final codeBackgroundColor = isUser
        ? theme.onPrimary.withValues(alpha: 0.1)
        : theme.onSurface.withValues(alpha: 0.05);

    final codeBorderColor = isUser
        ? theme.onPrimary.withValues(alpha: 0.2)
        : theme.onSurface.withValues(alpha: 0.1);

    return MarkdownStyleSheet(
      // Text styles
      p: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: baseColor,
        height: 1.4,
        fontSize: 16,
      ),
      
      // Heading styles
      h1: Theme.of(context).textTheme.headlineLarge?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
      h2: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      h3: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      h4: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      h5: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      h6: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      
      // Strong and emphasis
      strong: TextStyle(
        color: baseColor,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      em: TextStyle(
        color: baseColor,
        fontStyle: FontStyle.italic,
        fontSize: 16,
      ),
      
      // Code styles
      code: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: baseColor,
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: codeBackgroundColor,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: codeBorderColor),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      
      // List styles
      listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: baseColor,
        height: 1.4,
      ),
      
      // Link styles
      a: TextStyle(
        color: isUser ? theme.onPrimary : theme.primary,
        decoration: TextDecoration.underline,
      ),
      
      // Blockquote styles
      blockquote: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: baseColor.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isUser ? theme.onPrimary.withValues(alpha: 0.3) : theme.primary.withValues(alpha: 0.3),
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      
      // Table styles
      tableHead: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.bold,
      ),
      tableBody: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: baseColor,
      ),
      tableBorder: TableBorder.all(
        color: codeBorderColor,
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.all(8),
      
      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: codeBorderColor,
            width: 1,
          ),
        ),
      ),
    );
  }
}
