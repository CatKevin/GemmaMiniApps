import 'package:flutter/material.dart';

/// A safe version of Opacity that ensures the opacity value is always valid
class SafeOpacity extends StatelessWidget {
  final double opacity;
  final Widget? child;
  final bool alwaysIncludeSemantics;
  
  const SafeOpacity({
    super.key,
    required this.opacity,
    this.child,
    this.alwaysIncludeSemantics = false,
  });
  
  @override
  Widget build(BuildContext context) {
    // Ensure opacity is valid
    double safeOpacity = opacity;
    
    // Check for NaN, infinity, or out of range
    if (safeOpacity.isNaN || safeOpacity.isInfinite) {
      safeOpacity = 1.0;
      debugPrint('WARNING: Invalid opacity value (NaN or Infinite) replaced with 1.0');
    } else if (safeOpacity < 0.0) {
      debugPrint('WARNING: Opacity $safeOpacity < 0.0, clamping to 0.0');
      safeOpacity = 0.0;
    } else if (safeOpacity > 1.0) {
      debugPrint('WARNING: Opacity $safeOpacity > 1.0, clamping to 1.0');
      safeOpacity = 1.0;
    }
    
    return Opacity(
      opacity: safeOpacity,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
      child: child,
    );
  }
}

/// Extension to safely convert animation values to opacity
extension SafeAnimationOpacity on Animation<double> {
  double get safeOpacityValue {
    final val = value;
    if (val.isNaN || val.isInfinite) {
      return 0.0;
    }
    return val.clamp(0.0, 1.0);
  }
}