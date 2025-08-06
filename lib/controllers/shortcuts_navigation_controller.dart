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
    runtimeShortcutId.value = shortcutId;
    currentPage.value = 'runtime';
  }
  
  // Navigate back to list
  void navigateToList() {
    currentPage.value = 'list';
    runtimeShortcutId.value = null;
  }
  
  // Check if can go back
  bool canGoBack() {
    return currentPage.value != 'list';
  }
}