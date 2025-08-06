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
        borderRadius: 20.0,
        showShadow: true,
        angle: 0.0, // No tilt for premium look
        menuBackgroundColor: theme.surface.withValues(alpha: 0.45),
        // menuBackgroundColor: theme.surface.withValues(alpha: 0.98),
        slideWidth: MediaQuery.of(context).size.width * 0.75,
        mainScreenScale: 0.15, // Subtle scale effect
        mainScreenTapClose: true,
        menuScreenTapClose: true,
        drawerShadowsBackgroundColor: Colors.white.withValues(alpha: 0.9),
        shadowLayer1Color: Colors.white.withValues(alpha: 0.25),
        shadowLayer2Color: Colors.white.withValues(alpha: 0.18),
        overlayBlur: 1.0,
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
