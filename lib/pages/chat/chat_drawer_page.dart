import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../controllers/chat/conversation_controller.dart';
import '../../widgets/chat/drawer_menu.dart';
import 'chat_page.dart';

/// Chat page wrapped with zoom drawer for conversation management
class ChatDrawerPage extends StatelessWidget {
  ChatDrawerPage({super.key});
  
  final _drawerController = ZoomDrawerController();

  @override
  Widget build(BuildContext context) {
    // Ensure ConversationController is initialized
    if (!Get.isRegistered<ConversationController>()) {
      Get.put(ConversationController());
    }
    
    return Obx(() {
      final theme = ThemeController.to.currentThemeConfig;
      
      return ZoomDrawer(
        controller: _drawerController,
        menuScreen: DrawerMenu(
          onConversationSelected: (conversationId) {
            // Close drawer when conversation is selected
            _drawerController.close!();
          },
        ),
        mainScreen: const ChatPageWithDrawer(),
        borderRadius: 24.0,
        showShadow: true,
        angle: -12.0,
        menuBackgroundColor: theme.background,
        slideWidth: MediaQuery.of(context).size.width * 0.75,
        mainScreenScale: 0.2,
        mainScreenTapClose: true,
        menuScreenTapClose: true,
        drawerShadowsBackgroundColor: theme.shadowColor.withValues(alpha: 0.3),
        shadowLayer1Color: theme.shadowColor.withValues(alpha: 0.1),
        shadowLayer2Color: theme.shadowColor.withValues(alpha: 0.05),
      );
    });
  }
}

/// Modified ChatPage that can access the ZoomDrawer
class ChatPageWithDrawer extends StatelessWidget {
  const ChatPageWithDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap the original ChatPage and handle the drawer toggle
    return const ChatPage();
  }
}