import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../controllers/chat/conversation_controller.dart';
import '../../controllers/stack_navigation_controller.dart';
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
    // Safe controller access with fallback initialization
    late final ConversationController conversationController;
    try {
      conversationController = ConversationController.to;
    } catch (e) {
      print('DEBUG: ConversationController not found in ConversationList, initializing...');
      Get.put(ConversationController());
      conversationController = ConversationController.to;
    }
    
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
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: theme.onBackground.withValues(alpha: 0.3),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Start a new conversation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.onBackground.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Premium new conversation button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      
                      // Create new conversation
                      await conversationController.createNewConversation();
                      
                      // Close the drawer to go back to main page
                      if (context.mounted) {
                        ZoomDrawer.of(context)?.close();
                      }
                      
                      // Show mode selection if available
                      final stackNavController = Get.isRegistered<StackNavigationController>() 
                          ? StackNavigationController.to 
                          : null;
                      stackNavController?.backToModeSelection();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primary,
                            theme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: theme.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'New Conversation',
                            style: TextStyle(
                              color: theme.onPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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