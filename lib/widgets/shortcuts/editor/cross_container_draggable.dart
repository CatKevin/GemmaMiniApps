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
class CrossContainerDraggable extends StatefulWidget {
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
  State<CrossContainerDraggable> createState() => _CrossContainerDraggableState();
}

class _CrossContainerDraggableState extends State<CrossContainerDraggable>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onLongPressStart(_) {
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _onLongPressEnd(_) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Check if dragging is allowed
    final dragType = DragHelper.getDragType(widget.component);
    if (!widget.enabled || dragType == DragType.forbidden) {
      return widget.child;
    }

    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: LongPressDraggable<DragData>(
                data: DragData(
                  component: widget.component,
                  sourceSectionId: widget.sectionId,
                  sourceIndex: widget.index,
                ),
                onDragStarted: () {
                  HapticFeedback.mediumImpact();
                  widget.onDragStarted?.call();
                },
                onDragCompleted: widget.onDragCompleted,
                onDragEnd: (_) {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                },
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.05,
                    child: DragHelper.buildDragFeedback(
                      context: context,
                      component: widget.component,
                      theme: Theme.of(context),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.2,
                  child: widget.child,
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
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