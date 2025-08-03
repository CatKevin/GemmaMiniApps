import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/composite_component.dart';

/// Panel for selecting composite components
class CompositeComponentPanel extends HookWidget {
  final Function(CompositeComponentType type, Map<String, dynamic>? config) onComponentSelected;

  const CompositeComponentPanel({
    super.key,
    required this.onComponentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;

    final compositeTemplates = [
      _CompositeTemplate(
        type: CompositeComponentType.ifElse,
        name: 'IF-ELSE',
        description: 'Conditional branching logic',
        icon: Icons.call_split,
        color: Colors.blue,
      ),
      _CompositeTemplate(
        type: CompositeComponentType.switchCase,
        name: 'MENU LOGIC',
        description: 'Menu-driven choice branching',
        icon: Icons.menu_book,
        color: Colors.orange,
      ),
      _CompositeTemplate(
        type: CompositeComponentType.forEach,
        name: 'FOR-EACH',
        description: 'Loop through items',
        icon: Icons.repeat,
        color: Colors.green,
        isComingSoon: true,
      ),
      _CompositeTemplate(
        type: CompositeComponentType.whileLoop,
        name: 'WHILE',
        description: 'Conditional loop',
        icon: Icons.loop,
        color: Colors.purple,
        isComingSoon: true,
      ),
      _CompositeTemplate(
        type: CompositeComponentType.tryError,
        name: 'TRY-CATCH',
        description: 'Error handling',
        icon: Icons.error_outline,
        color: Colors.red,
        isComingSoon: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.widgets,
                  color: theme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Logic Components',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // Component list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: compositeTemplates.length,
              itemBuilder: (context, index) {
                final template = compositeTemplates[index];
                return _buildComponentTile(context, template, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentTile(BuildContext context, _CompositeTemplate template, dynamic theme) {
    final isDisabled = template.isComingSoon;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: template.color.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  onComponentSelected(template.type, null);
                },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: template.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    template.icon,
                    color: template.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            template.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.onBackground,
                            ),
                          ),
                          if (isDisabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.onBackground.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Coming Soon',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.onBackground.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.onBackground.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                if (!isDisabled)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: theme.onBackground.withValues(alpha: 0.3),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompositeTemplate {
  final CompositeComponentType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isComingSoon;

  _CompositeTemplate({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isComingSoon = false,
  });
}

