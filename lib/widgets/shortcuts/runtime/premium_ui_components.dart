import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../core/theme/models/theme_config.dart';

/// Premium UI components for enhanced runtime experience
class PremiumUIComponents {
  
  /// Create a premium title header with gradient and animation
  static Widget premiumHeader({
    required String title,
    String? subtitle,
    required ThemeConfig theme,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.surface,
            theme.surface.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: theme.onSurface.withValues(alpha: 0.05),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primary,
                        theme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: theme.onPrimary, size: 24),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.onSurface.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Create an animated option card with hover effects
  static Widget animatedOptionCard({
    required String label,
    String? description,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeConfig theme,
    IconData? leadingIcon,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isSelected ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1 - (value * 0.02),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected
                        ? [
                            theme.primary,
                            theme.primary.withValues(alpha: 0.9),
                          ]
                        : [
                            theme.surface,
                            theme.surface.withValues(alpha: 0.98),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.primary
                        : theme.onSurface.withValues(alpha: 0.08),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? theme.primary.withValues(alpha: 0.25)
                          : theme.onSurface.withValues(alpha: 0.05),
                      blurRadius: isSelected ? 24 : 12,
                      offset: Offset(0, isSelected ? 12 : 6),
                    ),
                    if (isSelected)
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.15),
                        blurRadius: 48,
                        offset: const Offset(0, 24),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.onPrimary.withValues(alpha: 0.2)
                              : theme.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          leadingIcon,
                          color: isSelected ? theme.onPrimary : theme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? theme.onPrimary
                                  : theme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: isSelected
                                    ? theme.onPrimary.withValues(alpha: 0.8)
                                    : theme.onSurface.withValues(alpha: 0.5),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isSelected ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: isSelected
                            ? theme.onPrimary
                            : theme.onSurface.withValues(alpha: 0.3),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Create a floating action button with animation
  static Widget floatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required ThemeConfig theme,
    String? tooltip,
    bool mini = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: mini ? 48 : 56,
            height: mini ? 48 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primary,
                  theme.primary.withValues(alpha: 0.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onPressed();
                },
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(
                    icon,
                    color: theme.onPrimary,
                    size: mini ? 20 : 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Create an animated step indicator
  static Widget stepIndicator({
    required int currentStep,
    required int totalSteps,
    required ThemeConfig theme,
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [
                            theme.primary,
                            theme.primary.withValues(alpha: 0.5),
                          ]
                        : [
                            theme.onSurface.withValues(alpha: 0.1),
                            theme.onSurface.withValues(alpha: 0.05),
                          ],
                  ),
                ),
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final isActive = stepIndex == currentStep;
            final isCompleted = stepIndex < currentStep;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 36 : 28,
              height: isActive ? 36 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isActive || isCompleted
                      ? [
                          theme.primary,
                          theme.primary.withValues(alpha: 0.8),
                        ]
                      : [
                          theme.surface,
                          theme.surface.withValues(alpha: 0.95),
                        ],
                ),
                border: Border.all(
                  color: isActive || isCompleted
                      ? theme.primary
                      : theme.onSurface.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        color: theme.onPrimary,
                        size: isActive ? 18 : 14,
                      )
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive || isCompleted
                              ? theme.onPrimary
                              : theme.onSurface.withValues(alpha: 0.5),
                          fontSize: isActive ? 14 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          }
        }),
      ),
    );
  }

  /// Create a glowing pulse animation widget
  static Widget pulseAnimation({
    required Widget child,
    required ThemeConfig theme,
    Duration duration = const Duration(seconds: 2),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(
                  alpha: 0.3 * math.sin(value * math.pi),
                ),
                blurRadius: 20 + (10 * math.sin(value * math.pi)),
                spreadRadius: 5 * math.sin(value * math.pi),
              ),
            ],
          ),
          child: child,
        );
      },
      onEnd: () {
        // Repeat animation
      },
    );
  }
}