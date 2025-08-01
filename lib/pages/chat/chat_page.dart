import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../widgets/message_bubble/message_bubble.dart';
import '../../widgets/chat_input/chat_input.dart';
import '../../widgets/button_bar/button_bar.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../core/theme/widgets/theme_switcher.dart';

// Message model
class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatPage extends HookWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    // State management using hooks
    final messages = useState<List<Message>>([
      Message(
        text:
            "Welcome to the future of AI interaction. I'm Gemma, your advanced local assistant.",
        isUser: false,
      ),
    ]);

    final scrollController = useScrollController();
    final isTyping = useState(false);
    final scrollOffset = useState(0.0);
    final isModelSelected = useState(false);
    final isMiniAppsSelected = useState(false);

    // Animation controllers
    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 400),
    );

    // Initialize animations
    useEffect(() {
      fadeController.forward();
      scaleController.forward();
      return null;
    }, []);

    // Listen to scroll position
    useEffect(() {
      void listener() {
        if (scrollController.hasClients) {
          scrollOffset.value = scrollController.offset;
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    // Scroll to bottom when new message is added
    useEffect(() {
      if (messages.value.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuart,
            );
          }
        });
      }
      return null;
    }, [messages.value.length]);

    // Handle sending message
    void sendMessage(String text) {
      if (text.trim().isEmpty) return;

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Add user message
      messages.value = [
        ...messages.value,
        Message(text: text, isUser: true),
      ];

      // Simulate AI response
      isTyping.value = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        HapticFeedback.lightImpact();
        isTyping.value = false;
        messages.value = [
          ...messages.value,
          Message(
            text:
                "Processing your request with advanced neural networks. This is a placeholder response showcasing the future of local AI processing.",
            isUser: false,
          ),
        ];
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Obx(() {
              final theme = themeController.currentThemeConfig;
              return AppBar(
                title: FadeTransition(
                  opacity: fadeController,
                  child: const Text(
                    'GEMMA',
                    style: TextStyle(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: ThemeSwitcher(),
                  ),
                ],
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.background.withOpacity(0.95),
                        theme.background.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      body: Obx(() {
        final theme = themeController.currentThemeConfig;
        return Container(
          color: theme.background,
          child: Column(
          children: [
            // Message list
            Expanded(
              child: messages.value.isEmpty
                  ? Center(
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: scaleController,
                          curve: Curves.elasticOut,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.onBackground.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.glowColor.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 40,
                                color: theme.onBackground.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Begin your journey',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: theme.onBackground.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type a message to start',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: theme.onBackground.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      itemCount:
                          messages.value.length + (isTyping.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show typing indicator
                        if (isTyping.value && index == messages.value.length) {
                          return TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 400),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: const MessageBubble(
                                  text: '...',
                                  isUser: false,
                                  isTyping: true,
                                ),
                              );
                            },
                          );
                        }

                        final message = messages.value[index];
                        return TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 400),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOutQuart,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: MessageBubble(
                                  text: message.text,
                                  isUser: message.isUser,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            // Button bar for mode selection
            ModeButtonBar(
              isModelSelected: isModelSelected.value,
              isMiniAppsSelected: isMiniAppsSelected.value,
              onModelToggle: () {
                isModelSelected.value = !isModelSelected.value;
                HapticFeedback.selectionClick();
              },
              onMiniAppsToggle: () {
                isMiniAppsSelected.value = !isMiniAppsSelected.value;
                HapticFeedback.selectionClick();
              },
              enabled: !isTyping.value,
            ),
            // Input area with glassmorphic effect
            FadeTransition(
              opacity: fadeController,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.background.withOpacity(0.7),
                          theme.background.withOpacity(0.95),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -2),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: ChatInput(
                      onSendMessage: sendMessage,
                      enabled: !isTyping.value,
                      showToolbar: false,
                      isLoading: isTyping.value,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }),
    );
  }
}
