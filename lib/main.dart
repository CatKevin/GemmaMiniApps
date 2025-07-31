import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pages/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gemma Mini Apps',
      theme: ThemeData(
        // Using blue color scheme for AI assistant theme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Route configuration
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      // Debug banner
      debugShowCheckedModeBanner: false,
    );
  }
}