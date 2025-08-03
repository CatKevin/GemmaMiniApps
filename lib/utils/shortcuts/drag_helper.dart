import 'package:flutter/material.dart';
import '../../models/shortcuts/editor_models.dart';
import '../../models/shortcuts/composite_component.dart';
import '../../models/shortcuts/shortcut_definition.dart';

/// Types of draggable items
enum DragType {
  component,      // Regular component (can be dragged freely)
  sectionContent, // Content inside composite sections (limited to section)
  forbidden,      // Cannot be dragged (composite structure)
}

/// Helper class for drag and drop operations
class DragHelper {

  /// Get the drag type of an item
  static DragType getDragType(EditableComponent component) {
    // Composite components themselves cannot be dragged when expanded
    if (component.isComposite && component.isExpanded) {
      return DragType.forbidden;
    }
    
    // Components inside sections have limited drag scope
    if (component.parentSectionId != null) {
      return DragType.sectionContent;
    }
    
    // Regular components can be dragged freely
    return DragType.component;
  }

  /// Check if an item can be dropped at target location
  static bool canDrop({
    required EditableComponent draggedItem,
    required dynamic targetLocation,
    String? targetSectionId,
  }) {
    final dragType = getDragType(draggedItem);
    
    switch (dragType) {
      case DragType.forbidden:
        // Forbidden items cannot be dropped anywhere
        return false;
        
      case DragType.sectionContent:
        // Section content can only be dropped within the same section
        return draggedItem.parentSectionId == targetSectionId;
        
      case DragType.component:
        // Regular components can be dropped in main list or empty sections
        return targetSectionId == null || targetLocation is ComponentSection;
    }
  }

  /// Build visual feedback for drag operations
  static Widget buildDragFeedback({
    required BuildContext context,
    required EditableComponent component,
    required ThemeData theme,
  }) {
    final dragType = getDragType(component);
    
    if (dragType == DragType.forbidden) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.block,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Structure cannot be moved',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    // Normal drag feedback
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: theme.cardColor.withValues(alpha: 0.9),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getComponentIcon(component),
              color: theme.primaryColor,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _getComponentName(component),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get drag handle widget based on drag type
  static Widget? buildDragHandle({
    required EditableComponent component,
    required int index,
    required ThemeData theme,
  }) {
    final dragType = getDragType(component);
    
    if (dragType == DragType.forbidden) {
      // No drag handle for forbidden items
      return Icon(
        Icons.lock_outline,
        color: theme.disabledColor,
        size: 20,
      );
    }
    
    // Normal drag handle
    return ReorderableDragStartListener(
      index: index,
      child: Icon(
        Icons.drag_handle,
        color: theme.iconTheme.color?.withValues(alpha: 0.6),
      ),
    );
  }

  static IconData _getComponentIcon(EditableComponent component) {
    if (component.isComposite) {
      switch (component.compositeComponent?.type) {
        case CompositeComponentType.ifElse:
          return Icons.call_split;
        case CompositeComponentType.switchCase:
          return Icons.account_tree;
        default:
          return Icons.widgets;
      }
    }
    
    // Map component types to icons
    switch (component.component.type) {
      case ComponentType.textInput:
        return Icons.text_fields;
      case ComponentType.numberInput:
        return Icons.numbers;
      case ComponentType.dropdown:
        return Icons.arrow_drop_down_circle;
      default:
        return Icons.widgets;
    }
  }

  static String _getComponentName(EditableComponent component) {
    if (component.isComposite) {
      switch (component.compositeComponent?.type) {
        case CompositeComponentType.ifElse:
          return 'IF-ELSE Structure';
        case CompositeComponentType.switchCase:
          return 'SWITCH-CASE Structure';
        default:
          return 'Composite Component';
      }
    }
    
    return component.component.properties['label'] ??
        component.component.type.toString().split('.').last;
  }
}