/// Runtime execution context for a Shortcut
class ExecutionContext {
  final String shortcutId;
  String currentScreenId;
  final Map<String, dynamic> variables;
  final List<String> navigationHistory;
  final DateTime startTime;
  
  ExecutionContext({
    required this.shortcutId,
    required this.currentScreenId,
    Map<String, dynamic>? variables,
    List<String>? navigationHistory,
    DateTime? startTime,
  })  : variables = variables ?? {},
        navigationHistory = navigationHistory ?? [],
        startTime = startTime ?? DateTime.now();

  /// Set a variable value
  void setVariable(String name, dynamic value) {
    variables[name] = value;
  }

  /// Get a variable value
  dynamic getVariable(String name) {
    return variables[name];
  }

  /// Check if a variable exists
  bool hasVariable(String name) {
    return variables.containsKey(name);
  }

  /// Navigate to a new screen
  void navigateToScreen(String screenId) {
    navigationHistory.add(currentScreenId);
    currentScreenId = screenId;
  }

  /// Go back to previous screen
  bool navigateBack() {
    if (navigationHistory.isNotEmpty) {
      currentScreenId = navigationHistory.removeLast();
      return true;
    }
    return false;
  }

  /// Evaluate a condition expression
  bool evaluateCondition(String condition) {
    if (condition.isEmpty) return true; // Empty condition is always true
    
    // Handle complex conditions with && and ||
    if (condition.contains('&&')) {
      final subConditions = condition.split('&&').map((s) => s.trim()).toList();
      return subConditions.every((subCondition) => _evaluateSimpleCondition(subCondition));
    }
    
    if (condition.contains('||')) {
      final subConditions = condition.split('||').map((s) => s.trim()).toList();
      return subConditions.any((subCondition) => _evaluateSimpleCondition(subCondition));
    }
    
    return _evaluateSimpleCondition(condition);
  }
  
  bool _evaluateSimpleCondition(String condition) {
    // Handle parentheses by removing them
    condition = condition.trim();
    if (condition.startsWith('(') && condition.endsWith(')')) {
      condition = condition.substring(1, condition.length - 1).trim();
    }
    
    // Parse the condition
    final parts = _parseCondition(condition);
    if (parts == null) return false;
    
    final variableName = parts['variable']!;
    final operator = parts['operator']!;
    final expectedValue = parts['value']!;
    
    final actualValue = getVariable(variableName);

    switch (operator) {
      case '==':
        return _compareValues(actualValue, expectedValue);
      case '!=':
        return !_compareValues(actualValue, expectedValue);
      case '>':
        return _compareNumeric(actualValue, expectedValue, (a, b) => a > b);
      case '<':
        return _compareNumeric(actualValue, expectedValue, (a, b) => a < b);
      case '>=':
        return _compareNumeric(actualValue, expectedValue, (a, b) => a >= b);
      case '<=':
        return _compareNumeric(actualValue, expectedValue, (a, b) => a <= b);
      case 'contains':
        return actualValue.toString().toLowerCase().contains(expectedValue.toLowerCase());
      case 'isEmpty':
        return actualValue == null || 
               actualValue.toString().isEmpty ||
               (actualValue is List && actualValue.isEmpty);
      case 'isNotEmpty':
        return actualValue != null && 
               (actualValue.toString().isNotEmpty ||
                (actualValue is List && actualValue.isNotEmpty));
      default:
        return false;
    }
  }
  
  Map<String, String>? _parseCondition(String condition) {
    // List of operators from longest to shortest to avoid partial matches
    final operators = ['isNotEmpty', 'isEmpty', 'contains', '>=', '<=', '!=', '==', '>', '<'];
    
    for (final op in operators) {
      final index = condition.indexOf(' $op ');
      if (index > 0 || (op == 'isEmpty' || op == 'isNotEmpty')) {
        if (op == 'isEmpty' || op == 'isNotEmpty') {
          // Special case for unary operators
          final parts = condition.split(' ');
          if (parts.length >= 2 && parts.last == op) {
            return {
              'variable': parts.first,
              'operator': op,
              'value': '',
            };
          }
        } else {
          // Binary operators
          final parts = condition.split(' $op ');
          if (parts.length == 2) {
            return {
              'variable': parts[0].trim(),
              'operator': op,
              'value': _stripQuotes(parts[1].trim()),
            };
          }
        }
      }
    }
    
    return null;
  }
  
  String _stripQuotes(String value) {
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
  
  bool _compareValues(dynamic actual, String expected) {
    // Handle null
    if (actual == null) {
      return expected.toLowerCase() == 'null' || expected.isEmpty;
    }
    
    // Handle boolean
    if (expected.toLowerCase() == 'true' || expected.toLowerCase() == 'false') {
      final expectedBool = expected.toLowerCase() == 'true';
      if (actual is bool) {
        return actual == expectedBool;
      }
      return actual.toString().toLowerCase() == expected.toLowerCase();
    }
    
    // Handle numbers
    final expectedNum = num.tryParse(expected);
    if (expectedNum != null && actual is num) {
      return actual == expectedNum;
    }
    
    // String comparison
    return actual.toString() == expected;
  }

  bool _compareNumeric(
    dynamic actual,
    String expected,
    bool Function(num, num) comparator,
  ) {
    try {
      final actualNum = num.parse(actual.toString());
      final expectedNum = num.parse(expected);
      return comparator(actualNum, expectedNum);
    } catch (e) {
      return false;
    }
  }

  /// Get execution duration
  Duration get executionDuration => DateTime.now().difference(startTime);

  /// Clone the context
  ExecutionContext clone() {
    return ExecutionContext(
      shortcutId: shortcutId,
      currentScreenId: currentScreenId,
      variables: Map.from(variables),
      navigationHistory: List.from(navigationHistory),
      startTime: startTime,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'shortcutId': shortcutId,
      'currentScreenId': currentScreenId,
      'variables': variables,
      'navigationHistory': navigationHistory,
      'startTime': startTime.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ExecutionContext.fromJson(Map<String, dynamic> json) {
    return ExecutionContext(
      shortcutId: json['shortcutId'],
      currentScreenId: json['currentScreenId'],
      variables: Map<String, dynamic>.from(json['variables'] ?? {}),
      navigationHistory: List<String>.from(json['navigationHistory'] ?? []),
      startTime: DateTime.parse(json['startTime']),
    );
  }
}

/// Variable transformer for processing values
class VariableTransformer {
  /// Transform a variable value based on transformation type
  static dynamic transform(dynamic value, TransformationType type,
      [Map<String, dynamic>? parameters]) {
    switch (type) {
      case TransformationType.uppercase:
        return value.toString().toUpperCase();
      case TransformationType.lowercase:
        return value.toString().toLowerCase();
      case TransformationType.trim:
        return value.toString().trim();
      case TransformationType.join:
        if (value is List) {
          final separator = parameters?['separator'] ?? ', ';
          return value.join(separator);
        }
        return value;
      case TransformationType.split:
        final separator = parameters?['separator'] ?? ',';
        return value.toString().split(separator).map((s) => s.trim()).toList();
      case TransformationType.format:
        final template = parameters?['template'] ?? '{value}';
        return template.replaceAll('{value}', value.toString());
      case TransformationType.parseNumber:
        return num.tryParse(value.toString()) ?? 0;
      case TransformationType.parseBoolean:
        final strValue = value.toString().toLowerCase();
        return strValue == 'true' || strValue == '1' || strValue == 'yes';
      case TransformationType.dateFormat:
        if (value is DateTime) {
          // Simple date formatting
          return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
        }
        return value;
      case TransformationType.custom:
        // Custom transformation logic can be added here
        return value;
    }
  }
}

/// Transformation types
enum TransformationType {
  uppercase,
  lowercase,
  trim,
  join,
  split,
  format,
  parseNumber,
  parseBoolean,
  dateFormat,
  custom,
}

/// Execution result after running a Shortcut
class ExecutionResult {
  final String shortcutId;
  final String generatedPrompt;
  final Map<String, dynamic> collectedVariables;
  final Duration executionTime;
  final bool completed;
  final String? error;

  ExecutionResult({
    required this.shortcutId,
    required this.generatedPrompt,
    required this.collectedVariables,
    required this.executionTime,
    required this.completed,
    this.error,
  });

  bool get hasError => error != null;

  Map<String, dynamic> toJson() {
    return {
      'shortcutId': shortcutId,
      'generatedPrompt': generatedPrompt,
      'collectedVariables': collectedVariables,
      'executionTime': executionTime.inMilliseconds,
      'completed': completed,
      'error': error,
    };
  }

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    return ExecutionResult(
      shortcutId: json['shortcutId'],
      generatedPrompt: json['generatedPrompt'],
      collectedVariables: Map<String, dynamic>.from(json['collectedVariables']),
      executionTime: Duration(milliseconds: json['executionTime']),
      completed: json['completed'],
      error: json['error'],
    );
  }
}