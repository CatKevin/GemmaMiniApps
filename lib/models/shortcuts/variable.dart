// Import VariableType from shortcut_definition.dart to avoid duplicate definition
import 'shortcut_definition.dart' show VariableType;

/// Runtime variable model for storing actual values
class Variable {
  final String id;
  final String name;
  final VariableType type;
  final dynamic value;
  final String? description;
  final VariableSource source;
  final DateTime? lastUpdated;

  Variable({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.description,
    required this.source,
    this.lastUpdated,
  });

  Variable copyWith({
    String? id,
    String? name,
    VariableType? type,
    dynamic value,
    String? description,
    VariableSource? source,
    DateTime? lastUpdated,
  }) {
    return Variable(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      description: description ?? this.description,
      source: source ?? this.source,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'value': value,
      'description': description,
      'source': source.toString().split('.').last,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory Variable.fromJson(Map<String, dynamic> json) {
    return Variable(
      id: json['id'],
      name: json['name'],
      type: VariableType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
      ),
      value: json['value'],
      description: json['description'],
      source: VariableSource.values.firstWhere(
        (s) => s.toString().split('.').last == json['source'],
      ),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }
}

/// Variable source indicates where the variable value comes from
enum VariableSource {
  userInput,     // From user input components
  system,        // System-generated (e.g., timestamp, device info)
  calculated,    // Calculated from other variables
  constant,      // Constant value defined by the shortcut
}

/// Extension for user-friendly display names
extension VariableTypeExtension on VariableType {
  String get displayName {
    switch (this) {
      case VariableType.string:
        return 'Text';
      case VariableType.number:
        return 'Number';
      case VariableType.boolean:
        return 'Boolean';
      case VariableType.date:
        return 'Date';
      case VariableType.list:
        return 'List';
      case VariableType.map:
        return 'Object';
    }
  }
  
  dynamic get defaultValue {
    switch (this) {
      case VariableType.string:
        return '';
      case VariableType.number:
        return 0;
      case VariableType.boolean:
        return false;
      case VariableType.date:
        return DateTime.now();
      case VariableType.list:
        return [];
      case VariableType.map:
        return {};
    }
  }
}

extension VariableSourceExtension on VariableSource {
  String get displayName {
    switch (this) {
      case VariableSource.userInput:
        return 'User Input';
      case VariableSource.system:
        return 'System';
      case VariableSource.calculated:
        return 'Calculated';
      case VariableSource.constant:
        return 'Constant';
    }
  }
}