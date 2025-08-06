import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/chat/conversation.dart';
import '../../core/theme/controllers/theme_controller.dart';

/// A single conversation item in the conversation list
class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isSelected;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = ThemeController.to.currentThemeConfig;
      
      return Dismissible(
        key: Key(conversation.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red.withValues(alpha: 0.8),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected 
                      ? theme.primary 
                      : Colors.transparent,
                  width: 3,
                ),
                bottom: BorderSide(
                  color: theme.onBackground.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Conversation icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.surface,
                    border: Border.all(
                      color: theme.onBackground.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: theme.onBackground.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Title and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: theme.onBackground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: theme.onBackground.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            conversation.getFormattedTime(),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.onBackground.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.message,
                            size: 12,
                            color: theme.onBackground.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${conversation.messages.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.onBackground.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.onBackground.withValues(alpha: 0.3),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
  
  void _showDeleteConfirmation(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Delete Conversation',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
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
              onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}