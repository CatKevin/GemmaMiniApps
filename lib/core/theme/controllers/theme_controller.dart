import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/theme_mode.dart';
import '../models/theme_config.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  // Observable theme mode
  final Rx<AppThemeMode> _themeMode = AppThemeMode.dark.obs;
  AppThemeMode get themeMode => _themeMode.value;

  // Theme configurations
  ThemeConfig get currentThemeConfig {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return LightTheme.config;
      case AppThemeMode.dark:
        return DarkTheme.config;
      case AppThemeMode.system:
        // For now, default to dark. In future, can check system brightness
        return DarkTheme.config;
    }
  }

  // Flutter theme data
  ThemeData get theme {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return LightTheme.themeData;
      case AppThemeMode.dark:
        return DarkTheme.themeData;
      case AppThemeMode.system:
        // For now, default to dark
        return DarkTheme.themeData;
    }
  }

  // Theme mode getter for Material App
  ThemeMode get materialThemeMode {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
    _updateSystemUI();
  }

  // Toggle between light and dark modes
  void toggleTheme() {
    if (_themeMode.value == AppThemeMode.dark) {
      setThemeMode(AppThemeMode.light);
    } else {
      setThemeMode(AppThemeMode.dark);
    }
  }

  // Set specific theme mode
  void setThemeMode(AppThemeMode mode) {
    _themeMode.value = mode;
    _saveTheme();
    _updateSystemUI();
    
    // Haptic feedback for theme change
    HapticFeedback.mediumImpact();
    
    // Force update of all widgets
    Get.forceAppUpdate();
  }

  // Update system UI overlay style based on theme
  void _updateSystemUI() {
    final isDark = _themeMode.value == AppThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  // Load saved theme from storage
  Future<void> _loadSavedTheme() async {
    // TODO: Implement with SharedPreferences
    // For now, default to dark theme
    _themeMode.value = AppThemeMode.dark;
  }

  // Save theme to storage
  Future<void> _saveTheme() async {
    // TODO: Implement with SharedPreferences
  }

  // Helper method for getting themed colors
  Color getThemedColor({
    required Color Function(ThemeConfig) colorSelector,
  }) {
    return colorSelector(currentThemeConfig);
  }
}