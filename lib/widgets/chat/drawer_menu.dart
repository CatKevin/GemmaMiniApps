import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../controllers/chat/conversation_controller.dart';
import '../../pages/routes.dart';
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

      return GestureDetector(
        onTap: () {
          // Unfocus search field when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Container(
          color: theme.background,
          child: SafeArea(
            child: Column(
              children: [
              // App header with glassmorphic effect - Horizontal layout
              Container(
                height: 100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.surface.withValues(alpha: 0.95),
                      theme.surface.withValues(alpha: 0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left side: Premium App Icon
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primary,
                            theme.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.3),
                            blurRadius: 25,
                            spreadRadius: -5,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: theme.glowColor.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 32,
                        color: theme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Right side: App Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App name with gradient - split into two lines
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.onBackground,
                                theme.onBackground.withValues(alpha: 0.9),
                              ],
                            ).createShader(bounds),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gemma',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                Text(
                                  'MiniApps',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Premium Search bar with glassmorphic effect
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.surface.withValues(alpha: 0.5),
                      theme.background,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.onBackground.withValues(alpha: 0.05),
                      width: 0.5,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(isSearching.value ? 14 : 12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.surface.withValues(alpha: 0.9),
                            theme.surface.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(isSearching.value ? 14 : 12),
                        border: Border.all(
                          color: isSearching.value
                              ? theme.primary.withValues(alpha: 0.3)
                              : theme.onBackground.withValues(alpha: 0.1),
                          width: isSearching.value ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSearching.value
                                ? theme.primary.withValues(alpha: 0.15)
                                : theme.shadowColor.withValues(alpha: 0.05),
                            blurRadius: isSearching.value ? 12 : 8,
                            spreadRadius: -2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search conversations',
                          hintStyle: TextStyle(
                            color: theme.onSurface.withValues(alpha: 0.35),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                          prefixIcon: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              isSearching.value
                                  ? Icons.search_rounded
                                  : Icons.search,
                              color: isSearching.value
                                  ? theme.primary
                                  : theme.onSurface.withValues(alpha: 0.4),
                              size: 20,
                            ),
                          ),
                          suffixIcon: isSearching.value
                              ? IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.onSurface
                                          .withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.clear_rounded,
                                      color: theme.onSurface
                                          .withValues(alpha: 0.5),
                                      size: 16,
                                    ),
                                  ),
                                  onPressed: () {
                                    searchController.clear();
                                    isSearching.value = false;
                                    conversationController.clearSearch();
                                    HapticFeedback.lightImpact();
                                  },
                                )
                              : null,
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
                ),
              ),

              // Section header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Row(
                  children: [
                    Text(
                      'Conversations',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
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
              
              // Bottom actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.onBackground.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Model Manager button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Routes.toModelManagement();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.onBackground.withValues(alpha: 0.1),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.storage,
                                size: 20,
                                color: theme.onBackground.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Model Manager',
                                style: TextStyle(
                                  color: theme.onBackground.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: theme.onBackground.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    });
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
