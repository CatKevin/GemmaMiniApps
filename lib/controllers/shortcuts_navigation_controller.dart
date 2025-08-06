import 'package:get/get.dart';

/// Controller for managing navigation within shortcuts Stack layer
class ShortcutsNavigationController extends GetxController {
  static ShortcutsNavigationController get to => Get.find();
  
  // Current page in shortcuts layer
  final RxString currentPage = 'list'.obs; // 'list' or 'runtime'
  
  // Runtime shortcut ID
  final RxnString runtimeShortcutId = RxnString();
  
  // Navigate to runtime page
  void navigateToRuntime(String shortcutId) {
    print('DEBUG ShortcutsNavController: Navigating to runtime with ID: $shortcutId');
    runtimeShortcutId.value = shortcutId;
    currentPage.value = 'runtime';
  }
  
  // Navigate back to list
  void navigateToList() {
    print('DEBUG ShortcutsNavController: Navigating back to list, clearing runtime state');
    currentPage.value = 'list';
    runtimeShortcutId.value = null;
  }
  
  // Reset all state (for cleanup)
  void resetState() {
    print('DEBUG ShortcutsNavController: Resetting all navigation state');
    currentPage.value = 'list';
    runtimeShortcutId.value = null;
  }
  
  // Check if can go back
  bool canGoBack() {
    return currentPage.value != 'list';
  }
}