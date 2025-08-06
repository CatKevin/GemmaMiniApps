import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../controllers/chat/conversation_controller.dart';
import 'conversation_list.dart';

/// The drawer menu that contains app info and conversation list
class DrawerMenu extends HookWidget {
  final Function(String)? onConversationSelected;
  
  const DrawerMenu({
    super.key,
    this.onConversationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final conversationController = ConversationController.to;
    final searchController = useTextEditingController();
    final isSearching = useState(false);
    
    return Obx(() {
      final theme = ThemeController.to.currentThemeConfig;
      
      return Container(
        color: theme.background,
        child: SafeArea(
          child: Column(
            children: [
              // App header with glassmorphic effect
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.surface,
                      theme.surface.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // App icon with glow effect
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primary,
                            theme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.glowColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 30,
                        color: theme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // App name
                    Text(
                      'Gemma Mini Apps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        color: theme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Statistics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem(
                          icon: Icons.chat_bubble_outline,
                          value: '${conversationController.conversations.length}',
                          label: 'Chats',
                          theme: theme,
                        ),
                        const SizedBox(width: 24),
                        _buildStatItem(
                          icon: Icons.message_outlined,
                          value: _getTotalMessages(conversationController),
                          label: 'Messages',
                          theme: theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.onBackground.withValues(alpha: 0.05),
                      width: 0.5,
                    ),
                  ),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isSearching.value ? 48 : 40,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(isSearching.value ? 24 : 20),
                    border: Border.all(
                      color: theme.onBackground.withValues(alpha: 
                        isSearching.value ? 0.2 : 0.1
                      ),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(
                      color: theme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: TextStyle(
                        color: theme.onSurface.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      suffixIcon: isSearching.value ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.onSurface.withValues(alpha: 0.4),
                          size: 20,
                        ),
                        onPressed: () {
                          searchController.clear();
                          isSearching.value = false;
                          conversationController.clearSearch();
                          HapticFeedback.lightImpact();
                        },
                      ) : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      isSearching.value = value.isNotEmpty;
                      conversationController.searchConversations(value);
                    },
                  ),
                ),
              ),
              
              // Section header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      'Conversations',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: theme.onBackground.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    if (conversationController.conversations.isNotEmpty)
                      TextButton(
                        onPressed: () => _showClearAllDialog(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.error.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Conversation list
              Expanded(
                child: ConversationList(
                  onConversationSelected: onConversationSelected,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required dynamic theme,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.onBackground.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.onBackground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.onBackground.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
  
  String _getTotalMessages(ConversationController controller) {
    int total = 0;
    for (final conversation in controller.conversations) {
      total += conversation.messages.length;
    }
    return total.toString();
  }
  
  void _showClearAllDialog(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Clear All Conversations',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Text(
          'Are you sure you want to delete all conversations? This action cannot be undone.',
          style: TextStyle(color: theme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ConversationController.to.deleteAllConversations();
              HapticFeedback.mediumImpact();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}