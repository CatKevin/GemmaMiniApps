import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../widgets/message_bubble/message_bubble.dart';
import '../../widgets/chat_input/chat_input.dart';

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
        text: "Hello! I'm Gemma, your local AI assistant. How can I help you today?",
        isUser: false,
      ),
    ]);
    
    final scrollController = useScrollController();
    final isTyping = useState(false);

    // Scroll to bottom when new message is added
    useEffect(() {
      if (messages.value.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      return null;
    }, [messages.value.length]);

    // Handle sending message
    void sendMessage(String text) {
      if (text.trim().isEmpty) return;

      // Add user message
      messages.value = [
        ...messages.value,
        Message(text: text, isUser: true),
      ];

      // Simulate AI response (will be replaced with actual AI integration)
      isTyping.value = true;
      Future.delayed(const Duration(seconds: 1), () {
        isTyping.value = false;
        messages.value = [
          ...messages.value,
          Message(
            text: "I'm a local AI assistant. In the future, I'll process your message using the Gemma 3n model. For now, this is a placeholder response.",
            isUser: false,
          ),
        ];
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemma Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: messages.value.isEmpty
                ? Center(
                    child: Text(
                      'Start a conversation with Gemma',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.value.length + (isTyping.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show typing indicator
                      if (isTyping.value && index == messages.value.length) {
                        return const MessageBubble(
                          text: '...',
                          isUser: false,
                          isTyping: true,
                        );
                      }

                      final message = messages.value[index];
                      return MessageBubble(
                        text: message.text,
                        isUser: message.isUser,
                      );
                    },
                  ),
          ),
          // Input area
          ChatInput(
            onSendMessage: sendMessage,
            enabled: !isTyping.value,
          ),
        ],
      ),
    );
  }
}