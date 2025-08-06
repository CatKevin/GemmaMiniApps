import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../controllers/stack_navigation_controller.dart';
import '../../core/theme/controllers/theme_controller.dart';

/// Mode selection overlay with two cards: Mini Apps and Chat
class ModeSelectionOverlay extends HookWidget {
  const ModeSelectionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final stackNavController = StackNavigationController.to;
    
    // Animation controllers with stable keys
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 600),
      keys: ['mode_selection_scale'], // Stable key to avoid recreation
    );
    
    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 400),
      keys: ['mode_selection_fade'], // Stable key to avoid recreation
    );
    
    // Start animations
    useEffect(() {
      fadeController.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        scaleController.forward();
      });
      return null;
    }, ['once']); // Only run once
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.background,
            theme.surface,
          ],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: FadeTransition(
          opacity: fadeController, // Use controller directly
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  ScaleTransition(
                    scale: scaleController, // Use controller directly
                    child: Text(
                      'Gemma Mini Apps',
                      style: TextStyle(
                        color: theme.onBackground,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  FadeTransition(
                    opacity: fadeController, // Use controller directly
                    child: Text(
                      'Choose your AI experience',
                      style: TextStyle(
                        color: theme.onBackground.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Mode cards
                  Row(
                    children: [
                      // Mini Apps Card
                      Expanded(
                        child: ScaleTransition(
                          scale: scaleController, // Use controller directly
                          child: _ModeCard(
                            title: 'Mini Apps',
                            subtitle: 'Workflows',
                            icon: Icons.apps_rounded,
                            gradientColors: [
                              Colors.black,
                              Colors.grey.shade800,
                            ],
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              stackNavController.showMiniApps();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Chat Card
                      Expanded(
                        child: ScaleTransition(
                          scale: scaleController, // Use controller directly
                          child: _ModeCard(
                            title: 'Chat',
                            subtitle: 'AI Assistant',
                            icon: Icons.chat_bubble_rounded,
                            gradientColors: [
                              Colors.grey.shade800,
                              Colors.grey.shade600,
                            ],
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              stackNavController.showChat();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // Info text
                  FadeTransition(
                    opacity: fadeController, // Use controller directly
                    child: Text(
                      'Powered by Gemma 3n',
                      style: TextStyle(
                        color: theme.onBackground.withValues(alpha: 0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual mode card widget
class _ModeCard extends HookWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);
    
    // Animation for press effect with stable key
    final pressController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      keys: ['press_${title}_${subtitle}'], // Unique stable key per card
    );
    
    return GestureDetector(
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
        animation: pressController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (pressController.value * 0.05),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 160,
                maxHeight: 180,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon with glow effect
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Title
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          
                          // Subtitle
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}