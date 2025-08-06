import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'shortcuts_navigation_controller.dart';

/// Controller for managing Stack-based navigation between different app modes
class StackNavigationController extends GetxController {
  static StackNavigationController get to => Get.find();
  
  // Layer visibility states
  final RxBool isModeSelectionVisible = true.obs;
  final RxBool isShortcutsVisible = false.obs;
  final RxBool isChatVisible = false.obs;
  
  // Animation controllers
  late AnimationController modeSelectionAnimationController;
  late AnimationController shortcutsAnimationController;
  late AnimationController chatAnimationController;
  
  // Prompt and images passing
  final RxString pendingPrompt = ''.obs;
  final RxList<Uint8List> pendingImages = <Uint8List>[].obs;
  final RxBool hasPromptToSend = false.obs;
  
  // Current active layer
  final Rx<AppLayer> currentLayer = AppLayer.modeSelection.obs;
  
  // Navigation history for back button
  final RxList<AppLayer> navigationHistory = <AppLayer>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // Animation controllers will be initialized by MainContainer
  }
  
  // Initialize animation controllers (called from MainContainer)
  void initAnimationControllers({
    required AnimationController modeSelection,
    required AnimationController shortcuts,
    required AnimationController chat,
  }) {
    modeSelectionAnimationController = modeSelection;
    shortcutsAnimationController = shortcuts;
    chatAnimationController = chat;
  }
  
  // Show Mini Apps (shortcuts)
  void showMiniApps() {
    // Only add to history if we're actually changing layers
    if (currentLayer.value != AppLayer.shortcuts) {
      navigationHistory.add(currentLayer.value);
    }
    
    // Always reset shortcuts navigation to list page when showing miniApps
    // This ensures we never show the runtime page when user expects the list
    try {
      final shortcutsNavController = Get.find<ShortcutsNavigationController>();
      // Force reset to list, clearing any runtime state
      shortcutsNavController.resetState();
      print('DEBUG: Force reset shortcuts to list page when showing miniApps');
    } catch (e) {
      print('DEBUG: ShortcutsNavigationController not found, skipping reset: $e');
    }
    
    // Hide mode selection with fade out if visible
    if (isModeSelectionVisible.value) {
      modeSelectionAnimationController.reverse().then((_) {
        isModeSelectionVisible.value = false;
      });
    }
    
    // Show shortcuts with fade in
    isShortcutsVisible.value = true;
    shortcutsAnimationController.forward();
    
    currentLayer.value = AppLayer.shortcuts;
  }
  
  // Show Chat directly
  void showChat() {
    navigationHistory.add(currentLayer.value);
    
    // Hide mode selection
    if (isModeSelectionVisible.value) {
      modeSelectionAnimationController.reverse().then((_) {
        isModeSelectionVisible.value = false;
      });
    }
    
    // Hide shortcuts if visible
    if (isShortcutsVisible.value) {
      shortcutsAnimationController.reverse().then((_) {
        isShortcutsVisible.value = false;
      });
    }
    
    // Show chat
    isChatVisible.value = true;
    chatAnimationController.forward();
    
    currentLayer.value = AppLayer.chat;
  }
  
  // Send prompt from shortcuts to chat with optional images
  void sendPromptToChat(String prompt, {List<Uint8List>? images}) {
    // Set the prompt and images
    pendingPrompt.value = prompt;
    if (images != null && images.isNotEmpty) {
      pendingImages.value = images;
      print('DEBUG: StackNavigationController - Setting ${images.length} pending images');
    }
    
    // Hide shortcuts with animation
    shortcutsAnimationController.reverse().then((_) {
      isShortcutsVisible.value = false;
      
      // Show chat
      isChatVisible.value = true;
      chatAnimationController.forward();
      
      currentLayer.value = AppLayer.chat;
      
      // Trigger prompt send after animation completes
      // This ensures the chat page is visible and ready
      Future.delayed(const Duration(milliseconds: 200), () {
        hasPromptToSend.value = true;
      });
    });
  }
  
  // Go back to mode selection
  void backToModeSelection() {
    navigationHistory.clear();
    
    // Always reset shortcuts state when returning to mode selection
    // This ensures clean state when user creates new conversation from any context
    try {
      final shortcutsNavController = Get.find<ShortcutsNavigationController>();
      shortcutsNavController.resetState();
      print('DEBUG: Reset shortcuts state when returning to mode selection');
    } catch (e) {
      print('DEBUG: ShortcutsNavigationController not found: $e');
    }
    
    // Hide all layers
    if (isShortcutsVisible.value) {
      shortcutsAnimationController.reverse().then((_) {
        isShortcutsVisible.value = false;
      });
    }
    
    if (isChatVisible.value) {
      chatAnimationController.reverse().then((_) {
        isChatVisible.value = false;
      });
    }
    
    // Show mode selection
    isModeSelectionVisible.value = true;
    modeSelectionAnimationController.forward();
    
    currentLayer.value = AppLayer.modeSelection;
  }
  
  // Navigate back in history
  void navigateBack() {
    if (navigationHistory.isEmpty) {
      backToModeSelection();
      return;
    }
    
    final previousLayer = navigationHistory.removeLast();
    
    switch (previousLayer) {
      case AppLayer.modeSelection:
        backToModeSelection();
        break;
      case AppLayer.shortcuts:
        // If coming from chat back to shortcuts
        if (isChatVisible.value) {
          chatAnimationController.reverse().then((_) {
            isChatVisible.value = false;
            isShortcutsVisible.value = true;
            shortcutsAnimationController.forward();
          });
        }
        currentLayer.value = AppLayer.shortcuts;
        break;
      case AppLayer.chat:
        showChat();
        break;
    }
  }
  
  // Check if can go back
  bool canGoBack() {
    return currentLayer.value != AppLayer.modeSelection;
  }
  
  // Clear pending prompt and images after they've been sent
  void clearPendingPrompt() {
    pendingPrompt.value = '';
    pendingImages.clear();
    hasPromptToSend.value = false;
    print('DEBUG: StackNavigationController - Cleared pending prompt and images');
  }
  
  // Reset to initial state
  void reset() {
    navigationHistory.clear();
    pendingPrompt.value = '';
    pendingImages.clear();
    hasPromptToSend.value = false;
    backToModeSelection();
  }
  
  @override
  void onClose() {
    // Animation controllers are disposed by MainContainer
    super.onClose();
  }
}

// Enum for app layers
enum AppLayer {
  modeSelection,
  shortcuts,
  chat,
}