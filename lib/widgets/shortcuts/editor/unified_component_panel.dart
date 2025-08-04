import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/models.dart';

/// Unified panel for selecting both regular and logic components
class UnifiedComponentPanel extends HookWidget {
  final Function(dynamic component) onComponentSelected;
  final bool hideLogicComponents;
  
  const UnifiedComponentPanel({
    super.key,
    required this.onComponentSelected,
    this.hideLogicComponents = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final selectedCategory = useState<_UnifiedCategory?>(null);
    final searchQuery = useState('');
    
    // Get all components (regular + logic)
    final allComponents = useMemoized(() {
      final components = <_UnifiedComponent>[];
      
      // Add regular components from ComponentTemplateLibrary
      for (final template in ComponentTemplateLibrary.templates) {
        components.add(_UnifiedComponent(
          id: template.id,
          name: template.name,
          description: template.description,
          icon: template.icon,
          category: _mapComponentCategory(template.category),
          color: _getCategoryColor(template.category),
          data: template,
          isLogic: false,
        ));
      }
      
      // Add logic components only if not hidden
      if (!hideLogicComponents) {
        components.addAll([
          _UnifiedComponent(
            id: 'if-else',
            name: 'IF-ELSE',
            description: 'Conditional branching logic',
            icon: Icons.call_split,
            category: _UnifiedCategory.logic,
            color: Colors.blue,
            data: CompositeComponentType.ifElse,
            isLogic: true,
          ),
          _UnifiedComponent(
            id: 'menu-logic',
            name: 'MENU LOGIC',
            description: 'Menu-driven choice branching',
            icon: Icons.menu_book,
            category: _UnifiedCategory.logic,
            color: Colors.orange,
            data: CompositeComponentType.switchCase,
            isLogic: true,
          ),
          _UnifiedComponent(
            id: 'for-each',
            name: 'FOR-EACH',
            description: 'Loop through items',
            icon: Icons.repeat,
            category: _UnifiedCategory.logic,
            color: Colors.green,
            data: CompositeComponentType.forEach,
            isLogic: true,
            isComingSoon: true,
          ),
          _UnifiedComponent(
            id: 'while-loop',
            name: 'WHILE',
            description: 'Conditional loop',
            icon: Icons.loop,
            category: _UnifiedCategory.logic,
            color: Colors.purple,
            data: CompositeComponentType.whileLoop,
            isLogic: true,
            isComingSoon: true,
          ),
          _UnifiedComponent(
            id: 'try-catch',
            name: 'TRY-CATCH',
            description: 'Error handling',
            icon: Icons.error_outline,
            category: _UnifiedCategory.logic,
            color: Colors.red,
            data: CompositeComponentType.tryError,
            isLogic: true,
            isComingSoon: true,
          ),
        ]);
      }
      
      return components;
    }, [hideLogicComponents]);
    
    // Filter components based on category and search
    final filteredComponents = useMemoized(() {
      var components = allComponents;
      
      // Filter by category
      if (selectedCategory.value != null) {
        components = components.where((c) => c.category == selectedCategory.value).toList();
      }
      
      // Filter by search query
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        components = components.where((c) =>
          c.name.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query)
        ).toList();
      }
      
      return components;
    }, [selectedCategory.value, searchQuery.value, allComponents]);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.onBackground.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.onBackground.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'ADD COMPONENT',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: theme.onBackground,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.onBackground,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) => searchQuery.value = value,
              style: TextStyle(color: theme.onBackground),
              decoration: InputDecoration(
                hintText: 'Search components...',
                hintStyle: TextStyle(
                  color: theme.onBackground.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.onBackground.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category tabs
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'ALL',
                  isSelected: selectedCategory.value == null,
                  onTap: () => selectedCategory.value = null,
                  theme: theme,
                ),
                ..._UnifiedCategory.values.where((category) => 
                  !(hideLogicComponents && category == _UnifiedCategory.logic)
                ).map((category) {
                  return _CategoryChip(
                    label: _getCategoryName(category).toUpperCase(),
                    icon: _getCategoryIcon(category),
                    isSelected: selectedCategory.value == category,
                    onTap: () => selectedCategory.value = category,
                    theme: theme,
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Component list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredComponents.length,
              itemBuilder: (context, index) {
                final component = filteredComponents[index];
                return _buildComponentTile(context, component, theme);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComponentTile(BuildContext context, _UnifiedComponent component, dynamic theme) {
    final isDisabled = component.isComingSoon;
    
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: component.color.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  onComponentSelected(component.data);
                  Navigator.of(context).pop();
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
                    color: component.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    component.icon,
                    color: component.color,
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
                            component.name,
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
                        component.description,
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
  
  static _UnifiedCategory _mapComponentCategory(ComponentCategory category) {
    switch (category) {
      case ComponentCategory.input:
        return _UnifiedCategory.input;
      case ComponentCategory.selection:
        return _UnifiedCategory.selection;
      case ComponentCategory.display:
        return _UnifiedCategory.display;
      case ComponentCategory.layout:
        return _UnifiedCategory.layout;
      case ComponentCategory.logic:
        return _UnifiedCategory.logic;
      case ComponentCategory.prompt:
        return _UnifiedCategory.prompt;
    }
  }
  
  static Color _getCategoryColor(ComponentCategory category) {
    switch (category) {
      case ComponentCategory.input:
        return Colors.teal;
      case ComponentCategory.selection:
        return Colors.indigo;
      case ComponentCategory.display:
        return Colors.purple;
      case ComponentCategory.layout:
        return Colors.amber;
      case ComponentCategory.logic:
        return Colors.blue;
      case ComponentCategory.prompt:
        return Colors.green;
    }
  }
  
  static String _getCategoryName(_UnifiedCategory category) {
    switch (category) {
      case _UnifiedCategory.input:
        return 'Input';
      case _UnifiedCategory.selection:
        return 'Selection';
      case _UnifiedCategory.display:
        return 'Display';
      case _UnifiedCategory.layout:
        return 'Layout';
      case _UnifiedCategory.logic:
        return 'Logic';
      case _UnifiedCategory.prompt:
        return 'Prompt';
    }
  }
  
  static IconData _getCategoryIcon(_UnifiedCategory category) {
    switch (category) {
      case _UnifiedCategory.input:
        return Icons.input;
      case _UnifiedCategory.selection:
        return Icons.select_all;
      case _UnifiedCategory.display:
        return Icons.visibility;
      case _UnifiedCategory.layout:
        return Icons.dashboard;
      case _UnifiedCategory.logic:
        return Icons.schema;
      case _UnifiedCategory.prompt:
        return Icons.description;
    }
  }
}

/// Unified category enum
enum _UnifiedCategory {
  input,
  selection,
  display,
  layout,
  logic,
  prompt,
}

/// Unified component model
class _UnifiedComponent {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final _UnifiedCategory category;
  final Color color;
  final dynamic data; // Either ComponentTemplate or CompositeComponentType
  final bool isLogic;
  final bool isComingSoon;
  
  _UnifiedComponent({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.color,
    required this.data,
    required this.isLogic,
    this.isComingSoon = false,
  });
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final dynamic theme;
  
  const _CategoryChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? theme.primary : theme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? theme.primary 
                  : theme.onSurface.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? theme.onPrimary : theme.onSurface,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.onPrimary : theme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}