import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/models.dart';

/// Component panel content without the outer container
/// Used when the panel is shown inside another container (e.g., in composite components)
class ComponentPanelContent extends HookWidget {
  final Function(ComponentTemplate) onComponentSelected;
  final String? title;
  final bool showCloseButton;
  
  const ComponentPanelContent({
    super.key,
    required this.onComponentSelected,
    this.title,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final selectedCategory = useState<ComponentCategory?>(null);
    final searchQuery = useState('');
    
    // Filter templates based on category and search
    final filteredTemplates = useMemoized(() {
      List<ComponentTemplate> templates = ComponentTemplateLibrary.templates;
      
      // Filter by category
      if (selectedCategory.value != null) {
        templates = templates.where((t) => t.category == selectedCategory.value).toList();
      }
      
      // Filter by search query
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        templates = templates.where((t) => 
          t.name.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query)
        ).toList();
      }
      
      return templates;
    }, [selectedCategory.value, searchQuery.value]);
    
    return Column(
      children: [
        // Title
        if (title != null || showCloseButton)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: theme.onBackground,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                const Spacer(),
                if (showCloseButton)
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
              ),
              ...ComponentCategory.values.map((category) {
                return _CategoryChip(
                  label: _getCategoryName(category).toUpperCase(),
                  icon: _getCategoryIcon(category),
                  isSelected: selectedCategory.value == category,
                  onTap: () => selectedCategory.value = category,
                );
              }),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Component grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredTemplates.length,
            itemBuilder: (context, index) {
              final template = filteredTemplates[index];
              return _ComponentCard(
                template: template,
                onTap: () {
                  onComponentSelected(template);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  String _getCategoryName(ComponentCategory category) {
    switch (category) {
      case ComponentCategory.input:
        return 'Input';
      case ComponentCategory.selection:
        return 'Selection';
      case ComponentCategory.display:
        return 'Display';
      case ComponentCategory.layout:
        return 'Layout';
      case ComponentCategory.logic:
        return 'Logic';
      case ComponentCategory.prompt:
        return 'Prompt';
    }
  }
  
  IconData _getCategoryIcon(ComponentCategory category) {
    switch (category) {
      case ComponentCategory.input:
        return Icons.input;
      case ComponentCategory.selection:
        return Icons.select_all;
      case ComponentCategory.display:
        return Icons.visibility;
      case ComponentCategory.layout:
        return Icons.dashboard;
      case ComponentCategory.logic:
        return Icons.schema;
      case ComponentCategory.prompt:
        return Icons.description;
    }
  }
}

class ComponentPanel extends HookWidget {
  final Function(ComponentTemplate) onComponentSelected;
  
  const ComponentPanel({
    super.key,
    required this.onComponentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final selectedCategory = useState<ComponentCategory?>(null);
    final searchQuery = useState('');
    
    // Filter templates based on category and search
    final filteredTemplates = useMemoized(() {
      List<ComponentTemplate> templates = ComponentTemplateLibrary.templates;
      
      // Filter by category
      if (selectedCategory.value != null) {
        templates = templates.where((t) => t.category == selectedCategory.value).toList();
      }
      
      // Filter by search query
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        templates = templates.where((t) => 
          t.name.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query)
        ).toList();
      }
      
      return templates;
    }, [selectedCategory.value, searchQuery.value]);
    
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
                ),
                ...ComponentCategory.values.map((category) {
                  return _CategoryChip(
                    label: _getCategoryName(category).toUpperCase(),
                    icon: _getCategoryIcon(category),
                    isSelected: selectedCategory.value == category,
                    onTap: () => selectedCategory.value = category,
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Component grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredTemplates.length,
              itemBuilder: (context, index) {
                final template = filteredTemplates[index];
                return _ComponentCard(
                  template: template,
                  onTap: () {
                    onComponentSelected(template);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  String _getCategoryName(ComponentCategory category) {
    switch (category) {
      case ComponentCategory.input:
        return 'Input';
      case ComponentCategory.selection:
        return 'Selection';
      case ComponentCategory.display:
        return 'Display';
      case ComponentCategory.layout:
        return 'Layout';
      case ComponentCategory.logic:
        return 'Logic';
      case ComponentCategory.prompt:
        return 'Prompt';
    }
  }
  
  IconData _getCategoryIcon(ComponentCategory category) {
    switch (category) {
      case ComponentCategory.input:
        return Icons.input;
      case ComponentCategory.selection:
        return Icons.select_all;
      case ComponentCategory.display:
        return Icons.visibility;
      case ComponentCategory.layout:
        return Icons.dashboard;
      case ComponentCategory.logic:
        return Icons.schema;
      case ComponentCategory.prompt:
        return Icons.description;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _CategoryChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
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

class _ComponentCard extends StatelessWidget {
  final ComponentTemplate template;
  final VoidCallback onTap;
  
  const _ComponentCard({
    required this.template,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              template.icon,
              size: 28,
              color: theme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              template.name,
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                template.description,
                style: TextStyle(
                  color: theme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}