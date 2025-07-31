import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../widgets/message_bubble/message_bubble.dart';
import '../../widgets/chat_input/chat_input.dart';
import '../../utils/theme/app_theme.dart';

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
    // State management using hooks
    final messages = useState<List<Message>>([
      Message(
        text: "Welcome to the future of AI interaction. I'm Gemma, your advanced local assistant.",
        isUser: false,
      ),
    ]);
    
    final scrollController = useScrollController();
    final isTyping = useState(false);
    
    // Animation controllers
    final fadeController = useAnimationController(
      duration: AppTheme.longAnimation,
    );
    final scaleController = useAnimationController(
      duration: AppTheme.mediumAnimation,
    );

    // Initialize animations
    useEffect(() {
      fadeController.forward();
      scaleController.forward();
      return null;
    }, []);

    // Scroll to bottom when new message is added
    useEffect(() {
      if (messages.value.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: AppTheme.mediumAnimation,
              curve: AppTheme.smoothCurve,
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
            text: "Processing your request with advanced neural networks. This is a placeholder response showcasing the future of local AI processing.",
            isUser: false,
          ),
        ];
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.pureBlack.withOpacity(0.8),
                AppTheme.pureBlack.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            // Message list
            Expanded(
              child: messages.value.isEmpty
                  ? Center(
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: scaleController,
                          curve: AppTheme.bounceCurve,
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
                                  color: AppTheme.pureWhite.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: AppTheme.glowShadow,
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 40,
                                color: AppTheme.pureWhite.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Begin your journey',
                              style: AppTheme.headline2.copyWith(
                                color: AppTheme.pureWhite.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type a message to start',
                              style: AppTheme.bodyText2.copyWith(
                                color: AppTheme.lightGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(
                        top: 100,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      itemCount: messages.value.length + (isTyping.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show typing indicator
                        if (isTyping.value && index == messages.value.length) {
                          return TweenAnimationBuilder<double>(
                            duration: AppTheme.mediumAnimation,
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: AppTheme.smoothCurve,
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
                          duration: AppTheme.mediumAnimation,
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: AppTheme.smoothCurve,
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
            // Input area
            FadeTransition(
              opacity: fadeController,
              child: ChatInput(
                onSendMessage: sendMessage,
                enabled: !isTyping.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}