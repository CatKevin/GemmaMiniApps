import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/models.dart';

class LogicBlockRenderer extends StatelessWidget {
  final EditableComponent component;
  final List<EditableComponent> childComponents;
  final VoidCallback onExpand;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final Function(String key, dynamic value) onPropertyChanged;
  final Function(ComponentTemplate) onAddChildComponent;
  final Function(String) onRemoveChildComponent;
  final Function(int, int) onReorderChildren;

  const LogicBlockRenderer({
    super.key,
    required this.component,
    required this.childComponents,
    required this.onExpand,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    required this.onPropertyChanged,
    required this.onAddChildComponent,
    required this.onRemoveChildComponent,
    required this.onReorderChildren,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final type = component.component.type;
    
    // Get block configuration based on type
    final blockConfig = _getBlockConfig(type);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: blockConfig.borderColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: blockConfig.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: onExpand,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: blockConfig.headerColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(
                  bottom: BorderSide(
                    color: blockConfig.borderColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Drag handle
                  Icon(
                    Icons.drag_handle,
                    color: theme.onSurface.withValues(alpha: 0.3),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  
                  // Block icon and title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: blockConfig.headerColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          blockConfig.icon,
                          size: 16,
                          color: theme.onPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          blockConfig.title,
                          style: TextStyle(
                            color: theme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Condition/Expression preview
                  if (_hasCondition(type)) ...[
                    Expanded(
                      child: Text(
                        _getConditionText(),
                        style: TextStyle(
                          color: theme.onSurface,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  
                  // Action buttons
                  if (onMoveUp != null || onMoveDown != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: theme.background,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onMoveUp?.call();
                            },
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.arrow_upward,
                                size: 16,
                                color: onMoveUp != null 
                                    ? theme.onSurface.withValues(alpha: 0.6)
                                    : theme.onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            color: theme.onSurface.withValues(alpha: 0.1),
                          ),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onMoveDown?.call();
                            },
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.arrow_downward,
                                size: 16,
                                color: onMoveDown != null 
                                    ? theme.onSurface.withValues(alpha: 0.6)
                                    : theme.onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  IconButton(
                    icon: Icon(
                      component.isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: onExpand,
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.error,
                      size: 20,
                    ),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded content
          if (component.isExpanded) ...[
            // Condition editor (if applicable)
            if (_hasCondition(type))
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: TextEditingController(
                    text: component.component.properties['condition'] ?? '',
                  ),
                  onChanged: (value) => onPropertyChanged('condition', value),
                  style: TextStyle(
                    color: theme.onSurface,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: type == ComponentType.forLoop 
                        ? 'Collection to iterate'
                        : 'Condition',
                    labelStyle: TextStyle(
                      color: theme.onSurface.withValues(alpha: 0.6),
                    ),
                    hintText: type == ComponentType.forLoop
                        ? 'e.g., items, users, {{variableName}}'
                        : 'e.g., age > 18, status == "active"',
                    hintStyle: TextStyle(
                      color: theme.onSurface.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: theme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: blockConfig.borderColor,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.code,
                      color: theme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            
            // Children area
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.onBackground.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  // Child components
                  if (childComponents.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.widgets_outlined,
                            size: 32,
                            color: theme.onBackground.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No components inside this block',
                            style: TextStyle(
                              color: theme.onBackground.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add components to execute when ${_getEmptyMessage(type)}',
                            style: TextStyle(
                              color: theme.onBackground.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // TODO: Render child components here
                    // This would be handled by the parent editor
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${childComponents.length} component${childComponents.length > 1 ? 's' : ''} inside',
                        style: TextStyle(
                          color: theme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Add component button
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Show component selector for adding child
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Component'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blockConfig.borderColor,
                      side: BorderSide(color: blockConfig.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  bool _hasCondition(ComponentType type) {
    return type == ComponentType.ifBlock || 
           type == ComponentType.elseIfBlock ||
           type == ComponentType.whileLoop ||
           type == ComponentType.forLoop;
  }
  
  String _getConditionText() {
    final condition = component.component.properties['condition'] ?? '';
    if (condition.isEmpty) {
      return '<no condition set>';
    }
    return condition;
  }
  
  String _getEmptyMessage(ComponentType type) {
    switch (type) {
      case ComponentType.ifBlock:
        return 'condition is true';
      case ComponentType.elseBlock:
        return 'condition is false';
      case ComponentType.elseIfBlock:
        return 'this condition is true';
      case ComponentType.forLoop:
        return 'iterating over collection';
      case ComponentType.whileLoop:
        return 'condition remains true';
      default:
        return 'executing this block';
    }
  }
  
  _BlockConfig _getBlockConfig(ComponentType type) {
    final theme = ThemeController.to.currentThemeConfig;
    
    switch (type) {
      case ComponentType.ifBlock:
        return _BlockConfig(
          title: 'IF',
          icon: Icons.code,
          headerColor: Colors.blue,
          borderColor: Colors.blue,
          shadowColor: Colors.blue,
        );
      case ComponentType.elseBlock:
        return _BlockConfig(
          title: 'ELSE',
          icon: Icons.swap_horiz,
          headerColor: Colors.orange,
          borderColor: Colors.orange,
          shadowColor: Colors.orange,
        );
      case ComponentType.elseIfBlock:
        return _BlockConfig(
          title: 'ELSE IF',
          icon: Icons.alt_route,
          headerColor: Colors.amber,
          borderColor: Colors.amber,
          shadowColor: Colors.amber,
        );
      case ComponentType.forLoop:
        return _BlockConfig(
          title: 'FOR',
          icon: Icons.repeat,
          headerColor: Colors.purple,
          borderColor: Colors.purple,
          shadowColor: Colors.purple,
        );
      case ComponentType.whileLoop:
        return _BlockConfig(
          title: 'WHILE',
          icon: Icons.loop,
          headerColor: Colors.deepPurple,
          borderColor: Colors.deepPurple,
          shadowColor: Colors.deepPurple,
        );
      default:
        return _BlockConfig(
          title: 'BLOCK',
          icon: Icons.widgets,
          headerColor: theme.primary,
          borderColor: theme.primary,
          shadowColor: theme.primary,
        );
    }
  }
}

class _BlockConfig {
  final String title;
  final IconData icon;
  final Color headerColor;
  final Color borderColor;
  final Color shadowColor;
  
  const _BlockConfig({
    required this.title,
    required this.icon,
    required this.headerColor,
    required this.borderColor,
    required this.shadowColor,
  });
}