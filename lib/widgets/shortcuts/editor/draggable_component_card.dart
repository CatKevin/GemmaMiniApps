import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/models/theme_config.dart';
import '../../../models/shortcuts/models.dart';
import 'property_editor.dart';

class DraggableComponentCard extends HookWidget {
  final EditableComponent component;
  final ComponentTemplate? template;
  final int index;
  final int totalCount;
  final VoidCallback onExpand;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final Function(String key, dynamic value) onPropertyChanged;
  final List<Variable> availableVariables;
  final Function(Variable) onAddVariable;
  final ThemeConfig theme;

  const DraggableComponentCard({
    super.key,
    required this.component,
    required this.template,
    required this.index,
    required this.totalCount,
    required this.onExpand,
    required this.onDelete,
    required this.onPropertyChanged,
    required this.availableVariables,
    required this.onAddVariable,
    required this.theme,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    // Use state to track if component is being dragged
    final isDragging = useState(false);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDragging.value 
              ? theme.primary 
              : theme.onSurface.withValues(alpha: 0.1),
          width: isDragging.value ? 2 : 1,
        ),
        boxShadow: isDragging.value
            ? [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Component header with custom layout
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Leading section: Drag handle and icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle with ReorderableDragStartListener
                        ReorderableDragStartListener(
                          index: index,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.move,
                            child: GestureDetector(
                              onTapDown: (_) {
                                HapticFeedback.lightImpact();
                                isDragging.value = true;
                              },
                              onTapUp: (_) => isDragging.value = false,
                              onTapCancel: () => isDragging.value = false,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDragging.value 
                                      ? theme.primary.withValues(alpha: 0.1)
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: isDragging.value
                                      ? theme.primary
                                      : theme.onSurface.withValues(alpha: 0.3),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getComponentIcon(component.component.type),
                                color: theme.primary,
                                size: 20,
                              ),
                            ),
                            // Position indicator as a small badge
                            if (index == 0 || index == totalCount - 1)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index == 0 ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    index == 0 ? '1st' : 'Last',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getComponentTitle(component.component),
                            style: TextStyle(
                              color: theme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getComponentSubtitle(component.component),
                            style: TextStyle(
                              color: theme.onSurface.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Trailing actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Quick move buttons
                        if (onMoveUp != null || onMoveDown != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: theme.background,
                              border: Border.all(
                                color: theme.onSurface.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: onMoveUp,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Icon(
                                      Icons.arrow_upward,
                                      size: 14,
                                      color: onMoveUp != null 
                                          ? theme.onSurface.withValues(alpha: 0.6)
                                          : theme.onSurface.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 14,
                                  color: theme.onSurface.withValues(alpha: 0.1),
                                ),
                                InkWell(
                                  onTap: onMoveDown,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Icon(
                                      Icons.arrow_downward,
                                      size: 14,
                                      color: onMoveDown != null 
                                          ? theme.onSurface.withValues(alpha: 0.6)
                                          : theme.onSurface.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        
                        // Expand/collapse button
                        InkWell(
                          onTap: onExpand,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              component.isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: theme.onSurface.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        
                        // Delete button
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.delete_outline,
                              color: theme.error,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Property editor (shown when expanded)
          if (component.isExpanded && template != null)
            ComponentPropertyEditor(
              component: component.component,
              template: template!,
              onPropertyChanged: onPropertyChanged,
              availableVariables: availableVariables,
              onAddVariable: onAddVariable,
            ),
        ],
      ),
    );
  }

  IconData _getComponentIcon(ComponentType type) {
    switch (type) {
      case ComponentType.textInput:
      case ComponentType.multilineTextInput:
        return Icons.text_fields;
      case ComponentType.numberInput:
        return Icons.numbers;
      case ComponentType.singleSelect:
        return Icons.radio_button_checked;
      case ComponentType.multiSelect:
        return Icons.check_box;
      case ComponentType.conditional:
        return Icons.alt_route;
      case ComponentType.textTemplate:
        return Icons.text_snippet;
      case ComponentType.roleDefinition:
        return Icons.person;
      case ComponentType.taskDescription:
        return Icons.task_alt;
      default:
        return Icons.widgets;
    }
  }

  String _getComponentTitle(UIComponent component) {
    return component.properties['label'] ??
        component.properties['title'] ??
        component.type.toString().split('.').last;
  }

  String _getComponentSubtitle(UIComponent component) {
    if (component.variableBinding != null) {
      return 'Variable: ${component.variableBinding}';
    }
    return component.type.toString().split('.').last;
  }
}