import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'shortcut_definition.dart';

/// Component that can be added from the component panel
class ComponentTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final ComponentCategory category;
  final ComponentType type;
  final Map<String, dynamic> defaultProperties;
  final List<ComponentProperty> editableProperties;

  ComponentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.type,
    required this.defaultProperties,
    required this.editableProperties,
  });
}

/// Category for grouping components
enum ComponentCategory {
  input,
  selection,
  display,
  layout,
  logic,
  prompt,
}

/// Property that can be edited in the editor
class ComponentProperty {
  final String key;
  final String label;
  final PropertyType type;
  final dynamic defaultValue;
  final bool required;
  final List<dynamic>? options; // For select types
  final Map<String, dynamic>? constraints;

  ComponentProperty({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.required = false,
    this.options,
    this.constraints,
  });
}

/// Types of properties that can be edited
enum PropertyType {
  text,
  number,
  boolean,
  select,
  multiSelect,
  variable,
  expression,
  richText,
}

/// Editor state for a component being edited
class EditableComponent {
  final String id;
  final UIComponent component;
  final bool isExpanded;
  final bool isSelected;
  final int order;
  final quill.QuillController? richTextController;

  EditableComponent({
    required this.id,
    required this.component,
    this.isExpanded = false,
    this.isSelected = false,
    required this.order,
    this.richTextController,
  });

  EditableComponent copyWith({
    String? id,
    UIComponent? component,
    bool? isExpanded,
    bool? isSelected,
    int? order,
    quill.QuillController? richTextController,
  }) {
    return EditableComponent(
      id: id ?? this.id,
      component: component ?? this.component,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      order: order ?? this.order,
      richTextController: richTextController ?? this.richTextController,
    );
  }
}

/// Editor session state
class EditorSession {
  final String shortcutId;
  final String shortcutName;
  final List<EditableComponent> components;
  final Map<String, VariableDefinition> variables;
  final Set<String> expandedComponents;
  final String? selectedComponentId;
  final bool hasUnsavedChanges;
  final DateTime lastModified;

  EditorSession({
    required this.shortcutId,
    required this.shortcutName,
    required this.components,
    required this.variables,
    required this.expandedComponents,
    this.selectedComponentId,
    required this.hasUnsavedChanges,
    required this.lastModified,
  });

  EditorSession copyWith({
    String? shortcutId,
    String? shortcutName,
    List<EditableComponent>? components,
    Map<String, VariableDefinition>? variables,
    Set<String>? expandedComponents,
    String? selectedComponentId,
    bool? hasUnsavedChanges,
    DateTime? lastModified,
  }) {
    return EditorSession(
      shortcutId: shortcutId ?? this.shortcutId,
      shortcutName: shortcutName ?? this.shortcutName,
      components: components ?? this.components,
      variables: variables ?? this.variables,
      expandedComponents: expandedComponents ?? this.expandedComponents,
      selectedComponentId: selectedComponentId,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Variable reference in rich text
class VariableReference {
  final String variableName;
  final int startIndex;
  final int endIndex;

  VariableReference({
    required this.variableName,
    required this.startIndex,
    required this.endIndex,
  });
}

/// Preview data for testing shortcuts
class PreviewData {
  final Map<String, dynamic> sampleVariables;
  final String generatedPrompt;
  final List<String> warnings;

  PreviewData({
    required this.sampleVariables,
    required this.generatedPrompt,
    required this.warnings,
  });
}

/// Component drag state
class DragState {
  final String componentId;
  final int originalIndex;
  final int currentIndex;
  final bool isDragging;

  DragState({
    required this.componentId,
    required this.originalIndex,
    required this.currentIndex,
    required this.isDragging,
  });
}

/// Available component templates
class ComponentTemplateLibrary {
  static final List<ComponentTemplate> templates = [
    // Input Components
    ComponentTemplate(
      id: 'text-input',
      name: 'Text Input',
      description: 'Single line text input',
      icon: Icons.text_fields,
      category: ComponentCategory.input,
      type: ComponentType.textInput,
      defaultProperties: {
        'placeholder': 'Enter text...',
        'maxLength': 100,
        'required': false,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'placeholder',
          label: 'Placeholder',
          type: PropertyType.text,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: true,
        ),
        ComponentProperty(
          key: 'maxLength',
          label: 'Max Length',
          type: PropertyType.number,
          defaultValue: 100,
        ),
        ComponentProperty(
          key: 'required',
          label: 'Required',
          type: PropertyType.boolean,
          defaultValue: false,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'multiline-input',
      name: 'Multiline Text',
      description: 'Multi-line text input',
      icon: Icons.notes,
      category: ComponentCategory.input,
      type: ComponentType.multilineTextInput,
      defaultProperties: {
        'placeholder': 'Enter detailed text...',
        'rows': 4,
        'maxLength': 500,
        'required': false,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'placeholder',
          label: 'Placeholder',
          type: PropertyType.text,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: true,
        ),
        ComponentProperty(
          key: 'rows',
          label: 'Rows',
          type: PropertyType.number,
          defaultValue: 4,
        ),
        ComponentProperty(
          key: 'maxLength',
          label: 'Max Length',
          type: PropertyType.number,
          defaultValue: 500,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'number-input',
      name: 'Number Input',
      description: 'Numeric input field',
      icon: Icons.numbers,
      category: ComponentCategory.input,
      type: ComponentType.numberInput,
      defaultProperties: {
        'min': 0,
        'max': 100,
        'step': 1,
        'required': false,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: true,
        ),
        ComponentProperty(
          key: 'min',
          label: 'Minimum',
          type: PropertyType.number,
          defaultValue: 0,
        ),
        ComponentProperty(
          key: 'max',
          label: 'Maximum',
          type: PropertyType.number,
          defaultValue: 100,
        ),
        ComponentProperty(
          key: 'step',
          label: 'Step',
          type: PropertyType.number,
          defaultValue: 1,
        ),
      ],
    ),
    
    // Selection Components
    ComponentTemplate(
      id: 'single-select',
      name: 'Single Select',
      description: 'Radio button selection',
      icon: Icons.radio_button_checked,
      category: ComponentCategory.selection,
      type: ComponentType.singleSelect,
      defaultProperties: {
        'options': ['Option 1', 'Option 2', 'Option 3'],
        'required': true,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: true,
        ),
        ComponentProperty(
          key: 'options',
          label: 'Options',
          type: PropertyType.multiSelect,
          required: true,
        ),
        ComponentProperty(
          key: 'required',
          label: 'Required',
          type: PropertyType.boolean,
          defaultValue: true,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'multi-select',
      name: 'Multi Select',
      description: 'Checkbox selection',
      icon: Icons.check_box,
      category: ComponentCategory.selection,
      type: ComponentType.multiSelect,
      defaultProperties: {
        'options': ['Option 1', 'Option 2', 'Option 3'],
        'minSelection': 0,
        'maxSelection': null,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: true,
        ),
        ComponentProperty(
          key: 'options',
          label: 'Options',
          type: PropertyType.multiSelect,
          required: true,
        ),
        ComponentProperty(
          key: 'minSelection',
          label: 'Min Selection',
          type: PropertyType.number,
          defaultValue: 0,
        ),
        ComponentProperty(
          key: 'maxSelection',
          label: 'Max Selection',
          type: PropertyType.number,
        ),
      ],
    ),
    
    // Logic Components
    ComponentTemplate(
      id: 'conditional',
      name: 'If Condition',
      description: 'Conditional logic',
      icon: Icons.alt_route,
      category: ComponentCategory.logic,
      type: ComponentType.conditional,
      defaultProperties: {
        'condition': '',
        'trueComponents': [],
        'falseComponents': [],
      },
      editableProperties: [
        ComponentProperty(
          key: 'condition',
          label: 'Condition',
          type: PropertyType.expression,
          required: true,
        ),
      ],
    ),
    
    // Prompt Components
    ComponentTemplate(
      id: 'text-template',
      name: 'Text Template',
      description: 'Rich text with variables',
      icon: Icons.text_snippet,
      category: ComponentCategory.prompt,
      type: ComponentType.textTemplate,
      defaultProperties: {
        'content': '',
      },
      editableProperties: [
        ComponentProperty(
          key: 'title',
          label: 'Component Title',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'content',
          label: 'Content',
          type: PropertyType.richText,
          required: true,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'role-definition',
      name: 'Role Definition',
      description: 'Define AI role',
      icon: Icons.person,
      category: ComponentCategory.prompt,
      type: ComponentType.roleDefinition,
      defaultProperties: {
        'role': 'You are a helpful assistant',
      },
      editableProperties: [
        ComponentProperty(
          key: 'role',
          label: 'Role Description',
          type: PropertyType.richText,
          required: true,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'task-description',
      name: 'Task Description',
      description: 'Define the task',
      icon: Icons.task_alt,
      category: ComponentCategory.prompt,
      type: ComponentType.taskDescription,
      defaultProperties: {
        'task': '',
      },
      editableProperties: [
        ComponentProperty(
          key: 'task',
          label: 'Task Description',
          type: PropertyType.richText,
          required: true,
        ),
      ],
    ),
  ];

  static ComponentTemplate? getTemplate(ComponentType type) {
    return templates.firstWhere(
      (t) => t.type == type,
      orElse: () => templates.first,
    );
  }

  static List<ComponentTemplate> getByCategory(ComponentCategory category) {
    return templates.where((t) => t.category == category).toList();
  }
}