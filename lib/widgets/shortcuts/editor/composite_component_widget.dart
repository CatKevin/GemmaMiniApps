import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/composite_component.dart';
import '../../../models/shortcuts/editor_models.dart';
import '../../../models/shortcuts/shortcut_definition.dart';
import '../../../models/shortcuts/variable.dart';
import 'component_panel.dart';
import 'property_editor.dart';

/// Widget for rendering composite components (IF-ELSE, SWITCH-CASE, etc.)
class CompositeComponentWidget extends HookWidget {
  final CompositeComponent component;
  final Function(String sectionId, EditableComponent) onAddComponent;
  final Function(String componentId) onRemoveComponent;
  final Function(int oldIndex, int newIndex, String sectionId) onReorderInSection;
  final Function(String componentId, String key, dynamic value) onPropertyChanged;
  final List<Variable> availableVariables;
  final Function(Variable) onAddVariable;
  final bool isExpanded;
  final Function() onToggleExpand;
  final Function() onDelete;

  const CompositeComponentWidget({
    super.key,
    required this.component,
    required this.onAddComponent,
    required this.onRemoveComponent,
    required this.onReorderInSection,
    required this.onPropertyChanged,
    required this.availableVariables,
    required this.onAddVariable,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _getComponentColor(component.type).withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.onBackground.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Composite component header
          _buildHeader(context, theme),
          // Sections
          if (isExpanded) ..._buildSections(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic theme) {
    return Container(
      decoration: BoxDecoration(
        color: _getComponentColor(component.type).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleExpand,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _getComponentIcon(component.type),
                  color: _getComponentColor(component.type),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getComponentTitle(component),
                        style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (component is IfElseComponent &&
                          (component as IfElseComponent).conditionExpression.isNotEmpty)
                        Text(
                          'Condition: ${(component as IfElseComponent).conditionExpression}',
                          style: TextStyle(
                            color: theme.onBackground.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      if (component is SwitchCaseComponent)
                        Text(
                          (component as SwitchCaseComponent).switchVariable,
                          style: TextStyle(
                            color: theme.onBackground.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Expand/Collapse icon
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.onBackground.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.error.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, dynamic theme) {
    return component.sections.map((section) {
      return _buildSection(context, section, theme);
    }).toList();
  }

  Widget _buildSection(BuildContext context, ComponentSection section, dynamic theme) {
    switch (section.type) {
      case CompositeSectionType.condition:
        return _buildConditionSection(context, section, theme);
      case CompositeSectionType.branch:
      case CompositeSectionType.caseOption:
      case CompositeSectionType.default_:
        return _buildBranchSection(section, theme);
      case CompositeSectionType.terminator:
        return _buildTerminatorSection(section, theme);
      default:
        return _buildBranchSection(section, theme);
    }
  }

  Widget _buildConditionSection(BuildContext context, ComponentSection section, dynamic theme) {
    final conditionController = useTextEditingController(
      text: section.properties['expression'] ?? '',
    );
    final showOptionsEditor = useState(false);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.onBackground.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Main condition row
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: _getComponentColor(component.type),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  section.label,
                  style: TextStyle(
                    color: _getComponentColor(component.type),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: conditionController,
                    style: TextStyle(color: theme.onBackground),
                    decoration: InputDecoration(
                      hintText: component.type == CompositeComponentType.switchCase
                          ? 'Enter menu prompt text'
                          : 'Enter condition expression',
                      hintStyle: TextStyle(
                        color: theme.onBackground.withValues(alpha: 0.4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.onBackground.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.onBackground.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _getComponentColor(component.type),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      section.properties['expression'] = value;
                      if (component is IfElseComponent) {
                        (component as IfElseComponent).conditionExpression = value;
                      } else if (component is SwitchCaseComponent) {
                        (component as SwitchCaseComponent).switchVariable = value;
                      }
                    },
                  ),
                ),
                // Options management button for SWITCH-CASE
                if (component.type == CompositeComponentType.switchCase) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      showOptionsEditor.value ? Icons.expand_less : Icons.settings,
                      color: theme.primary,
                    ),
                    onPressed: () {
                      showOptionsEditor.value = !showOptionsEditor.value;
                    },
                    tooltip: 'Manage options',
                  ),
                ],
              ],
            ),
          ),
          // Options editor for SWITCH-CASE
          if (component.type == CompositeComponentType.switchCase && showOptionsEditor.value)
            _buildOptionsEditor(context, component as SwitchCaseComponent, theme),
        ],
      ),
    );
  }

  Widget _buildOptionsEditor(BuildContext context, SwitchCaseComponent switchComponent, dynamic theme) {
    final newOptionController = useTextEditingController();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(
            color: theme.onBackground.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list,
                color: theme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Menu Options',
                style: TextStyle(
                  color: theme.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${switchComponent.caseOptions.length} options',
                style: TextStyle(
                  color: theme.onBackground.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Existing options
          ...switchComponent.caseOptions.map((option) {
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.onBackground.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_handle,
                    color: theme.onBackground.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: theme.onBackground,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Delete button (keep at least 2 options)
                  if (switchComponent.caseOptions.length > 2)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.error,
                        size: 18,
                      ),
                      onPressed: () {
                        switchComponent.removeCase(option);
                        onToggleExpand(); // Refresh UI
                      },
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          // Add new option
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: newOptionController,
                  style: TextStyle(color: theme.onBackground),
                  decoration: InputDecoration(
                    hintText: 'New option name',
                    hintStyle: TextStyle(
                      color: theme.onBackground.withValues(alpha: 0.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.onBackground.withValues(alpha: 0.2),
                      ),
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty && !switchComponent.caseOptions.contains(value)) {
                      switchComponent.addCase(value);
                      newOptionController.clear();
                      onToggleExpand(); // Refresh UI
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: theme.primary,
                ),
                onPressed: () {
                  final value = newOptionController.text;
                  if (value.isNotEmpty && !switchComponent.caseOptions.contains(value)) {
                    switchComponent.addCase(value);
                    newOptionController.clear();
                    onToggleExpand(); // Refresh UI
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchSection(ComponentSection section, dynamic theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.onBackground.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.surface,
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(section.type),
                  size: 16,
                  color: theme.onBackground.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  section.label,
                  style: TextStyle(
                    color: theme.onBackground,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (section.type == CompositeSectionType.branch &&
                    section.label == 'ELSE IF') ...[
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.error,
                    ),
                    onPressed: () {
                      if (component is IfElseComponent) {
                        (component as IfElseComponent).removeElseIf(section.id);
                        onToggleExpand(); // Refresh UI
                      }
                    },
                  ),
                ],
                // Delete button for CASE sections (keep at least 2 cases)
                if (section.type == CompositeSectionType.caseOption &&
                    component is SwitchCaseComponent &&
                    (component as SwitchCaseComponent).caseOptions.length > 2) ...[
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.error,
                    ),
                    onPressed: () {
                      final caseValue = section.properties['value'];
                      if (caseValue != null) {
                        (component as SwitchCaseComponent).removeCase(caseValue);
                        onToggleExpand(); // Refresh UI
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          // Content area (draggable components)
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 80),
            child: section.children.isEmpty
                ? _buildEmptyPlaceholder(section, theme)
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: section.children.length,
                    onReorder: (oldIndex, newIndex) {
                      onReorderInSection(oldIndex, newIndex, section.id);
                    },
                    itemBuilder: (context, index) {
                      final child = section.children[index];
                      return _buildDraggableChild(
                        child,
                        section,
                        index,
                        theme,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminatorSection(ComponentSection section, dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getComponentColor(component.type).withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Center(
        child: Text(
          section.label,
          style: TextStyle(
            color: _getComponentColor(component.type).withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(ComponentSection section, dynamic theme) {
    return GestureDetector(
      onTap: () => _showAddComponentDialog(section),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.onBackground.withValues(alpha: 0.1),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: theme.onBackground.withValues(alpha: 0.3),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Add components here',
              style: TextStyle(
                color: theme.onBackground.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableChild(
    EditableComponent child,
    ComponentSection section,
    int index,
    dynamic theme,
  ) {
    // Get the component template for property editing
    final template = ComponentTemplateLibrary.getTemplate(child.component.type);
    
    return _DraggableChildWidget(
      key: ValueKey(child.id),
      child: child,
      section: section,
      index: index,
      theme: theme,
      template: template,
      onRemoveComponent: onRemoveComponent,
      onPropertyChanged: onPropertyChanged,
      availableVariables: availableVariables,
      onAddVariable: onAddVariable,
    );
  }

  String _getComponentTitle(CompositeComponent component) {
    switch (component.type) {
      case CompositeComponentType.ifElse:
        return 'IF-ELSE Structure';
      case CompositeComponentType.switchCase:
        return 'Menu-Driven Logic';
      case CompositeComponentType.forEach:
        return 'FOR-EACH Loop';
      case CompositeComponentType.whileLoop:
        return 'WHILE Loop';
      case CompositeComponentType.tryError:
        return 'TRY-CATCH Block';
    }
  }

  IconData _getComponentIcon(CompositeComponentType type) {
    switch (type) {
      case CompositeComponentType.ifElse:
        return Icons.call_split;
      case CompositeComponentType.switchCase:
        return Icons.account_tree;
      case CompositeComponentType.forEach:
        return Icons.repeat;
      case CompositeComponentType.whileLoop:
        return Icons.loop;
      case CompositeComponentType.tryError:
        return Icons.error_outline;
    }
  }

  Color _getComponentColor(CompositeComponentType type) {
    switch (type) {
      case CompositeComponentType.ifElse:
        return Colors.blue;
      case CompositeComponentType.switchCase:
        return Colors.orange;
      case CompositeComponentType.forEach:
        return Colors.green;
      case CompositeComponentType.whileLoop:
        return Colors.purple;
      case CompositeComponentType.tryError:
        return Colors.red;
    }
  }

  IconData _getSectionIcon(CompositeSectionType type) {
    switch (type) {
      case CompositeSectionType.condition:
        return Icons.help_outline;
      case CompositeSectionType.branch:
        return Icons.arrow_forward;
      case CompositeSectionType.caseOption:
        return Icons.label_outline;
      case CompositeSectionType.default_:
        return Icons.all_inclusive;
      case CompositeSectionType.terminator:
        return Icons.stop;
      default:
        return Icons.circle_outlined;
    }
  }


  void _showAddComponentDialog(ComponentSection section) {
    final theme = ThemeController.to.currentThemeConfig;
    
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(Get.context!).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: theme.onSurface.withValues(alpha: 0.1),
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
                color: theme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSectionIcon(section.type),
                    color: _getComponentColor(component.type),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Component to ${section.label}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.onSurface,
                        ),
                      ),
                      Text(
                        'Select a component to add',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.onSurface,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Component Panel
            Expanded(
              child: ComponentPanel(
                onComponentSelected: (template) {
                  // Create new component from template
                  final newComponent = EditableComponent(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    component: UIComponent(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      type: template.type,
                      properties: Map<String, dynamic>.from(template.defaultProperties),
                    ),
                    order: section.children.length,
                    parentSectionId: section.id,
                  );
                  
                  // Add to section
                  onAddComponent(section.id, newComponent);
                  
                  // Note: ComponentPanel already handles closing the bottom sheet
                  // No need to call Get.back() here
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete ${_getComponentTitle(component)}?'),
        content: const Text(
          'This will delete the entire structure and all components within it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: ThemeController.to.currentThemeConfig.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Separate widget to handle hooks properly
class _DraggableChildWidget extends HookWidget {
  final EditableComponent child;
  final ComponentSection section;
  final int index;
  final dynamic theme;
  final ComponentTemplate? template;
  final Function(String) onRemoveComponent;
  final Function(String, String, dynamic) onPropertyChanged;
  final List<Variable> availableVariables;
  final Function(Variable) onAddVariable;

  const _DraggableChildWidget({
    super.key,
    required this.child,
    required this.section,
    required this.index,
    required this.theme,
    required this.template,
    required this.onRemoveComponent,
    required this.onPropertyChanged,
    required this.availableVariables,
    required this.onAddVariable,
  });

  @override
  Widget build(BuildContext context) {
    // Track expansion state
    final isExpanded = useState(false);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(
          color: theme.onBackground.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Component header
          InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        color: theme.onBackground.withValues(alpha: 0.4),
                        size: 18,
                      ),
                    ),
                  ),
                  // Component icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getComponentIconByType(child.component.type),
                      color: theme.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          child.component.properties['label'] ??
                              child.component.properties['title'] ??
                              child.component.type.toString().split('.').last,
                          style: TextStyle(
                            color: theme.onBackground,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          child.component.type.toString().split('.').last,
                          style: TextStyle(
                            color: theme.onBackground.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse icon
                  Icon(
                    isExpanded.value ? Icons.expand_less : Icons.expand_more,
                    color: theme.onBackground.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  // Delete button
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.error,
                      size: 18,
                    ),
                    onPressed: () => onRemoveComponent(child.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Property editor (shown when expanded)
          if (isExpanded.value && template != null)
            ComponentPropertyEditor(
              component: child.component,
              template: template!,
              onPropertyChanged: (key, value) {
                onPropertyChanged(child.component.id, key, value);
              },
              availableVariables: availableVariables,
              onAddVariable: onAddVariable,
            ),
        ],
      ),
    );
  }

  IconData _getComponentIconByType(ComponentType type) {
    switch (type) {
      case ComponentType.textInput:
      case ComponentType.multilineTextInput:
        return Icons.text_fields;
      case ComponentType.numberInput:
        return Icons.numbers;
      case ComponentType.dateTimePicker:
        return Icons.calendar_today;
      case ComponentType.slider:
        return Icons.tune;
      case ComponentType.singleSelect:
      case ComponentType.multiSelect:
        return Icons.checklist;
      case ComponentType.dropdown:
        return Icons.arrow_drop_down_circle;
      case ComponentType.toggle:
      case ComponentType.switch_:
        return Icons.toggle_on;
      case ComponentType.tagSelect:
      case ComponentType.tagInput:
        return Icons.label;
      case ComponentType.titleText:
      case ComponentType.descriptionText:
        return Icons.text_snippet;
      case ComponentType.image:
        return Icons.image;
      case ComponentType.progressIndicator:
        return Icons.linear_scale;
      case ComponentType.groupContainer:
        return Icons.view_module;
      case ComponentType.tabs:
        return Icons.tab;
      case ComponentType.stepIndicator:
        return Icons.format_list_numbered;
      default:
        return Icons.widgets;
    }
  }

}