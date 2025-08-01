import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeConfig {
  // Core colors
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color background;
  final Color onBackground;
  final Color error;
  final Color onError;

  // Extended colors for our app
  final Color inputBackground;
  final Color inputBorder;
  final Color inputBorderFocused;
  final Color inputText;
  final Color inputHint;
  final Color messageBubbleUser;
  final Color messageBubbleAI;
  final Color messageBubbleBorder;
  final Color buttonSelected;
  final Color buttonUnselected;
  final Color buttonBorder;
  final Color shadowColor;
  final Color glowColor;

  // Opacity values
  final double borderOpacity;
  final double borderOpacityFocused;
  final double hintOpacity;
  final double iconOpacity;
  final double shadowOpacity;

  const ThemeConfig({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputBorderFocused,
    required this.inputText,
    required this.inputHint,
    required this.messageBubbleUser,
    required this.messageBubbleAI,
    required this.messageBubbleBorder,
    required this.buttonSelected,
    required this.buttonUnselected,
    required this.buttonBorder,
    required this.shadowColor,
    required this.glowColor,
    this.borderOpacity = 0.2,
    this.borderOpacityFocused = 0.5,
    this.hintOpacity = 0.5,
    this.iconOpacity = 0.5,
    this.shadowOpacity = 0.1,
  });

  ThemeData toThemeData({required Brightness brightness}) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: onSecondary,
        surface: surface,
        onSurface: onSurface,
        error: error,
        onError: onError,
        outline: inputBorder,
        shadow: shadowColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w300,
          letterSpacing: 2,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.5,
          color: onBackground,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
          color: onBackground,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: onBackground,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: onBackground,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: onBackground,
          height: 1.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: inputBorderFocused,
            width: 1,
          ),
        ),
        hintStyle: TextStyle(
          color: inputHint,
          fontSize: 14,
        ),
      ),
    );
  }
}