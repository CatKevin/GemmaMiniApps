import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat/chat_page.dart';
import 'shortcuts/shortcuts_page.dart';
import 'shortcuts/runtime_page.dart';
import 'shortcuts/editor_page.dart';

// Route name constants
abstract class Routes {
  static const String initial = '/';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String modelManagement = '/model-management';
  
  // Shortcuts routes
  static const String shortcuts = '/shortcuts';
  static const String shortcutsList = '/shortcuts/list';
  static const String shortcutsRuntime = '/shortcuts/runtime';
  static const String shortcutsEditor = '/shortcuts/editor';
  
  // Navigation helper methods
  static void toChat() => Get.toNamed(chat);
  
  static void toSettings() => Get.toNamed(settings);
  
  static void toModelManagement() => Get.toNamed(modelManagement);
  
  static void toShortcuts() => Get.toNamed(shortcuts);
  
  static void toShortcutsList() => Get.toNamed(shortcutsList);
  
  static void toShortcutsRuntime({String? shortcutId}) {
    if (shortcutId != null) {
      Get.toNamed(shortcutsRuntime, arguments: {'shortcutId': shortcutId});
    } else {
      Get.toNamed(shortcutsRuntime);
    }
  }
  
  static void toShortcutsEditor({String? shortcutId}) {
    if (shortcutId != null) {
      Get.toNamed(shortcutsEditor, arguments: {'shortcutId': shortcutId});
    } else {
      Get.toNamed(shortcutsEditor);
    }
  }
  
  // Navigation with replacement (removes current route)
  static void offToChat() => Get.offNamed(chat);
  
  static void offToShortcuts() => Get.offNamed(shortcuts);
  
  // Navigation with all previous routes removed
  static void offAllToChat() => Get.offAllNamed(chat);
  
  static void offAllToShortcuts() => Get.offAllNamed(shortcuts);
  
  // Go back
  static void back<T>({T? result}) => Get.back(result: result);
  
  // Check if can go back
  static bool canGoBack() => Navigator.canPop(Get.context!);
  
  // Show snackbar
  static void showSnackbar(String title, String message) {
    Get.snackbar(title, message);
  }
  
  // Show dialog
  static Future<T?> showDialog<T>(Widget dialog) {
    return Get.dialog<T>(dialog);
  }
}

// GetPage configurations
class AppPages {
  static const initial = Routes.chat;

  static final routes = [
    GetPage(
      name: Routes.chat,
      page: () => const ChatPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    
    // Shortcuts routes
    GetPage(
      name: Routes.shortcuts,
      page: () => const ShortcutsPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: Routes.shortcutsList,
      page: () => const ShortcutsPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: Routes.shortcutsRuntime,
      page: () => const RuntimePage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: Routes.shortcutsEditor,
      page: () => const EditorPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    
    // TODO: Add settings page
    // GetPage(
    //   name: Routes.settings,
    //   page: () => const SettingsPage(),
    //   transition: Transition.rightToLeft,
    // ),
    // TODO: Add model management page
    // GetPage(
    //   name: Routes.modelManagement,
    //   page: () => const ModelManagementPage(),
    //   transition: Transition.rightToLeft,
    // ),
  ];
}