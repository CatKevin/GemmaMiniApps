import 'package:flutter/material.dart';

/// Core model for a Shortcut definition
class ShortcutDefinition {
  final String id;
  final String name;
  final String description;
  final String category;
  final ShortcutIcon icon;
  
  // UI flow definition
  final List<ScreenDefinition> screens;
  final String startScreenId;
  final Map<String, ScreenTransition> transitions;
  
  // Variable definitions
  final Map<String, VariableDefinition> variables;
  
  // Prompt construction definition
  final PromptTemplate promptTemplate;
  
  // Metadata
  final String version;
  final String author;
  final bool isBuiltIn;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int usageCount;

  ShortcutDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.screens,
    required this.startScreenId,
    required this.transitions,
    required this.variables,
    required this.promptTemplate,
    required this.version,
    required this.author,
    required this.isBuiltIn,
    required this.createdAt,
    required this.updatedAt,
    required this.usageCount,
  });

  ShortcutDefinition copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    ShortcutIcon? icon,
    List<ScreenDefinition>? screens,
    String? startScreenId,
    Map<String, ScreenTransition>? transitions,
    Map<String, VariableDefinition>? variables,
    PromptTemplate? promptTemplate,
    String? version,
    String? author,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? usageCount,
  }) {
    return ShortcutDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      screens: screens ?? this.screens,
      startScreenId: startScreenId ?? this.startScreenId,
      transitions: transitions ?? this.transitions,
      variables: variables ?? this.variables,
      promptTemplate: promptTemplate ?? this.promptTemplate,
      version: version ?? this.version,
      author: author ?? this.author,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon.toJson(),
      'screens': screens.map((s) => s.toJson()).toList(),
      'startScreenId': startScreenId,
      'transitions': transitions.map((k, v) => MapEntry(k, v.toJson())),
      'variables': variables.map((k, v) => MapEntry(k, v.toJson())),
      'promptTemplate': promptTemplate.toJson(),
      'version': version,
      'author': author,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  factory ShortcutDefinition.fromJson(Map<String, dynamic> json) {
    return ShortcutDefinition(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      icon: ShortcutIcon.fromJson(json['icon']),
      screens: (json['screens'] as List)
          .map((s) => ScreenDefinition.fromJson(s))
          .toList(),
      startScreenId: json['startScreenId'],
      transitions: (json['transitions'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, ScreenTransition.fromJson(v))),
      variables: (json['variables'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, VariableDefinition.fromJson(v))),
      promptTemplate: PromptTemplate.fromJson(json['promptTemplate']),
      version: json['version'] ?? '1.0.0',
      author: json['author'] ?? 'Unknown',
      isBuiltIn: json['isBuiltIn'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      usageCount: json['usageCount'],
    );
  }
}

/// Icon definition for a Shortcut
class ShortcutIcon {
  final IconData iconData;
  final Color? color;

  ShortcutIcon({
    required this.iconData,
    this.color,
  });
  
  static final ShortcutIcon defaultIcon = ShortcutIcon(
    iconData: Icons.flash_on,
  );

  Map<String, dynamic> toJson() {
    return {
      'codePoint': iconData.codePoint,
      'fontFamily': iconData.fontFamily,
      'color': color?.value,
    };
  }

  factory ShortcutIcon.fromJson(Map<String, dynamic> json) {
    return ShortcutIcon(
      iconData: IconData(
        json['codePoint'],
        fontFamily: json['fontFamily'],
      ),
      color: json['color'] != null ? Color(json['color']) : null,
    );
  }
}

/// Screen definition within a Shortcut
class ScreenDefinition {
  final String id;
  final String title;
  final List<UIComponent> components;
  final Map<String, ScreenAction> actions;

  ScreenDefinition({
    required this.id,
    required this.title,
    required this.components,
    required this.actions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'components': components.map((c) => c.toJson()).toList(),
      'actions': actions.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  factory ScreenDefinition.fromJson(Map<String, dynamic> json) {
    return ScreenDefinition(
      id: json['id'],
      title: json['title'],
      components: (json['components'] as List)
          .map((c) => UIComponent.fromJson(c))
          .toList(),
      actions: (json['actions'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, ScreenAction.fromJson(v))),
    );
  }
}

/// Base class for UI components
class UIComponent {
  final String id;
  final ComponentType type;
  final Map<String, dynamic> properties;
  final String? variableBinding;
  final ValidationRule? validation;
  final String? conditionalDisplay;

  UIComponent({
    required this.id,
    required this.type,
    required this.properties,
    this.variableBinding,
    this.validation,
    this.conditionalDisplay,
  });
  
  UIComponent copyWith({
    String? id,
    ComponentType? type,
    Map<String, dynamic>? properties,
    String? variableBinding,
    ValidationRule? validation,
    String? conditionalDisplay,
  }) {
    return UIComponent(
      id: id ?? this.id,
      type: type ?? this.type,
      properties: properties ?? this.properties,
      variableBinding: variableBinding ?? this.variableBinding,
      validation: validation ?? this.validation,
      conditionalDisplay: conditionalDisplay ?? this.conditionalDisplay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'properties': properties,
      'variableBinding': variableBinding,
      'validation': validation?.toJson(),
      'conditionalDisplay': conditionalDisplay,
    };
  }

  factory UIComponent.fromJson(Map<String, dynamic> json) {
    return UIComponent(
      id: json['id'],
      type: ComponentType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
      ),
      properties: json['properties'],
      variableBinding: json['variableBinding'],
      validation: json['validation'] != null
          ? ValidationRule.fromJson(json['validation'])
          : null,
      conditionalDisplay: json['conditionalDisplay'],
    );
  }
}

/// Component types
enum ComponentType {
  // Input components
  textInput,
  multilineTextInput,
  numberInput,
  dateTimePicker,
  slider,
  
  // Selection components
  singleSelect,
  multiSelect,
  dropdown,
  toggle,
  switch_,
  tagSelect,
  tagInput,
  
  // Display components
  titleText,
  descriptionText,
  image,
  progressIndicator,
  
  // Layout components
  groupContainer,
  tabs,
  stepIndicator,
  
  // Logic components
  conditional, // Deprecated - use ifBlock/elseBlock instead
  ifBlock,
  elseBlock,
  elseIfBlock,
  forLoop,
  whileLoop,
  variableAssignment,
  variableTransform,
  
  // Integration components
  apiCall,
  fileOperation,
  dataTransform,
  jsonParser,
  csvParser,
  
  // Advanced UI components
  fileUpload,
  imageDisplay,
  markdown,
  codeEditor,
  chartDisplay,
  
  // Prompt components
  roleDefinition,
  contextProvider,
  taskDescription,
  text,
  exampleProvider,
  
  // Special component - always at the end of workflow
  finalPromptBuilder,
}

/// Variable definition
class VariableDefinition {
  final String name;
  final VariableType type;
  final dynamic defaultValue;
  final String? description;

  VariableDefinition({
    required this.name,
    required this.type,
    this.defaultValue,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.toString().split('.').last,
      'defaultValue': defaultValue,
      'description': description,
    };
  }

  factory VariableDefinition.fromJson(Map<String, dynamic> json) {
    return VariableDefinition(
      name: json['name'],
      type: VariableType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
      ),
      defaultValue: json['defaultValue'],
      description: json['description'],
    );
  }
}

/// Variable types
enum VariableType {
  string,
  number,
  boolean,
  date,
  list,
  map,
}

/// Validation rule for components
class ValidationRule {
  final ValidationType type;
  final Map<String, dynamic> parameters;
  final String? errorMessage;

  ValidationRule({
    required this.type,
    required this.parameters,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'parameters': parameters,
      'errorMessage': errorMessage,
    };
  }

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      type: ValidationType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
      ),
      parameters: json['parameters'],
      errorMessage: json['errorMessage'],
    );
  }
}

/// Validation types
enum ValidationType {
  required,
  minLength,
  maxLength,
  pattern,
  range,
  custom,
}

/// Screen transition definition
class ScreenTransition {
  final String targetScreenId;
  final TransitionType type;
  final String? condition;

  ScreenTransition({
    required this.targetScreenId,
    required this.type,
    this.condition,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetScreenId': targetScreenId,
      'type': type.toString().split('.').last,
      'condition': condition,
    };
  }

  factory ScreenTransition.fromJson(Map<String, dynamic> json) {
    return ScreenTransition(
      targetScreenId: json['targetScreenId'],
      type: TransitionType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
      ),
      condition: json['condition'],
    );
  }
}

/// Transition types
enum TransitionType {
  next,
  conditional,
  completion,
}

/// Screen action definition
class ScreenAction {
  final String label;
  final ActionType type;
  final Map<String, dynamic> parameters;

  ScreenAction({
    required this.label,
    required this.type,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'type': type.toString().split('.').last,
      'parameters': parameters,
    };
  }

  factory ScreenAction.fromJson(Map<String, dynamic> json) {
    return ScreenAction(
      label: json['label'],
      type: ActionType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
      ),
      parameters: json['parameters'],
    );
  }
}

/// Action types
enum ActionType {
  navigate,
  submit,
  validate,
  reset,
}

/// Prompt template definition
class PromptTemplate {
  final List<PromptSection> sections;
  final String assemblyLogic;
  final AssemblyMode assemblyMode;

  PromptTemplate({
    required this.sections,
    required this.assemblyLogic,
    this.assemblyMode = AssemblyMode.sequential,
  });

  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((s) => s.toJson()).toList(),
      'assemblyLogic': assemblyLogic,
      'assemblyMode': assemblyMode.toString().split('.').last,
    };
  }

  factory PromptTemplate.fromJson(Map<String, dynamic> json) {
    return PromptTemplate(
      sections: (json['sections'] as List)
          .map((s) => PromptSection.fromJson(s))
          .toList(),
      assemblyLogic: json['assemblyLogic'],
      assemblyMode: json['assemblyMode'] != null
          ? AssemblyMode.values.firstWhere(
              (m) => m.toString().split('.').last == json['assemblyMode'],
              orElse: () => AssemblyMode.sequential,
            )
          : AssemblyMode.sequential,
    );
  }
}

/// Prompt section definition
class PromptSection {
  final String id;
  final PromptSectionType type;
  final String content;
  final String? condition;
  final int order;

  PromptSection({
    required this.id,
    required this.type,
    required this.content,
    this.condition,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'content': content,
      'condition': condition,
      'order': order,
    };
  }

  factory PromptSection.fromJson(Map<String, dynamic> json) {
    return PromptSection(
      id: json['id'],
      type: PromptSectionType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
      ),
      content: json['content'],
      condition: json['condition'],
      order: json['order'],
    );
  }
}

/// Prompt section types
enum PromptSectionType {
  role,
  context,
  task,
  constraints,
  examples,
  format,
  custom,
}

/// Simplified section types for editor
enum SectionType {
  role,
  task,
  content,
}

/// Assembly mode for prompt sections
enum AssemblyMode {
  sequential,
  numbered,
  bulleted,
}