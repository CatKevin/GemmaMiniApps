import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import '../../widgets/message_bubble/message_bubble.dart';
import '../../widgets/chat_input/chat_input.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../controllers/stack_navigation_controller.dart';
import '../../controllers/chat/conversation_controller.dart';
import '../routes.dart';

class ChatPage extends HookWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    // Get or initialize ConversationController
    ConversationController conversationController;
    try {
      conversationController = ConversationController.to;
    } catch (e) {
      // Initialize if not found
      Get.put(ConversationController());
      conversationController = ConversationController.to;
    }
    
    // Get Stack Navigation Controller if available
    StackNavigationController? stackNavController;
    try {
      stackNavController = Get.find<StackNavigationController>();
    } catch (e) {
      // Controller not found, running in standalone mode
    }

    final scrollController = useScrollController();
    final isTyping = useState(false);
    final scrollOffset = useState(0.0);

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
    
    // Define sendMessage function before using it
    void sendMessage(String text) {
      if (text.trim().isEmpty) return;

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Add user message to conversation
      conversationController.addMessage(text, true);

      // Simulate AI response
      isTyping.value = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        HapticFeedback.lightImpact();
        isTyping.value = false;
        conversationController.addMessage(
          "Processing your request with advanced neural networks. This is a placeholder response showcasing the future of local AI processing.",
          false,
        );
      });
    }
    
    // Check for pending prompts from Stack Navigation
    useEffect(() {
      if (stackNavController != null) {
        // Store non-nullable reference
        final controller = stackNavController;
        
        // Listen to hasPromptToSend changes
        final subscription = controller.hasPromptToSend.listen((hasPrompt) {
          if (hasPrompt) {
            // Delay slightly to ensure page is ready
            Future.delayed(const Duration(milliseconds: 300), () {
              final prompt = controller.pendingPrompt.value;
              if (prompt.isNotEmpty) {
                sendMessage(prompt);
                controller.clearPendingPrompt();
              }
            });
          }
        });
        
        // Check immediately in case there's already a pending prompt
        if (controller.hasPromptToSend.value) {
          Future.delayed(const Duration(milliseconds: 300), () {
            final prompt = controller.pendingPrompt.value;
            if (prompt.isNotEmpty) {
              sendMessage(prompt);
              controller.clearPendingPrompt();
            }
          });
        }
        
        return subscription.cancel;
      }
      return null;
    }, [stackNavController]);

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
      // Listen to conversation changes
      ever(conversationController.currentConversation, (_) {
        final messages = conversationController.currentConversation.value?.messages ?? [];
        if (messages.isNotEmpty) {
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
      });
      return null;
    }, []);


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
                leading: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: theme.onBackground.withValues(alpha: 0.8),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Try to toggle ZoomDrawer if available
                    final zoomDrawer = ZoomDrawer.of(context);
                    if (zoomDrawer != null) {
                      zoomDrawer.toggle();
                    }
                  },
                ),
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
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      icon: Icon(
                        Icons.add,
                        color: theme.onBackground.withValues(alpha: 0.8),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // Create new conversation and navigate to shortcuts
                        conversationController.createNewConversation();
                        Routes.toShortcuts();
                      },
                    ),
                  ),
                ],
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.background.withValues(alpha: 0.95),
                        theme.background.withValues(alpha: 0.7),
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
              child: Obx(() {
                final messages = conversationController.currentConversation.value?.messages ?? [];
                return messages.isEmpty
                    ? Center(
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: scaleController,
                          curve: Curves.easeOutBack, // Changed from elasticOut
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
                                  color: theme.onBackground.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.glowColor.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 40,
                                color: theme.onBackground.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Begin your journey',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: theme.onBackground.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type a message to start',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: theme.onBackground.withValues(alpha: 0.5),
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
                            messages.length + (isTyping.value ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show typing indicator
                          if (isTyping.value && index == messages.length) {
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

                          final message = messages[index];
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
                      );
              }),
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
                          theme.background.withValues(alpha: 0.7),
                          theme.background.withValues(alpha: 0.95),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.05),
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
