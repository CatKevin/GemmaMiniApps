import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../controllers/stack_navigation_controller.dart';
import '../controllers/shortcuts_navigation_controller.dart';
import '../core/theme/controllers/theme_controller.dart';
import 'chat/chat_page.dart';
import 'shortcuts/shortcuts_page.dart';
import 'shortcuts/enhanced_runtime_page.dart';
import 'mode_selection/mode_selection_overlay.dart';

/// Main container that manages Stack-based navigation
class MainContainer extends HookWidget {
  const MainContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    // Initialize Stack Navigation Controller
    final stackNavController = Get.put(StackNavigationController());
    
    // Initialize shortcuts navigation controller here to avoid recreation
    Get.put(ShortcutsNavigationController(), permanent: true);
    
    // Animation controllers - use keys to ensure stability
    final modeSelectionAnimController = useAnimationController(
      duration: const Duration(milliseconds: 300),
      initialValue: 1.0,
      keys: [stackNavController], // Add key for stability
    );
    
    final shortcutsAnimController = useAnimationController(
      duration: const Duration(milliseconds: 400),
      initialValue: 0.0,
      keys: [stackNavController], // Add key for stability
    );
    
    final chatAnimController = useAnimationController(
      duration: const Duration(milliseconds: 400),
      initialValue: 0.0,
      keys: [stackNavController], // Add key for stability
    );
    
    // Initialize animation controllers in the navigation controller
    useEffect(() {
      stackNavController.initAnimationControllers(
        modeSelection: modeSelectionAnimController,
        shortcuts: shortcutsAnimController,
        chat: chatAnimController,
      );
      return null;
    }, []);
    
    // Handle back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        
        if (stackNavController.canGoBack()) {
          HapticFeedback.lightImpact();
          stackNavController.navigateBack();
        } else {
          // Show exit confirmation dialog
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: themeController.currentThemeConfig.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 0: Chat Page (Base layer)
            Obx(() => Visibility(
              visible: stackNavController.isChatVisible.value,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: false,
              child: FadeTransition(
                opacity: chatAnimController, // Use animation controller directly
                child: const ChatPageWithStackIntegration(),
              ),
            )),
            
            // Layer 1: Shortcuts Pages
            Obx(() => Visibility(
              visible: stackNavController.isShortcutsVisible.value,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: false,
              child: FadeTransition(
                opacity: shortcutsAnimController, // Use animation controller directly
                child: const ShortcutsStackWrapper(),
              ),
            )),
            
            // Layer 2: Mode Selection Overlay
            Obx(() => Visibility(
              visible: stackNavController.isModeSelectionVisible.value,
              maintainState: true, // Changed to maintain state to avoid dispose issues
              maintainAnimation: true,
              maintainSize: false,
              child: FadeTransition(
                opacity: modeSelectionAnimController, // Use animation controller directly
                child: const ModeSelectionOverlay(),
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  void _showExitDialog(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Exit App?',
          style: TextStyle(
            color: theme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to exit?',
          style: TextStyle(
            color: theme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: Text(
              'Exit',
              style: TextStyle(color: theme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper for ChatPage with Stack integration
class ChatPageWithStackIntegration extends HookWidget {
  const ChatPageWithStackIntegration({super.key});
  
  @override
  Widget build(BuildContext context) {
    final stackNavController = StackNavigationController.to;
    
    // Check for pending prompt
    useEffect(() {
      if (stackNavController.hasPromptToSend.value) {
        // Wait a moment for the page to be ready
        Future.delayed(const Duration(milliseconds: 500), () {
          // The chat page will handle the prompt
          // We'll modify ChatPage to listen for this
        });
      }
      return null;
    }, [stackNavController.hasPromptToSend.value]);
    
    return Stack(
      children: [
        const ChatPage(),
        
        // Back to mode selection button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: Icon(
              Icons.grid_view_rounded,
              color: ThemeController.to.currentThemeConfig.onBackground,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              stackNavController.backToModeSelection();
            },
          ),
        ),
      ],
    );
  }
}

/// Wrapper for Shortcuts with Stack integration
class ShortcutsStackWrapper extends HookWidget {
  const ShortcutsStackWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    final stackNavController = StackNavigationController.to;
    
    // Get shortcuts navigation controller (initialized in MainContainer)
    final shortcutsNavController = Get.find<ShortcutsNavigationController>();
    
    return Obx(() {
      final currentPage = shortcutsNavController.currentPage.value;
      final shortcutId = shortcutsNavController.runtimeShortcutId.value;
      
      return Stack(
        children: [
          // Show either shortcuts list or runtime based on current page
          if (currentPage == 'list')
            const ShortcutsPage()
          else if (currentPage == 'runtime' && shortcutId != null)
            const EnhancedRuntimePage(),
          
          // Back to mode selection button (only on list page)
          if (currentPage == 'list')
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: ThemeController.to.currentThemeConfig.onBackground,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  stackNavController.backToModeSelection();
                },
              ),
            ),
        ],
      );
    });
  }
}