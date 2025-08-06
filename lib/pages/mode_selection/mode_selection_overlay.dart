import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../controllers/stack_navigation_controller.dart';
import '../../core/theme/controllers/theme_controller.dart';

/// Premium mode selection overlay with enhanced visual design
class ModeSelectionOverlay extends HookWidget {
  const ModeSelectionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final stackNavController = StackNavigationController.to;
    
    // Master animation controllers
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 800),
      keys: ['mode_selection_scale'],
    );
    
    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 600),
      keys: ['mode_selection_fade'],
    );
    
    final floatingController = useAnimationController(
      duration: const Duration(seconds: 3),
      keys: ['mode_selection_floating'],
    );
    
    // Animations with curves
    final scaleAnimation = CurvedAnimation(
      parent: scaleController,
      curve: Curves.elasticOut,
    );
    
    final fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeOutCubic,
    );
    
    // Start animations
    useEffect(() {
      fadeController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        scaleController.forward();
      });
      floatingController.repeat(reverse: true);
      return null;
    }, ['once']);
    
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            theme.surface,
            theme.background,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle grid pattern background
          CustomPaint(
            painter: _GridPatternPainter(
              color: theme.onBackground.withValues(alpha: 0.02),
            ),
            size: Size.infinite,
          ),
          
          // Main content with glassmorphic backdrop
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Premium title with animation
                      ScaleTransition(
                        scale: scaleAnimation,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              theme.onBackground,
                              theme.onBackground.withValues(alpha: 0.6),
                              theme.onBackground,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                          child: const Text(
                            'Gemma Mini Apps',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 2,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Elegant subtitle
                      FadeTransition(
                        opacity: fadeAnimation,
                        child: Text(
                          'Choose your AI experience',
                          style: TextStyle(
                            color: theme.onBackground.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      
                      // Premium mode cards with staggered animation
                      Row(
                        children: [
                          // Mini Apps Card
                          Expanded(
                            child: AnimatedBuilder(
                              animation: floatingController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    math.sin(floatingController.value * math.pi * 2) * 2,
                                  ),
                                  child: ScaleTransition(
                                    scale: scaleAnimation,
                                    child: _PremiumModeCard(
                                      title: 'Mini Apps',
                                      subtitle: 'Intelligent Workflows',
                                      icon: Icons.dashboard_customize,
                                      isPrimary: true,
                                      animationDelay: 0,
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        stackNavController.showMiniApps();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          
                          // Chat Card
                          Expanded(
                            child: AnimatedBuilder(
                              animation: floatingController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    -math.sin(floatingController.value * math.pi * 2) * 2,
                                  ),
                                  child: ScaleTransition(
                                    scale: scaleAnimation,
                                    child: _PremiumModeCard(
                                      title: 'Chat',
                                      subtitle: 'AI Assistant',
                                      icon: Icons.auto_awesome,
                                      isPrimary: false,
                                      animationDelay: 100,
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        stackNavController.showChat();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      
                      // Premium footer with enhanced visibility
                      FadeTransition(
                        opacity: fadeAnimation,
                        child: AnimatedBuilder(
                          animation: floatingController,
                          builder: (context, child) {
                            final glowOpacity = 0.3 + (math.sin(floatingController.value * math.pi * 2) * 0.2);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.onBackground.withValues(alpha: 0.05),
                                    theme.onBackground.withValues(alpha: 0.02),
                                  ],
                                ),
                                border: Border.all(
                                  color: theme.onBackground.withValues(alpha: glowOpacity),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primary.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: theme.primary.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        theme.onBackground.withValues(alpha: 0.9),
                                        theme.onBackground.withValues(alpha: 0.6),
                                        theme.onBackground.withValues(alpha: 0.9),
                                      ],
                                      stops: [
                                        0.0,
                                        0.5 + math.sin(floatingController.value * math.pi * 2) * 0.3,
                                        1.0,
                                      ],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'POWERED BY GEMMA 3N',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium mode card with advanced visual effects
class _PremiumModeCard extends HookWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final int animationDelay;
  final VoidCallback onTap;
  
  const _PremiumModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.animationDelay,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final isPressed = useState(false);
    final isHovered = useState(false);
    
    // Animation controllers
    final pressController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      keys: ['press_$title'],
    );
    
    final glowController = useAnimationController(
      duration: const Duration(seconds: 2),
      keys: ['glow_$title'],
    );
    
    final iconRotationController = useAnimationController(
      duration: const Duration(seconds: 10),
      keys: ['icon_rotation_$title'],
    );
    
    // Start ambient animations
    useEffect(() {
      glowController.repeat(reverse: true);
      iconRotationController.repeat();
      return null;
    }, []);
    
    return MouseRegion(
      onEnter: (_) {
        isHovered.value = true;
        HapticFeedback.lightImpact();
      },
      onExit: (_) {
        isHovered.value = false;
      },
      child: GestureDetector(
        onTapDown: (_) {
          isPressed.value = true;
          pressController.forward();
        },
        onTapUp: (_) {
          isPressed.value = false;
          pressController.reverse();
          onTap();
        },
        onTapCancel: () {
          isPressed.value = false;
          pressController.reverse();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([pressController, glowController]),
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 - (pressController.value * 0.03),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(isHovered.value ? -0.02 : 0)
                  ..rotateY(isHovered.value ? 0.02 : 0),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      // Primary shadow
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: -5,
                      ),
                      // Secondary shadow for depth
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.1),
                        blurRadius: 60,
                        offset: const Offset(0, 30),
                        spreadRadius: -10,
                      ),
                      // Glow effect
                      if (isHovered.value)
                        BoxShadow(
                          color: isPrimary
                              ? theme.primary.withValues(alpha: 0.1 + glowController.value * 0.05)
                              : theme.onBackground.withValues(alpha: 0.05 + glowController.value * 0.03),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Background gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isPrimary
                                  ? [
                                      theme.surface,
                                      theme.background,
                                    ]
                                  : [
                                      theme.background,
                                      theme.surface.withValues(alpha: 0.5),
                                    ],
                            ),
                          ),
                        ),
                        
                        // Glassmorphic layer
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.onBackground.withValues(alpha: isPrimary ? 0.08 : 0.04),
                                  theme.onBackground.withValues(alpha: isPrimary ? 0.03 : 0.01),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Noise texture overlay
                        if (isPrimary)
                          CustomPaint(
                            painter: _NoiseOverlayPainter(
                              opacity: 0.03,
                            ),
                            size: Size.infinite,
                          ),
                        
                        // Border gradient
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.onBackground.withValues(
                                alpha: isHovered.value ? 0.2 : 0.1,
                              ),
                              width: 1,
                            ),
                          ),
                        ),
                        
                        // Content
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Geometric icon container with animation
                                Center(
                                  child: AnimatedBuilder(
                                    animation: iconRotationController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: _DiamondIconPainter(
                                          color: isPrimary
                                              ? theme.primary
                                              : theme.onBackground.withValues(alpha: 0.8),
                                          glowIntensity: glowController.value,
                                          rotation: iconRotationController.value * 2 * math.pi,
                                        ),
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            icon,
                                            size: 28,
                                            color: theme.primary.withValues(alpha: 0.95),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Title with shimmer effect
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    if (!isHovered.value) {
                                      return LinearGradient(
                                        colors: [
                                          isPrimary ? theme.primary : theme.onBackground,
                                          isPrimary ? theme.primary : theme.onBackground,
                                        ],
                                      ).createShader(bounds);
                                    }
                                    return LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        isPrimary ? theme.primary : theme.onBackground,
                                        isPrimary 
                                            ? theme.primary.withValues(alpha: 0.6)
                                            : theme.onBackground.withValues(alpha: 0.6),
                                        isPrimary ? theme.primary : theme.onBackground,
                                      ],
                                      stops: [
                                        0.0,
                                        0.5 + math.sin(glowController.value * math.pi) * 0.2,
                                        1.0,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                
                                // Subtitle
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isPrimary
                                        ? theme.onSurface.withValues(alpha: 0.7)
                                        : theme.onBackground.withValues(alpha: 0.5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Ripple effect on tap
                        if (isPressed.value)
                          Positioned.fill(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: theme.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for grid pattern background
class _GridPatternPainter extends CustomPainter {
  final Color color;
  
  _GridPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    const spacing = 30.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for noise texture overlay
class _NoiseOverlayPainter extends CustomPainter {
  final double opacity;
  final random = math.Random(42);
  
  _NoiseOverlayPainter({required this.opacity});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    const dotSize = 1.0;
    const spacing = 3.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if (random.nextDouble() > 0.5) {
          paint.color = Colors.white.withValues(
            alpha: random.nextDouble() * opacity,
          );
          canvas.drawCircle(Offset(x, y), dotSize, paint);
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for diamond-shaped icon container
class _DiamondIconPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;
  final double rotation;
  
  _DiamondIconPainter({
    required this.color,
    required this.glowIntensity,
    required this.rotation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Save canvas state
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 0.1); // Slow rotation
    canvas.translate(-center.dx, -center.dy);
    
    // Create hexagon path
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + radius * 0.8 * math.cos(angle);
      final y = center.dy + radius * 0.8 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.1 + glowIntensity * 0.1)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawPath(path, glowPaint);
    
    // Draw gradient fill
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.2),
        color.withValues(alpha: 0.05),
      ],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.5 + glowIntensity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
    
    // Draw inner glow lines
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + radius * 0.8 * math.cos(angle);
      final y = center.dy + radius * 0.8 * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), innerPaint);
    }
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant _DiamondIconPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.rotation != rotation;
  }
}