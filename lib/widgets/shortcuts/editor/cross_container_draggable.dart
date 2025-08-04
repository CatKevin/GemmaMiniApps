import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/shortcuts/editor_models.dart';
import '../../../utils/shortcuts/drag_helper.dart';

/// Data passed during drag operations
class DragData {
  final EditableComponent component;
  final String? sourceSectionId;
  final int sourceIndex;

  DragData({
    required this.component,
    this.sourceSectionId,
    required this.sourceIndex,
  });
}

/// Widget that enables cross-container drag and drop
class CrossContainerDraggable extends StatelessWidget {
  final EditableComponent component;
  final Widget child;
  final String? sectionId;
  final int index;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragCompleted;
  final bool enabled;

  const CrossContainerDraggable({
    super.key,
    required this.component,
    required this.child,
    this.sectionId,
    required this.index,
    this.onDragStarted,
    this.onDragCompleted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check if dragging is allowed
    final dragType = DragHelper.getDragType(component);
    if (!enabled || dragType == DragType.forbidden) {
      return child;
    }

    return LongPressDraggable<DragData>(
      data: DragData(
        component: component,
        sourceSectionId: sectionId,
        sourceIndex: index,
      ),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        onDragStarted?.call();
      },
      onDragCompleted: onDragCompleted,
      feedback: DragHelper.buildDragFeedback(
        context: context,
        component: component,
        theme: Theme.of(context),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: child,
      ),
      child: child,
    );
  }
}

/// Drop target widget for receiving dragged components
class ComponentDropTarget extends StatefulWidget {
  final Widget child;
  final int targetIndex;
  final String? targetSectionId;
  final Function(DragData data, int targetIndex) onAccept;
  final bool showDropIndicator;

  const ComponentDropTarget({
    super.key,
    required this.child,
    required this.targetIndex,
    this.targetSectionId,
    required this.onAccept,
    this.showDropIndicator = true,
  });

  @override
  State<ComponentDropTarget> createState() => _ComponentDropTargetState();
}

class _ComponentDropTargetState extends State<ComponentDropTarget> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        // Check if drop is allowed
        return DragHelper.canDrop(
          draggedItem: details.data.component,
          targetLocation: null,
          targetSectionId: widget.targetSectionId,
        );
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        widget.onAccept(details.data, widget.targetIndex);
        HapticFeedback.lightImpact();
      },
      onMove: (_) {
        if (!_isDragOver) {
          setState(() => _isDragOver = true);
        }
      },
      onLeave: (_) {
        setState(() => _isDragOver = false);
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          children: [
            // Drop indicator above the item
            if (_isDragOver && widget.showDropIndicator)
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // The actual child widget
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..scale(_isDragOver ? 0.95 : 1.0),
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}