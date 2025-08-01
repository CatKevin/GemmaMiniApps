import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pages/routes.dart';
import 'core/theme/controllers/theme_controller.dart';

void main() {
  // Initialize theme controller
  Get.put(ThemeController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    return Obx(() => GetMaterialApp(
      title: 'Gemma Mini Apps',
      theme: themeController.theme,
      darkTheme: themeController.theme,
      themeMode: themeController.materialThemeMode,
      // Route configuration
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      // Debug banner
      debugShowCheckedModeBanner: false,
    ));
  }
}