import 'package:flutter/material.dart';
import '../models/theme_config.dart';

class DarkTheme {
  static const ThemeConfig config = ThemeConfig(
    // Core colors - Pure monochrome dark theme
    primary: Color(0xFFFFFFFF), // Pure white
    onPrimary: Color(0xFF000000), // Pure black
    secondary: Color(0xFFB0B0B0), // Pale gray
    onSecondary: Color(0xFF000000),
    surface: Color(0xFF121212), // Deep gray
    onSurface: Color(0xFFB0B0B0), // Pale gray
    background: Color(0xFF000000), // Pure black
    onBackground: Color(0xFFFFFFFF), // Pure white
    error: Color(0xFFFFFFFF),
    onError: Color(0xFF000000),
    
    // Extended colors
    inputBackground: Color(0xFF000000),
    inputBorder: Color(0xFFFFFFFF),
    inputBorderFocused: Color(0xFFFFFFFF),
    inputText: Color(0xFFFFFFFF),
    inputHint: Color(0xFF6C6C6C), // Light gray
    messageBubbleUser: Color(0xFFFFFFFF),
    messageBubbleAI: Color(0xFF1E1E1E), // Dark gray
    messageBubbleBorder: Color(0xFFFFFFFF),
    buttonSelected: Color(0xFFFFFFFF),
    buttonUnselected: Color(0xFF000000),
    buttonBorder: Color(0xFFFFFFFF),
    shadowColor: Color(0xFF000000),
    glowColor: Color(0xFFFFFFFF),
    
    // Opacity values
    borderOpacity: 0.2,
    borderOpacityFocused: 0.5,
    hintOpacity: 0.5,
    iconOpacity: 0.5,
    shadowOpacity: 0.1,
  );

  static ThemeData get themeData => config.toThemeData(brightness: Brightness.dark);
}