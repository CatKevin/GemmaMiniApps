import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../../controllers/shortcuts/editor_controller.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/models.dart';
import '../../../models/shortcuts/variable.dart';
import 'unified_component_panel.dart';
import 'property_editor.dart';
import 'cross_container_draggable.dart';
import 'expression_editor.dart';

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

    // Add a visual indicator to show the entire component can be dragged
    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: Container(
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic theme) {
    final isDragging = useState(false);
    
    return GestureDetector(
      onTap: onToggleExpand,
      child: Container(
        decoration: BoxDecoration(
          color: _getComponentColor(component.type).withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Drag handle indicator
            Tooltip(
              message: 'Long press anywhere on this component to drag',
              child: Icon(
                Icons.drag_handle,
                color: theme.onBackground.withValues(alpha: 0.4),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
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
    );
  }

  List<Widget> _buildSections(BuildContext context, dynamic theme) {
    final sections = <Widget>[];
    
    // Add each section with proper separation
    for (int i = 0; i < component.sections.length; i++) {
      final section = component.sections[i];
      
      // Add separator between condition section and case options for Menu Logic
      if (component.type == CompositeComponentType.switchCase &&
          i == 1 && // After the first section (condition)
          section.type == CompositeSectionType.caseOption) {
        sections.add(_buildSeparator(theme));
      }
      
      sections.add(_buildSection(context, section, theme));
    }

    return sections;
  }
  
  Widget _buildSeparator(dynamic theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.orange.withValues(alpha: 0.0),
                    Colors.orange.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'SELECT OPTIONS',
              style: TextStyle(
                color: Colors.orange.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.orange.withValues(alpha: 0.3),
                    Colors.orange.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

    // Convert available variables to the format needed by ExpressionEditor
    final variableDefinitions = <String, VariableDefinition>{};
    for (var variable in availableVariables) {
      variableDefinitions[variable.name] = VariableDefinition(
        name: variable.name,
        type: variable.type,
        defaultValue: variable.value,
      );
    }

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
            padding: component.type == CompositeComponentType.switchCase 
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                : null,
            child: component.type == CompositeComponentType.ifElse
                ? Container(
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      childrenPadding: const EdgeInsets.all(16),
                      leading: Icon(
                        Icons.help_outline,
                        color: _getComponentColor(component.type),
                        size: 20,
                      ),
                      title: Text(
                        section.label,
                        style: TextStyle(
                          color: _getComponentColor(component.type),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: section.properties['expression']?.isNotEmpty == true
                          ? Text(
                              section.properties['expression']!,
                              style: TextStyle(
                                color: theme.onBackground.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            )
                          : Text(
                              'Click to set condition',
                              style: TextStyle(
                                color: theme.onBackground.withValues(alpha: 0.4),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                      initiallyExpanded: false,
                      children: [
                        ExpressionEditor(
                          initialValue: section.properties['expression'] ?? '',
                          onChanged: (value) {
                            section.properties['expression'] = value;
                            if (component is IfElseComponent) {
                              (component as IfElseComponent).conditionExpression = value;
                            }
                            // Trigger rebuild
                            (context as Element).markNeedsBuild();
                          },
                          availableVariables: variableDefinitions,
                          label: 'Build Condition',
                          hint: 'Select a variable and define the condition',
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          const Spacer(),
                          // Options management button for SWITCH-CASE
                          if (component.type == CompositeComponentType.switchCase) ...[
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
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.surface,
                              theme.background,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.onBackground.withValues(alpha: 0.05),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: conditionController,
                            style: TextStyle(
                              color: theme.onBackground,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            minLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Enter your menu prompt here...\nDescribe what options the user will choose from\nBe clear and concise',
                              hintStyle: TextStyle(
                                color: theme.onBackground.withValues(alpha: 0.3),
                                fontSize: 14,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              border: InputBorder.none,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 16, right: 8),
                                child: Icon(
                                  Icons.edit_note,
                                  color: Colors.orange.withValues(alpha: 0.6),
                                  size: 24,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 48,
                              ),
                            ),
                            onChanged: (value) {
                              section.properties['expression'] = value;
                              if (component is SwitchCaseComponent) {
                                (component as SwitchCaseComponent).switchVariable = value;
                              }
                            },
                          ),
                        ),
                      ),
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
    final editingStates = useState<Map<int, bool>>({});
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border.all(
          color: theme.onBackground.withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with primary color background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.onBackground.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.list,
                  color: theme.onBackground.withValues(alpha: 0.7),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.onBackground.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${switchComponent.caseOptions.length} options',
                    style: TextStyle(
                      color: theme.onBackground.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Options content with padding
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Existing options
                ...switchComponent.caseOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isEditing = editingStates.value[index] ?? false;
                  final editController = useTextEditingController(text: option);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEditing 
                            ? Colors.orange.withValues(alpha: 0.5)
                            : theme.onBackground.withValues(alpha: 0.1),
                        width: isEditing ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.orange.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: isEditing
                              ? TextField(
                                  controller: editController,
                                  autofocus: true,
                                  style: TextStyle(
                                    color: theme.onBackground,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onSubmitted: (newValue) {
                                    if (newValue.isNotEmpty && newValue != option && !switchComponent.caseOptions.contains(newValue)) {
                                      // Use rename method to preserve child components
                                      switchComponent.renameCase(index, newValue);
                                      
                                      // Trigger UI update
                                      onPropertyChanged(component.id, 'structure_updated', DateTime.now().millisecondsSinceEpoch);
                                    }
                                    editingStates.value = {...editingStates.value, index: false};
                                  },
                                  onTapOutside: (_) {
                                    // Save changes when tapping outside
                                    final newValue = editController.text;
                                    if (newValue.isNotEmpty && newValue != option && !switchComponent.caseOptions.contains(newValue)) {
                                      // Use rename method to preserve child components
                                      switchComponent.renameCase(index, newValue);
                                      onPropertyChanged(component.id, 'structure_updated', DateTime.now().millisecondsSinceEpoch);
                                    }
                                    editingStates.value = {...editingStates.value, index: false};
                                  },
                                )
                              : InkWell(
                                  onTap: () {
                                    editingStates.value = {...editingStates.value, index: true};
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        color: theme.onBackground,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // Edit button
                        if (!isEditing)
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: theme.onBackground.withValues(alpha: 0.5),
                              size: 16,
                            ),
                            onPressed: () {
                              editingStates.value = {...editingStates.value, index: true};
                            },
                          ),
                        // Delete button (keep at least 2 options)
                        if (switchComponent.caseOptions.length > 2)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: theme.error,
                              size: 16,
                            ),
                            onPressed: () {
                              switchComponent.removeCase(option);
                              // Trigger UI update without changing expansion state
                              onPropertyChanged(component.id, 'structure_updated', DateTime.now().millisecondsSinceEpoch);
                            },
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                // Add new option section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withValues(alpha: 0.05),
                        Colors.orange.withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newOptionController,
                          style: TextStyle(
                            color: theme.onBackground,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type new option name and press Enter',
                            hintStyle: TextStyle(
                              color: theme.onBackground.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: theme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.orange.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty && !switchComponent.caseOptions.contains(value)) {
                              switchComponent.addCase(value);
                              newOptionController.clear();
                              // Trigger UI update without changing expansion state
                              onPropertyChanged(component.id, 'structure_updated', DateTime.now().millisecondsSinceEpoch);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            final value = newOptionController.text;
                            if (value.isNotEmpty && !switchComponent.caseOptions.contains(value)) {
                              switchComponent.addCase(value);
                              newOptionController.clear();
                              // Trigger UI update without changing expansion state
                              onPropertyChanged(component.id, 'structure_updated', DateTime.now().millisecondsSinceEpoch);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.add_circle,
                              color: Colors.orange.withValues(alpha: 0.8),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchSection(ComponentSection section, dynamic theme) {
    // Convert available variables to the format needed by ExpressionEditor
    final variableDefinitions = <String, VariableDefinition>{};
    for (var variable in availableVariables) {
      variableDefinitions[variable.name] = VariableDefinition(
        name: variable.name,
        type: variable.type,
        defaultValue: variable.value,
      );
    }

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
            child: Column(
              children: [
                Row(
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
                            // Trigger UI update without changing expansion state
                            onPropertyChanged(component.id, 'structure_updated', DateTime.now().millisecondsSinceEpoch);
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
                            // Trigger UI update without changing expansion state
                            onPropertyChanged(component.id, 'structure_updated', DateTime.now().millisecondsSinceEpoch);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                // Show condition preview for ELSE IF
                if (section.type == CompositeSectionType.branch &&
                    section.label == 'ELSE IF' &&
                    section.properties['expression']?.isNotEmpty == true) ...[
                  const Spacer(),
                  Expanded(
                    child: Text(
                      section.properties['expression']!,
                      style: TextStyle(
                        color: theme.onBackground.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          // Add condition editor for ELSE IF
          if (section.type == CompositeSectionType.branch &&
              section.label == 'ELSE IF') ...[
            Container(
              color: theme.surface,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.all(16),
                leading: Icon(
                  Icons.build_circle,
                  color: theme.primary,
                  size: 20,
                ),
                title: Text(
                  'Edit Condition',
                  style: TextStyle(
                    color: theme.onBackground,
                    fontSize: 14,
                  ),
                ),
                initiallyExpanded: section.properties['expression']?.isEmpty ?? true,
                children: [
                  ExpressionEditor(
                    initialValue: section.properties['expression'] ?? '',
                    onChanged: (value) {
                      section.properties['expression'] = value;
                      // Don't need to trigger rebuild here as state will update automatically
                    },
                    availableVariables: variableDefinitions,
                    label: 'Condition',
                    hint: 'Define the condition for this ELSE IF branch',
                  ),
                ],
              ),
            ),
          ],
          // Content area (draggable components)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(minHeight: 40),
            child: ComponentDropTarget(
              targetSectionId: section.id,
              targetIndex: section.children.length,
              onAccept: (dragData, targetIndex) {
                // Handle drop from main list to section
                if (dragData.sourceSectionId == null) {
                  // Component is from main list
                  final controller = Get.find<EditorController>();
                  controller.moveComponentToSection(
                    dragData.component.id,
                    section.id,
                    targetIndex,
                  );
                } else if (dragData.sourceSectionId == section.id) {
                  // Reorder within same section
                  onReorderInSection(dragData.sourceIndex, targetIndex, section.id);
                } else {
                  // Move from another section directly
                  final controller = Get.find<EditorController>();
                  controller.moveComponentBetweenSections(
                    dragData.component.id,
                    dragData.sourceSectionId!,
                    section.id,
                    targetIndex,
                  );
                }
              },
              showDropIndicator: section.children.isEmpty,
              child: section.children.isEmpty
                  ? _buildEmptyPlaceholder(section, theme)
                  : Column(
                      children: [
                        // Existing components
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: section.children.length,
                          itemBuilder: (context, index) {
                            final child = section.children[index];
                            return ComponentDropTarget(
                              targetSectionId: section.id,
                              targetIndex: index,
                              onAccept: (dragData, targetIndex) {
                                // Handle drop from main list to section
                                if (dragData.sourceSectionId == null) {
                                  // Component is from main list
                                  final controller = Get.find<EditorController>();
                                  controller.moveComponentToSection(
                                    dragData.component.id,
                                    section.id,
                                    targetIndex,
                                  );
                                } else if (dragData.sourceSectionId == section.id) {
                                  // Reorder within same section
                                  onReorderInSection(dragData.sourceIndex, targetIndex, section.id);
                                } else {
                                  // Move from another section directly
                                  final controller = Get.find<EditorController>();
                                  controller.moveComponentBetweenSections(
                                    dragData.component.id,
                                    dragData.sourceSectionId!,
                                    section.id,
                                    targetIndex,
                                  );
                                }
                              },
                              child: _buildDraggableChild(
                                child,
                                section,
                                index,
                                theme,
                              ),
                            );
                          },
                        ),
                        // Drop zone at the end
                        ComponentDropTarget(
                          targetSectionId: section.id,
                          targetIndex: section.children.length,
                          onAccept: (dragData, targetIndex) {
                            // Handle drop from main list to section
                            if (dragData.sourceSectionId == null) {
                              // Component is from main list
                              final controller = Get.find<EditorController>();
                              controller.moveComponentToSection(
                                dragData.component.id,
                                section.id,
                                section.children.length,
                              );
                            } else if (dragData.sourceSectionId == section.id) {
                              // Reorder within same section
                              onReorderInSection(dragData.sourceIndex, section.children.length, section.id);
                            } else {
                              // Move from another section directly
                              final controller = Get.find<EditorController>();
                              controller.moveComponentBetweenSections(
                                dragData.component.id,
                                dragData.sourceSectionId!,
                                section.id,
                                section.children.length,
                              );
                            }
                          },
                          showDropIndicator: true,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: () => _showAddComponentDialog(section),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Add Component'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.primary,
                                side: BorderSide(color: theme.primary),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // Add ELSE IF button for THEN and ELSE IF sections
          if (component is IfElseComponent && 
              section.label != 'ELSE' && 
              section.type == CompositeSectionType.branch) ...[
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.onBackground.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Material(
                color: theme.surface.withValues(alpha: 0.5),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Find the index of current section
                    final currentIndex = component.sections.indexOf(section);
                    // Add new ELSE IF after current section
                    (component as IfElseComponent).addElseIf('');
                    
                    // Find the newly added ELSE IF (it's always inserted before ELSE)
                    final elseIndex = component.sections.indexWhere((s) => s.label == 'ELSE');
                    if (elseIndex > 0 && currentIndex >= 0) {
                      // The new ELSE IF is at elseIndex - 1
                      final newElseIf = component.sections[elseIndex - 1];
                      // Remove it from current position
                      component.sections.removeAt(elseIndex - 1);
                      // Insert it right after the current section
                      component.sections.insert(currentIndex + 1, newElseIf);
                    }
                    
                    // Use a small delay to ensure the UI updates
                    Future.delayed(Duration.zero, () {
                      // This will trigger a rebuild after the current frame
                      onPropertyChanged(component.id, 'structure_updated', DateTime.now().millisecondsSinceEpoch);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: theme.onBackground.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add ELSE IF below',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.onBackground.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: OutlinedButton.icon(
        onPressed: () => _showAddComponentDialog(section),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Component'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.primary,
          side: BorderSide(color: theme.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => UnifiedComponentPanel(
          hideLogicComponents: true,  // Hide logic components when adding to sections
          onComponentSelected: (component) {
            // Only handle regular components, not logic components
            if (component is ComponentTemplate) {
              // Create new component from template
              final newComponent = EditableComponent(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                component: UIComponent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: component.type,
                  properties: Map<String, dynamic>.from(component.defaultProperties),
                ),
                order: section.children.length,
                parentSectionId: section.id,
              );
              
              // Add to section
              onAddComponent(section.id, newComponent);
            }
            // Ignore logic components (CompositeComponentType) for sections
          },
        ),
      ),
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
    
    return CrossContainerDraggable(
      component: child,
      sectionId: section.id,
      index: index,
      enabled: true,
      child: Container(
        margin: index < section.children.length - 1 
            ? const EdgeInsets.only(bottom: 8)
            : const EdgeInsets.only(bottom: 4),
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
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        color: theme.onBackground.withValues(alpha: 0.4),
                        size: 18,
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