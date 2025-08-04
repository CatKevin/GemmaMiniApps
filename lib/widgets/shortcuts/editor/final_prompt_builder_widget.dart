import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/models/theme_config.dart';
import '../../../models/shortcuts/models.dart';

class FinalPromptBuilderWidget extends HookWidget {
  final EditableComponent component;
  final Function(String key, dynamic value) onPropertyChanged;
  final List<Variable> availableVariables;
  final Function(Variable) onAddVariable;
  final ThemeConfig theme;
  final bool isMinimized;

  const FinalPromptBuilderWidget({
    super.key,
    required this.component,
    required this.onPropertyChanged,
    required this.availableVariables,
    required this.onAddVariable,
    required this.theme,
    this.isMinimized = false,
  });
  
  // Process template with variable substitution
  static String _processTemplate(String template, ExecutionContext context) {
    // Simple variable substitution for preview
    String processed = template.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) {
        final variableName = match.group(1)!;
        final value = context.getVariable(variableName);
        return value?.toString() ?? '{{$variableName}}';
      },
    );
    return processed;
  }

  @override
  Widget build(BuildContext context) {
    // State management
    final isExpanded = useState(!isMinimized);
    final showPreview = useState(component.component.properties['enablePreview'] ?? true);
    final previewVariables = useState<Map<String, dynamic>>(
      Map<String, dynamic>.from(
        component.component.properties['previewVariables'] ?? {}
      )
    );
    
    // Initialize text controller for simplified version
    final textController = useTextEditingController(
      text: component.component.properties['promptTemplate'] as String? ?? ''
    );
    
    // Generate preview
    String generatePreview() {
      final template = textController.text;
      
      // Create sample context with preview variables
      final context = ExecutionContext(
        shortcutId: 'preview',
        currentScreenId: 'preview',
        variables: previewVariables.value,
      );
      
      // Process template with variables
      return _processTemplate(template, context);
    }
    
    // Insert variable
    void insertVariable(String variableName) {
      final text = '{{$variableName}}';
      final selection = textController.selection;
      final value = textController.text;
      
      if (selection.isValid) {
        // Replace selected text
        final newValue = value.replaceRange(
          selection.start,
          selection.end,
          text,
        );
        textController.value = TextEditingValue(
          text: newValue,
          selection: TextSelection.collapsed(offset: selection.start + text.length),
        );
      } else {
        // Append at the end
        textController.text = value + text;
      }
      
      onPropertyChanged('promptTemplate', textController.text);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary.withValues(alpha: 0.05),
            theme.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: () {
              isExpanded.value = !isExpanded.value;
              HapticFeedback.lightImpact();
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Final Prompt Builder',
                              style: TextStyle(
                                color: theme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: theme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'FIXED',
                                    style: TextStyle(
                                      color: theme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isExpanded.value ? 'Build your final prompt with variables' : 'Tap to expand and edit your final prompt',
                          style: TextStyle(
                            color: theme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/Collapse indicator
                  AnimatedRotation(
                    turns: isExpanded.value ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Editor section (collapsible)
          if (isExpanded.value)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Variable selector
                if (availableVariables.isNotEmpty) ...[
                  Text(
                    'Available Variables',
                    style: TextStyle(
                      color: theme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableVariables.map((variable) {
                      return InkWell(
                        onTap: () => insertVariable(variable.name),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.onSurface.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.code,
                                size: 14,
                                color: theme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                variable.name,
                                style: TextStyle(
                                  color: theme.onSurface,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Editor
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        // Editor content (temporarily simplified)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: TextField(
                              controller: textController,
                              maxLines: null,
                              style: TextStyle(
                                color: theme.onSurface,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your prompt here. Use {{variableName}} to insert variables.',
                                hintStyle: TextStyle(
                                  color: theme.onSurface.withValues(alpha: 0.4),
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                onPropertyChanged('promptTemplate', value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Preview section
                if (showPreview.value) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Preview',
                    style: TextStyle(
                      color: theme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      generatePreview(),
                      style: TextStyle(
                        color: theme.onSurface.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  
                  // Preview variables editor
                  if (availableVariables.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Preview Variables (for testing)',
                      style: TextStyle(
                        color: theme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...availableVariables.map((variable) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                variable.name,
                                style: TextStyle(
                                  color: theme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: TextStyle(
                                  color: theme.onSurface,
                                  fontSize: 12,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter test value',
                                  hintStyle: TextStyle(
                                    color: theme.onSurface.withValues(alpha: 0.3),
                                    fontSize: 12,
                                  ),
                                  filled: true,
                                  fillColor: theme.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: theme.onSurface.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: theme.onSurface.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: theme.primary,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  final updated = Map<String, dynamic>.from(previewVariables.value);
                                  updated[variable.name] = value;
                                  previewVariables.value = updated;
                                  onPropertyChanged('previewVariables', updated);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}