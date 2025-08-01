import 'package:flutter/material.dart';
import '../models/theme_config.dart';

class LightTheme {
  static const ThemeConfig config = ThemeConfig(
    // Core colors - Pure monochrome light theme
    primary: Color(0xFF000000), // Pure black
    onPrimary: Color(0xFFFFFFFF), // Pure white
    secondary: Color(0xFF404040), // Gray
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5), // Off white
    onSurface: Color(0xFF404040), // Gray
    background: Color(0xFFFFFFFF), // Pure white
    onBackground: Color(0xFF000000), // Pure black
    error: Color(0xFF000000),
    onError: Color(0xFFFFFFFF),
    
    // Extended colors
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFF000000),
    inputBorderFocused: Color(0xFF000000),
    inputText: Color(0xFF000000),
    inputHint: Color(0xFF6C6C6C), // Light gray
    messageBubbleUser: Color(0xFF000000),
    messageBubbleAI: Color(0xFFF5F5F5), // Off white
    messageBubbleBorder: Color(0xFF000000),
    buttonSelected: Color(0xFF000000),
    buttonUnselected: Color(0xFFFFFFFF),
    buttonBorder: Color(0xFF000000),
    shadowColor: Color(0xFF000000),
    glowColor: Color(0xFF000000),
    
    // Opacity values
    borderOpacity: 0.15,
    borderOpacityFocused: 0.4,
    hintOpacity: 0.5,
    iconOpacity: 0.5,
    shadowOpacity: 0.08,
  );

  static ThemeData get themeData => config.toThemeData(brightness: Brightness.light);
}