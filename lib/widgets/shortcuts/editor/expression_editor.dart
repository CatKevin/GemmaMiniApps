import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../core/theme/models/theme_config.dart';
import '../../../models/shortcuts/models.dart';

class ExpressionEditor extends HookWidget {
  final String initialValue;
  final Function(String) onChanged;
  final Map<String, VariableDefinition> availableVariables;
  final String label;
  final String? hint;
  
  const ExpressionEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.availableVariables,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialValue);
    final selectedVariable = useState<String?>(null);
    final selectedOperator = useState<String>('==');
    final valueController = useTextEditingController();
    final showHelper = useState(false);
    
    // Parse existing expression
    useEffect(() {
      if (initialValue.isNotEmpty) {
        final parts = initialValue.split(' ');
        if (parts.length >= 3) {
          selectedVariable.value = parts[0];
          selectedOperator.value = parts[1];
          valueController.text = parts.sublist(2).join(' ');
        }
      }
      return null;
    }, []);
    
    // Check if operator requires a value
    bool requiresValue(String operator) {
      return !['isEmpty', 'isNotEmpty', 'isNull', 'isNotNull', 'isTrue', 'isFalse'].contains(operator);
    }

    // Update expression when components change
    void updateExpression() {
      if (selectedVariable.value != null) {
        String expression;
        if (requiresValue(selectedOperator.value)) {
          if (valueController.text.isNotEmpty) {
            expression = '${selectedVariable.value} ${selectedOperator.value} ${valueController.text}';
          } else {
            return; // Don't update if value is required but empty
          }
        } else {
          // For operators that don't require a value
          expression = '${selectedVariable.value} ${selectedOperator.value}';
        }
        controller.text = expression;
        onChanged(expression);
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            color: context.theme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        
        // Expression builder
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.theme.onSurface.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Variable selector
              DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedVariable.value,
                      decoration: InputDecoration(
                        labelText: 'Variable',
                        labelStyle: TextStyle(
                          color: context.theme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: context.theme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: context.theme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: context.theme.primary,
                          ),
                        ),
                      ),
                      dropdownColor: context.theme.surface,
                      style: TextStyle(
                        color: context.theme.onSurface,
                        fontSize: 14,
                      ),
                      items: availableVariables.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(
                                _getVariableIcon(entry.value.type),
                                size: 16,
                                color: context.theme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(entry.key),
                              const SizedBox(width: 4),
                              Text(
                                '(${_getVariableTypeLabel(entry.value.type)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.theme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedVariable.value = value;
                        updateExpression();
                      },
                    ),
              const SizedBox(height: 8),
              // Operator selector in a new row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedOperator.value,
                      decoration: InputDecoration(
                        labelText: 'Operator',
                        labelStyle: TextStyle(
                          color: context.theme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: context.theme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: context.theme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: context.theme.primary,
                          ),
                        ),
                      ),
                      dropdownColor: context.theme.surface,
                      style: TextStyle(
                        color: context.theme.onSurface,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      items: _getOperators().map((op) {
                        return DropdownMenuItem(
                          value: op['value'] as String,
                          child: Text(
                            op['label'] as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedOperator.value = value!;
                        // Clear value if operator doesn't require it
                        if (!requiresValue(value)) {
                          valueController.clear();
                        }
                        updateExpression();
                      },
                    ),
                  ),
                ],
              ),
              // Value input (only show if operator requires a value)
              if (requiresValue(selectedOperator.value)) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: valueController,
                  onChanged: (value) {
                    updateExpression();
                  },
                  style: TextStyle(
                    color: context.theme.onSurface,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Value',
                    labelStyle: TextStyle(
                      color: context.theme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    hintText: _getValueHint(selectedVariable.value),
                    hintStyle: TextStyle(
                      color: context.theme.onSurface.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: context.theme.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: context.theme.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: context.theme.primary,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.help_outline,
                        size: 20,
                        color: context.theme.onSurface.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        showHelper.value = !showHelper.value;
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Raw expression display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.theme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expression:',
                      style: TextStyle(
                        color: context.theme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.text.isEmpty ? 'No condition set' : controller.text,
                      style: TextStyle(
                        color: context.theme.onSurface,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Helper text
              if (showHelper.value) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expression Examples:',
                        style: TextStyle(
                          color: context.theme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._getExamples().map((example) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          example,
                          style: TextStyle(
                            color: context.theme.onSurface.withValues(alpha: 0.8),
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Advanced mode button
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            _showAdvancedEditor(context, controller, onChanged);
          },
          icon: Icon(
            Icons.code,
            size: 16,
            color: context.theme.primary,
          ),
          label: Text(
            'Advanced Mode',
            style: TextStyle(
              color: context.theme.primary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showAdvancedEditor(BuildContext context, TextEditingController controller, Function(String) onChanged) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Advanced Expression Editor'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your expression manually:',
                  style: TextStyle(
                    color: context.theme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  onChanged: onChanged,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., age >= 18 && hasConsent == true',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Supported operators:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '==, !=, >, <, >=, <=, contains, isEmpty, isNotEmpty',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: context.theme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('DONE'),
            ),
          ],
        );
      },
    );
  }
  
  IconData _getVariableIcon(VariableType type) {
    switch (type) {
      case VariableType.string:
        return Icons.text_fields;
      case VariableType.number:
        return Icons.numbers;
      case VariableType.boolean:
        return Icons.toggle_on;
      case VariableType.list:
        return Icons.list;
      case VariableType.map:
        return Icons.data_object;
      case VariableType.date:
        return Icons.calendar_today;
    }
  }
  
  String _getVariableTypeLabel(VariableType type) {
    switch (type) {
      case VariableType.string:
        return 'text';
      case VariableType.number:
        return 'number';
      case VariableType.boolean:
        return 'yes/no';
      case VariableType.list:
        return 'list';
      case VariableType.map:
        return 'map';
      case VariableType.date:
        return 'date';
    }
  }
  
  String? _getValueHint(String? variableName) {
    if (variableName == null) return null;
    
    final variable = availableVariables[variableName];
    if (variable == null) return null;
    
    switch (variable.type) {
      case VariableType.string:
        return 'e.g., "Hello World"';
      case VariableType.number:
        return 'e.g., 42';
      case VariableType.boolean:
        return 'true or false';
      case VariableType.list:
        return 'e.g., item1,item2';
      case VariableType.map:
        return 'e.g., {"key": "value"}';
      case VariableType.date:
        return 'e.g., 2024-01-01';
    }
  }
  
  List<Map<String, String>> _getOperators() {
    return [
      {'value': '==', 'label': '=='},
      {'value': '!=', 'label': '!='},
      {'value': '>', 'label': '>'},
      {'value': '<', 'label': '<'},
      {'value': '>=', 'label': '>='},
      {'value': '<=', 'label': '<='},
      {'value': 'contains', 'label': 'contains'},
      {'value': 'startsWith', 'label': 'starts with'},
      {'value': 'endsWith', 'label': 'ends with'},
      {'value': 'isEmpty', 'label': 'is empty'},
      {'value': 'isNotEmpty', 'label': 'is not empty'},
      {'value': 'isNull', 'label': 'is null'},
      {'value': 'isNotNull', 'label': 'is not null'},
      {'value': 'isTrue', 'label': 'is true'},
      {'value': 'isFalse', 'label': 'is false'},
    ];
  }
  
  List<String> _getExamples() {
    return [
      '• age > 18',
      '• name == "John"',
      '• email contains "@gmail.com"',
      '• message isEmpty',
      '• username isNotEmpty',
      '• score >= 80',
      '• isActive isTrue',
      '• result isNull',
    ];
  }
}

extension on BuildContext {
  ThemeConfig get theme => ThemeController.to.currentThemeConfig;
}