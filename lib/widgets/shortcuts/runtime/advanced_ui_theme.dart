import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../core/theme/models/theme_mode.dart';

/// Advanced UI theme system for runtime rendering
class AdvancedUITheme {
  /// Create glassmorphic container with blur effect
  static Widget glassmorphicContainer({
    required Widget child,
    double blur = 20,
    double opacity = 0.1,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double borderRadius = 24,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
  }) {
    final theme = ThemeController.to.currentThemeConfig;
    final isDark = ThemeController.to.themeMode == AppThemeMode.dark;
    
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark 
                      ? Colors.white.withValues(alpha: opacity)
                      : Colors.black.withValues(alpha: opacity * 0.5),
                  isDark
                      ? Colors.white.withValues(alpha: opacity * 0.5)
                      : Colors.black.withValues(alpha: opacity * 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? 
                    (isDark 
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1)),
                width: 1.5,
              ),
              boxShadow: boxShadow ?? elevatedShadow(),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
  
  /// Advanced shadow system with multiple levels
  static List<BoxShadow> elevatedShadow({int level = 2}) {
    final isDark = ThemeController.to.themeMode == AppThemeMode.dark;
    
    switch (level) {
      case 1:
        return [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ];
      case 3:
        return [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ];
      case 4:
        return [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.1),
            blurRadius: 64,
            offset: const Offset(0, 32),
          ),
        ];
      default:
        return elevatedShadow(level: 2);
    }
  }
  
  /// Create gradient button with hover effect
  static Widget gradientButton({
    required String text,
    required VoidCallback onPressed,
    EdgeInsets? padding,
    double borderRadius = 16,
    double elevation = 8,
    IconData? icon,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled || isLoading ? null : () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDisabled
                  ? [
                      theme.onSurface.withValues(alpha: 0.3),
                      theme.onSurface.withValues(alpha: 0.2),
                    ]
                  : [
                      theme.primary,
                      theme.primary.withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isDisabled ? [] : [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.3),
                blurRadius: elevation,
                offset: Offset(0, elevation / 2),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 1,
                offset: const Offset(0, -1),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.onPrimary),
                  ),
                )
              else ...[
                if (icon != null) ...[
                  Icon(icon, color: theme.onPrimary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: theme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// Create shimmer loading effect
  static Widget shimmerEffect({
    required Widget child,
    bool isLoading = true,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!isLoading) return child;
    
    return AnimatedBuilder(
      animation: _shimmerAnimation(duration),
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.white,
                Colors.white10,
                Colors.white,
              ],
              stops: [
                _shimmerAnimation(duration).value - 0.3,
                _shimmerAnimation(duration).value,
                _shimmerAnimation(duration).value + 0.3,
              ],
              transform: const GradientRotation(0.5),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
  
  /// Create animated progress indicator
  static Widget animatedProgressIndicator({
    required double progress,
    double height = 4,
    Duration animationDuration = const Duration(milliseconds: 300),
    bool showGlow = true,
  }) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return Stack(
      children: [
        // Background track
        Container(
          height: height,
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        // Progress bar
        AnimatedContainer(
          duration: animationDuration,
          height: height,
          width: double.infinity,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primary,
                    theme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: showGlow ? [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.5),
                    blurRadius: height * 2,
                    offset: const Offset(0, 0),
                  ),
                ] : null,
              ),
            ),
          ),
        ),
        // Shimmer effect
        if (showGlow && progress > 0 && progress < 1)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerAnimation(const Duration(seconds: 3)),
              builder: (context, _) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        theme.primary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: [
                        _shimmerAnimation(const Duration(seconds: 3)).value - 0.3,
                        _shimmerAnimation(const Duration(seconds: 3)).value,
                        _shimmerAnimation(const Duration(seconds: 3)).value + 0.3,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  
  /// Create floating card with hover effect
  static Widget floatingCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double borderRadius = 20,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap == null ? null : () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.primary.withValues(alpha: 0.1)
                  : theme.surface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isSelected
                    ? theme.primary
                    : theme.onSurface.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : elevatedShadow(level: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
  
  /// Create pulsing animation for emphasis
  static Widget pulsingAnimation({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation(duration),
      builder: (context, _) {
        final scale = minScale + 
            (_pulseAnimation(duration).value * (maxScale - minScale));
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }
  
  // Animation controllers cache
  static final Map<String, AnimationController> _animationControllers = {};
  
  /// Get or create shimmer animation
  static Animation<double> _shimmerAnimation(Duration duration) {
    final key = 'shimmer_${duration.inMilliseconds}';
    if (!_animationControllers.containsKey(key)) {
      // This is a simplification - in real implementation, 
      // you'd need to properly manage the lifecycle
      final controller = AnimationController(
        vsync: const _DummyTickerProvider(),
        duration: duration,
      )..repeat();
      _animationControllers[key] = controller;
    }
    return _animationControllers[key]!;
  }
  
  /// Get or create pulse animation
  static Animation<double> _pulseAnimation(Duration duration) {
    final key = 'pulse_${duration.inMilliseconds}';
    if (!_animationControllers.containsKey(key)) {
      final controller = AnimationController(
        vsync: const _DummyTickerProvider(),
        duration: duration,
      )..repeat(reverse: true);
      _animationControllers[key] = controller;
    }
    return CurvedAnimation(
      parent: _animationControllers[key]!,
      curve: Curves.easeInOut,
    );
  }
  
  /// Dispose animations when needed
  static void disposeAnimations() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
  }
}

/// Dummy ticker provider for animations
class _DummyTickerProvider extends TickerProvider {
  const _DummyTickerProvider();
  
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}