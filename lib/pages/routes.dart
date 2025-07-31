import 'package:get/get.dart' show Get, GetNavigation, GetPage, Transition;
import 'chat/chat_page.dart';

// Route name constants
abstract class Routes {
  static const String initial = '/';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String modelManagement = '/model-management';
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