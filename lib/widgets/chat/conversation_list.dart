import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../controllers/chat/conversation_controller.dart';
import '../../core/theme/controllers/theme_controller.dart';
import 'conversation_list_item.dart';

/// Widget that displays a list of conversations
class ConversationList extends HookWidget {
  final Function(String conversationId)? onConversationSelected;
  
  const ConversationList({
    super.key,
    this.onConversationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final conversationController = ConversationController.to;
    final scrollController = useScrollController();
    final isLoadingMore = useState(false);

    // Load more when scrolling to bottom
    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >= 
            scrollController.position.maxScrollExtent - 200) {
          if (!isLoadingMore.value && conversationController.hasMorePages.value) {
            isLoadingMore.value = true;
            conversationController.loadConversationsPage().then((_) {
              isLoadingMore.value = false;
            });
          }
        }
      }
      
      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return Obx(() {
      final theme = ThemeController.to.currentThemeConfig;
      final conversations = conversationController.conversations;
      final isLoading = conversationController.isLoading.value;
      final currentConversationId = conversationController.currentConversation.value?.id;
      
      if (isLoading && conversations.isEmpty) {
        // Initial loading state
        return Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: theme.primary,
            size: 50,
          ),
        );
      }
      
      if (conversations.isEmpty) {
        // Empty state
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: theme.onBackground.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'No conversations yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.onBackground.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a new conversation with the + button',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.onBackground.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        );
      }
      
      return RefreshIndicator(
        onRefresh: () async {
          await conversationController.loadConversationsPage(refresh: true);
        },
        color: theme.primary,
        backgroundColor: theme.surface,
        child: ListView.builder(
          controller: scrollController,
          itemCount: conversations.length + (isLoadingMore.value ? 1 : 0),
          padding: const EdgeInsets.only(top: 8),
          itemBuilder: (context, index) {
            if (index == conversations.length) {
              // Loading more indicator
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: LoadingAnimationWidget.threeRotatingDots(
                    color: theme.primary,
                    size: 30,
                  ),
                ),
              );
            }
            
            final conversation = conversations[index];
            
            return ConversationListItem(
              conversation: conversation,
              isSelected: conversation.id == currentConversationId,
              onTap: () {
                conversationController.switchConversation(conversation);
                onConversationSelected?.call(conversation.id);
              },
              onDelete: () {
                conversationController.deleteConversation(conversation.id);
              },
            );
          },
        ),
      );
    });
  }
}