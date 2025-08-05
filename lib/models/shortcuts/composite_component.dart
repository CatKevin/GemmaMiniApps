import 'shortcut_definition.dart';
import 'editor_models.dart';

/// Enum for composite component types
enum CompositeComponentType {
  ifElse,      // IF-ELSE structure
  switchCase,  // SWITCH-CASE structure
  forEach,     // FOR-EACH loop
  whileLoop,   // WHILE loop
  tryError,    // TRY-CATCH error handling
}

/// Enum for section types within composite components
enum CompositeSectionType {
  condition,    // Condition part (IF, SWITCH, etc.)
  branch,       // Branch part (THEN, ELSE, CASE, etc.)
  terminator,   // End part (END IF, END SWITCH, etc.)
  caseOption,   // CASE option in SWITCH
  default_,     // DEFAULT branch
  catch_,       // CATCH block
  finally_,     // FINALLY block
}

/// Base class for composite components
abstract class CompositeComponent {
  final String id;
  final CompositeComponentType type;
  final List<ComponentSection> sections;
  final bool isStructureLocked = true; // Structure parts cannot be dragged

  CompositeComponent({
    required this.id,
    required this.type,
    required this.sections,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson();

  /// Create from JSON
  factory CompositeComponent.fromJson(Map<String, dynamic> json) {
    final type = CompositeComponentType.values.firstWhere(
      (t) => t.toString() == json['type'],
    );

    switch (type) {
      case CompositeComponentType.ifElse:
        return IfElseComponent.fromJson(json);
      case CompositeComponentType.switchCase:
        return SwitchCaseComponent.fromJson(json);
      default:
        throw UnimplementedError('Composite component type $type not implemented');
    }
  }

  /// Convert to editable component
  EditableComponent toEditableComponent() {
    return EditableComponent(
      id: id,
      component: UIComponent(
        id: id,
        type: ComponentType.groupContainer, // Use group as base type
        properties: {
          'compositeType': type.toString(),
          'sections': sections.map((s) => s.toJson()).toList(),
        },
      ),
      order: 0,
      isComposite: true,
      compositeComponent: this,
    );
  }
}

/// Component section within a composite component
class ComponentSection {
  final String id;
  final String label;
  final CompositeSectionType type;
  final bool isDraggable = false; // Structure sections cannot be dragged
  final List<EditableComponent> children;
  final Map<String, dynamic> properties;

  ComponentSection({
    required this.id,
    required this.label,
    required this.type,
    List<EditableComponent>? children,
    Map<String, dynamic>? properties,
  })  : children = children ?? [],
        properties = properties ?? {};

  ComponentSection copyWith({
    String? id,
    String? label,
    CompositeSectionType? type,
    List<EditableComponent>? children,
    Map<String, dynamic>? properties,
  }) {
    return ComponentSection(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      children: children ?? this.children,
      properties: properties ?? this.properties,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.toString(),
      'isDraggable': isDraggable,
      'children': children.map((c) => c.toJson()).toList(),
      'properties': properties,
    };
  }

  factory ComponentSection.fromJson(Map<String, dynamic> json) {
    return ComponentSection(
      id: json['id'],
      label: json['label'],
      type: CompositeSectionType.values.firstWhere(
        (t) => t.toString() == json['type'],
      ),
      children: (json['children'] as List?)
              ?.map((c) => EditableComponent.fromJson(c))
              .toList() ??
          [],
      properties: json['properties'] ?? {},
    );
  }
}

/// IF-ELSE composite component
class IfElseComponent extends CompositeComponent {
  String conditionExpression;

  IfElseComponent({
    required String id,
    String? conditionExpression,
    List<ComponentSection>? customSections,
  })  : conditionExpression = conditionExpression ?? '',
        super(
          id: id,
          type: CompositeComponentType.ifElse,
          sections: customSections ?? _createDefaultSections(id),
        );

  static List<ComponentSection> _createDefaultSections(String id) {
    return [
      ComponentSection(
        id: '${id}_if',
        label: 'IF',
        type: CompositeSectionType.condition,
        properties: {'expression': ''},
      ),
      ComponentSection(
        id: '${id}_then',
        label: 'THEN',
        type: CompositeSectionType.branch,
      ),
      ComponentSection(
        id: '${id}_else',
        label: 'ELSE',
        type: CompositeSectionType.branch,
      ),
      ComponentSection(
        id: '${id}_endif',
        label: 'END IF',
        type: CompositeSectionType.terminator,
      ),
    ];
  }

  /// Add ELSE IF branch
  void addElseIf(String? condition) {
    final elseIfSection = ComponentSection(
      id: '${id}_elseif_${DateTime.now().millisecondsSinceEpoch}',
      label: 'ELSE IF',
      type: CompositeSectionType.branch,
      properties: {'expression': condition ?? ''},
    );
    // Insert before ELSE section
    sections.insert(sections.length - 2, elseIfSection);
  }

  /// Remove ELSE IF branch
  void removeElseIf(String sectionId) {
    sections.removeWhere((s) => s.id == sectionId && s.label == 'ELSE IF');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'conditionExpression': conditionExpression,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }

  factory IfElseComponent.fromJson(Map<String, dynamic> json) {
    return IfElseComponent(
      id: json['id'],
      conditionExpression: json['conditionExpression'],
      customSections: (json['sections'] as List?)
          ?.map((s) => ComponentSection.fromJson(s))
          .toList(),
    );
  }
}

/// SWITCH-CASE composite component
class SwitchCaseComponent extends CompositeComponent {
  String switchVariable;
  List<String> caseOptions;

  SwitchCaseComponent({
    required String id,
    required this.switchVariable,
    required this.caseOptions,
  }) : super(
          id: id,
          type: CompositeComponentType.switchCase,
          sections: _buildSections(id, switchVariable, caseOptions),
        );

  static List<ComponentSection> _buildSections(
    String id,
    String switchVariable,
    List<String> options,
  ) {
    final sections = <ComponentSection>[];

    // MENU header
    sections.add(ComponentSection(
      id: '${id}_switch',
      label: 'MENU',
      type: CompositeSectionType.condition,
      properties: {'variable': switchVariable},
    ));

    // Dynamic CASE branches
    for (final option in options) {
      sections.add(ComponentSection(
        id: '${id}_case_${option.hashCode}',
        label: 'CASE "$option"',
        type: CompositeSectionType.caseOption,
        properties: {'value': option},
      ));
    }

    // DEFAULT branch
    sections.add(ComponentSection(
      id: '${id}_default',
      label: 'DEFAULT',
      type: CompositeSectionType.default_,
    ));

    // END MENU
    sections.add(ComponentSection(
      id: '${id}_endswitch',
      label: 'END MENU',
      type: CompositeSectionType.terminator,
    ));

    return sections;
  }

  /// Add new CASE
  void addCase(String option) {
    if (caseOptions.contains(option)) return;

    final caseSection = ComponentSection(
      id: '${id}_case_${option.hashCode}',
      label: 'CASE "$option"',
      type: CompositeSectionType.caseOption,
      properties: {'value': option},
    );
    
    // Insert before DEFAULT section
    sections.insert(sections.length - 2, caseSection);
    caseOptions.add(option);
  }

  /// Remove CASE
  void removeCase(String option) {
    sections.removeWhere((s) => s.id == '${id}_case_${option.hashCode}');
    caseOptions.remove(option);
  }
  
  /// Rename a CASE option without losing its child components
  void renameCase(int index, String newName) {
    if (index < 0 || index >= caseOptions.length) return;
    if (newName.isEmpty || caseOptions.contains(newName)) return;
    
    final oldName = caseOptions[index];
    
    // Find the corresponding section
    final sectionIndex = sections.indexWhere(
      (s) => s.id == '${id}_case_${oldName.hashCode}'
    );
    
    if (sectionIndex != -1) {
      // Create a new section with updated properties, preserving children
      final oldSection = sections[sectionIndex];
      final newProperties = Map<String, dynamic>.from(oldSection.properties);
      newProperties['value'] = newName;
      
      final newSection = oldSection.copyWith(
        id: '${id}_case_${newName.hashCode}',
        label: 'CASE "$newName"',
        properties: newProperties,
      );
      
      // Replace the old section with the new one
      sections[sectionIndex] = newSection;
      
      // Update the caseOptions list
      caseOptions[index] = newName;
    }
  }

  /// Update cases based on menu options
  void updateCases(List<String> newOptions) {
    // Remove cases that are no longer in options
    final toRemove = caseOptions.where((c) => !newOptions.contains(c)).toList();
    for (final option in toRemove) {
      removeCase(option);
    }

    // Add new cases
    final toAdd = newOptions.where((o) => !caseOptions.contains(o)).toList();
    for (final option in toAdd) {
      addCase(option);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'switchVariable': switchVariable,
      'caseOptions': caseOptions,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }

  factory SwitchCaseComponent.fromJson(Map<String, dynamic> json) {
    final component = SwitchCaseComponent(
      id: json['id'],
      switchVariable: json['switchVariable'],
      caseOptions: List<String>.from(json['caseOptions']),
    );
    
    // Restore sections with their children
    if (json['sections'] != null) {
      component.sections.clear();
      for (final sectionJson in json['sections']) {
        component.sections.add(ComponentSection.fromJson(sectionJson));
      }
    }
    
    return component;
  }
}

/// Menu selector component that can link to SWITCH-CASE
class MenuSelectorComponent extends UIComponent {
  static const ComponentType componentType = ComponentType.dropdown;
  
  MenuSelectorComponent({
    required String id,
    required String label,
    required List<Map<String, String>> options,
    String? variableBinding,
    bool enableDynamicCase = false,
  }) : super(
          id: id,
          type: componentType,
          properties: {
            'label': label,
            'options': options,
            'enableDynamicCase': enableDynamicCase,
          },
          variableBinding: variableBinding,
        );

  List<Map<String, String>> get options => 
      (properties['options'] as List).cast<Map<String, String>>();

  bool get enableDynamicCase => properties['enableDynamicCase'] ?? false;

  /// Get option values for SWITCH-CASE
  List<String> getOptionValues() {
    return options.map((o) => o['value'] ?? '').toList();
  }

  /// Update options
  void updateOptions(List<Map<String, String>> newOptions) {
    properties['options'] = newOptions;
  }
}

/// Component relationship for smart linking
class ComponentRelationship {
  final String sourceId;
  final String targetId;
  final RelationType type;

  ComponentRelationship({
    required this.sourceId,
    required this.targetId,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
      'type': type.toString(),
    };
  }

  factory ComponentRelationship.fromJson(Map<String, dynamic> json) {
    return ComponentRelationship(
      sourceId: json['sourceId'],
      targetId: json['targetId'],
      type: RelationType.values.firstWhere(
        (t) => t.toString() == json['type'],
      ),
    );
  }
}

enum RelationType {
  dataFlow,     // Data flow direction
  conditional,  // Conditional relationship
  switchCase,   // Switch-Case relationship
  sequential,   // Sequential execution
}