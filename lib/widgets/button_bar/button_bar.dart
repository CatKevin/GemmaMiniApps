import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../selectable_button/selectable_button.dart';
import '../../core/theme/controllers/theme_controller.dart';

class ModeButtonBar extends HookWidget {
  final bool isModelSelected;
  final bool isMiniAppsSelected;
  final VoidCallback onModelToggle;
  final VoidCallback onMiniAppsToggle;
  final bool enabled;

  const ModeButtonBar({
    super.key,
    required this.isModelSelected,
    required this.isMiniAppsSelected,
    required this.onModelToggle,
    required this.onMiniAppsToggle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    // Animation controller for fade in
    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );
    
    final slideController = useAnimationController(
      duration: const Duration(milliseconds: 400),
    );

    // Initialize animations
    useEffect(() {
      fadeController.forward();
      slideController.forward();
      return null;
    }, []);

    return AnimatedBuilder(
      animation: Listenable.merge([fadeController, slideController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - slideController.value)),
          child: FadeTransition(
            opacity: fadeController,
            child: Obx(() {
              final theme = themeController.currentThemeConfig;
              
              return ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.background.withOpacity(0.6),
                          theme.background.withOpacity(0.8),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: theme.onBackground.withOpacity(0.05),
                          width: 0.5,
                        ),
                      ),
                    ),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SelectableButton(
                            icon: Icons.psychology,
                            text: 'Model',
                            isSelected: isModelSelected,
                            enabled: enabled,
                            onTap: onModelToggle,
                          ),
                          const SizedBox(width: 12),
                          SelectableButton(
                            icon: Icons.apps,
                            text: 'Mini Apps',
                            isSelected: isMiniAppsSelected,
                            enabled: enabled,
                            onTap: onMiniAppsToggle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    },
  );
  }
}