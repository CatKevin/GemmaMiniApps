import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './safe_opacity.dart';

/// Advanced transition effects for runtime rendering
class TransitionEffects {
  /// Slide transition with fade effect
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    bool isForward = true,
    Curve curve = Curves.easeOutQuint,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: Offset(isForward ? 1.0 : -1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));
    
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));
    
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
  
  /// Slide up transition with scale
  static Widget slideUpTransition({
    required Widget child,
    required Animation<double> animation,
    Curve curve = Curves.easeOutBack,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));
    
    final scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));
    
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));
    
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      ),
    );
  }
  
  /// Staggered animation for list items
  static Widget staggeredAnimation({
    required Widget child,
    required int index,
    required AnimationController controller,
    int totalItems = 1,
    Duration delayPerItem = const Duration(milliseconds: 100),
    Curve curve = Curves.easeOutBack,
  }) {
    // Calculate animation interval for this item
    final startInterval = (index * 0.1).clamp(0.0, 0.8);
    final endInterval = (startInterval + 0.3).clamp(0.0, 1.0);
    
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        startInterval,
        endInterval,
        curve: curve,
      ),
    ));
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: SafeOpacity(
            opacity: animation.value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * animation.value),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
  
  /// Hero-like shared element transition
  static Widget sharedElementTransition({
    required Widget child,
    required String tag,
    required Animation<double> animation,
  }) {
    return Hero(
      tag: tag,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * animation.value),
            child: SafeOpacity(
              opacity: animation.value,
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
  
  /// Rotation transition with fade
  static Widget rotationTransition({
    required Widget child,
    required Animation<double> animation,
    double startRotation = -0.1,
    double endRotation = 0.0,
  }) {
    final rotationAnimation = Tween<double>(
      begin: startRotation,
      end: endRotation,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));
    
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));
    
    return FadeTransition(
      opacity: fadeAnimation,
      child: AnimatedBuilder(
        animation: rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: rotationAnimation.value,
            child: child,
          );
        },
        child: child,
      ),
    );
  }
  
  /// Bounce in animation
  static Widget bounceInAnimation({
    required Widget child,
    required Animation<double> animation,
  }) {
    final bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
    ));
    
    return ScaleTransition(
      scale: bounceAnimation,
      child: child,
    );
  }
  
  /// Page transition wrapper
  static Widget pageTransition({
    required Widget child,
    required Animation<double> animation,
    required TransitionType type,
  }) {
    switch (type) {
      case TransitionType.slide:
        return slideTransition(
          child: child,
          animation: animation,
        );
      case TransitionType.slideUp:
        return slideUpTransition(
          child: child,
          animation: animation,
        );
      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case TransitionType.scale:
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      case TransitionType.rotation:
        return rotationTransition(
          child: child,
          animation: animation,
        );
      default:
        return child;
    }
  }
  
  /// Interactive press animation
  static Widget pressAnimation({
    required Widget child,
    required VoidCallback onTap,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return _PressAnimation(
      onTap: onTap,
      duration: duration,
      child: child,
    );
  }
  
  /// Parallax scroll effect
  static Widget parallaxEffect({
    required Widget child,
    required ScrollController scrollController,
    double speed = 0.5,
  }) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        double offset = 0.0;
        if (scrollController.hasClients) {
          offset = scrollController.offset * speed;
        }
        return Transform.translate(
          offset: Offset(0, -offset),
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Reveal animation with mask
  static Widget revealAnimation({
    required Widget child,
    required Animation<double> animation,
    Alignment alignment = Alignment.center,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipPath(
          clipper: _CircularRevealClipper(
            fraction: animation.value,
            alignment: alignment,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Press animation widget
class _PressAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;
  
  const _PressAnimation({
    required this.child,
    required this.onTap,
    required this.duration,
  });
  
  @override
  State<_PressAnimation> createState() => _PressAnimationState();
}

class _PressAnimationState extends State<_PressAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }
  
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }
  
  void _handleTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Circular reveal clipper
class _CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Alignment alignment;
  
  const _CircularRevealClipper({
    required this.fraction,
    required this.alignment,
  });
  
  @override
  Path getClip(Size size) {
    final center = alignment.alongSize(size);
    final radius = fraction * size.longestSide * 1.5;
    
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
  }
  
  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.alignment != alignment;
  }
}

/// Transition types enum
enum TransitionType {
  slide,
  slideUp,
  fade,
  scale,
  rotation,
  custom,
}