import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Private constructor
  AppTheme._();

  // Color palette - Pure monochrome
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color deepGray = Color(0xFF121212);
  static const Color darkGray = Color(0xFF1E1E1E);
  static const Color mediumGray = Color(0xFF2C2C2C);
  static const Color gray = Color(0xFF404040);
  static const Color lightGray = Color(0xFF6C6C6C);
  static const Color paleGray = Color(0xFFB0B0B0);
  static const Color offWhite = Color(0xFFF5F5F5);

  // Semantic colors
  static const Color background = pureBlack;
  static const Color surface = deepGray;
  static const Color onBackground = pureWhite;
  static const Color onSurface = paleGray;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Curves
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutQuart;

  // Text styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    height: 1.2,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.3,
  );

  // Shadows
  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: pureWhite.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: -5,
        ),
      ];

  static List<BoxShadow> get deepShadow => [
        BoxShadow(
          color: pureBlack.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: pureBlack.withOpacity(0.2),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ];

  // Theme data
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: pureWhite,
        colorScheme: const ColorScheme.dark(
          primary: pureWhite,
          secondary: paleGray,
          surface: surface,
          background: background,
          error: pureWhite,
          onPrimary: pureBlack,
          onSecondary: pureBlack,
          onSurface: paleGray,
          onBackground: pureWhite,
          onError: pureBlack,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            color: pureWhite,
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: headline1,
          displayMedium: headline2,
          bodyLarge: bodyText1,
          bodyMedium: bodyText2,
          bodySmall: caption,
        ).apply(
          bodyColor: pureWhite,
          displayColor: pureWhite,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: pureWhite,
            foregroundColor: pureBlack,
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
              color: pureWhite.withOpacity(0.5),
              width: 1,
            ),
          ),
          hintStyle: TextStyle(
            color: lightGray,
            fontSize: 14,
          ),
        ),
        useMaterial3: true,
      );

  // Gradient definitions
  static LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          deepGray,
          pureBlack,
        ],
      );

  static LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          mediumGray,
          darkGray,
        ],
      );

  // Glass effect
  static BoxDecoration glassDecoration({
    double blur = 10,
    double opacity = 0.1,
  }) =>
      BoxDecoration(
        color: pureWhite.withOpacity(opacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pureWhite.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: glowShadow,
      );
}