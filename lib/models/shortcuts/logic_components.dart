import 'shortcut_definition.dart';

/// IF component - represents a conditional block
class IfComponent extends UIComponent {
  final String condition;
  final List<UIComponent> children;
  
  IfComponent({
    required String id,
    required this.condition,
    required this.children,
    String? variableBinding,
  }) : super(
    id: id,
    type: ComponentType.ifBlock,
    properties: {
      'condition': condition,
      'children': children.map((c) => c.toJson()).toList(),
    },
    variableBinding: variableBinding,
  );
  
  factory IfComponent.fromUIComponent(UIComponent component) {
    return IfComponent(
      id: component.id,
      condition: component.properties['condition'] ?? '',
      children: (component.properties['children'] as List<dynamic>?)
          ?.map((c) => UIComponent.fromJson(c))
          .toList() ?? [],
      variableBinding: component.variableBinding,
    );
  }
}

/// ELSE component - represents an else block
class ElseComponent extends UIComponent {
  final List<UIComponent> children;
  
  ElseComponent({
    required String id,
    required this.children,
    String? variableBinding,
  }) : super(
    id: id,
    type: ComponentType.elseBlock,
    properties: {
      'children': children.map((c) => c.toJson()).toList(),
    },
    variableBinding: variableBinding,
  );
  
  factory ElseComponent.fromUIComponent(UIComponent component) {
    return ElseComponent(
      id: component.id,
      children: (component.properties['children'] as List<dynamic>?)
          ?.map((c) => UIComponent.fromJson(c))
          .toList() ?? [],
      variableBinding: component.variableBinding,
    );
  }
}

/// ELSE IF component - represents an else-if block
class ElseIfComponent extends UIComponent {
  final String condition;
  final List<UIComponent> children;
  
  ElseIfComponent({
    required String id,
    required this.condition,
    required this.children,
    String? variableBinding,
  }) : super(
    id: id,
    type: ComponentType.elseIfBlock,
    properties: {
      'condition': condition,
      'children': children.map((c) => c.toJson()).toList(),
    },
    variableBinding: variableBinding,
  );
  
  factory ElseIfComponent.fromUIComponent(UIComponent component) {
    return ElseIfComponent(
      id: component.id,
      condition: component.properties['condition'] ?? '',
      children: (component.properties['children'] as List<dynamic>?)
          ?.map((c) => UIComponent.fromJson(c))
          .toList() ?? [],
      variableBinding: component.variableBinding,
    );
  }
}

/// FOR loop component
class ForComponent extends UIComponent {
  final String iteratorVariable;
  final String collection;
  final List<UIComponent> children;
  
  ForComponent({
    required String id,
    required this.iteratorVariable,
    required this.collection,
    required this.children,
    String? variableBinding,
  }) : super(
    id: id,
    type: ComponentType.forLoop,
    properties: {
      'iteratorVariable': iteratorVariable,
      'collection': collection,
      'children': children.map((c) => c.toJson()).toList(),
    },
    variableBinding: variableBinding,
  );
  
  factory ForComponent.fromUIComponent(UIComponent component) {
    return ForComponent(
      id: component.id,
      iteratorVariable: component.properties['iteratorVariable'] ?? 'item',
      collection: component.properties['collection'] ?? '',
      children: (component.properties['children'] as List<dynamic>?)
          ?.map((c) => UIComponent.fromJson(c))
          .toList() ?? [],
      variableBinding: component.variableBinding,
    );
  }
}

/// WHILE loop component
class WhileComponent extends UIComponent {
  final String condition;
  final List<UIComponent> children;
  
  WhileComponent({
    required String id,
    required this.condition,
    required this.children,
    String? variableBinding,
  }) : super(
    id: id,
    type: ComponentType.whileLoop,
    properties: {
      'condition': condition,
      'children': children.map((c) => c.toJson()).toList(),
    },
    variableBinding: variableBinding,
  );
  
  factory WhileComponent.fromUIComponent(UIComponent component) {
    return WhileComponent(
      id: component.id,
      condition: component.properties['condition'] ?? '',
      children: (component.properties['children'] as List<dynamic>?)
          ?.map((c) => UIComponent.fromJson(c))
          .toList() ?? [],
      variableBinding: component.variableBinding,
    );
  }
}