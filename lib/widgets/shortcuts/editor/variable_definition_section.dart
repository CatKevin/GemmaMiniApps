import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/variable.dart';
import '../../../models/shortcuts/shortcut_definition.dart' show VariableType;
import 'components/variable_definition_component.dart';

class VariableDefinitionSection extends HookWidget {
  final List<Variable> variables;
  final Function(Variable) onAddVariable;
  final Function(Variable) onUpdateVariable;
  final Function(String) onDeleteVariable;
  final Function(String) onVariableSelected;

  const VariableDefinitionSection({
    super.key,
    required this.variables,
    required this.onAddVariable,
    required this.onUpdateVariable,
    required this.onDeleteVariable,
    required this.onVariableSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final isExpanded = useState(true); // 默认展开
    final showDefinitionDialog = useState(false);
    final editingVariable = useState<Variable?>(null);
    
    // Show variable definition dialog
    if (showDefinitionDialog.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: VariableDefinitionComponent(
              initialVariable: editingVariable.value,
              onSave: (variable) {
                Navigator.of(context).pop(); // 先关闭对话框
                if (editingVariable.value != null) {
                  onUpdateVariable(variable);
                } else {
                  onAddVariable(variable);
                }
                showDefinitionDialog.value = false;
                editingVariable.value = null;
              },
              onCancel: () {
                Navigator.of(context).pop(); // 先关闭对话框
                showDefinitionDialog.value = false;
                editingVariable.value = null;
              },
            ),
          ),
        );
      });
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              isExpanded.value = !isExpanded.value;
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(
                  bottom: BorderSide(
                    color: theme.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.data_object,
                      color: theme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Variable Definitions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: theme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Define variables to use in your workflow',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme.onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${variables.length} variables',
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
          
          // Content
          if (isExpanded.value)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Variables list
                  if (variables.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.code_off,
                            size: 48,
                            color: theme.onSurface.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No variables defined yet',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: theme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Click the button below to add your first variable',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: variables.map((variable) => _buildVariableChip(
                        variable: variable,
                        theme: theme,
                        context: context,
                        onEdit: () {
                          editingVariable.value = variable;
                          showDefinitionDialog.value = true;
                        },
                        onDelete: () => _confirmDelete(variable),
                        onSelect: () => onVariableSelected(variable.id),
                      )).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Add variable button
                  OutlinedButton.icon(
                    onPressed: () {
                      editingVariable.value = null;
                      showDefinitionDialog.value = true;
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Variable'),
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
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildVariableChip({
    required Variable variable,
    required dynamic theme,
    required BuildContext context,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showVariableMenu(
          context: context,
          variable: variable,
          theme: theme,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTypeIcon(variable.type),
              size: 16,
              color: theme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              variable.name,
              style: TextStyle(
                color: theme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${variable.type.displayName})',
              style: TextStyle(
                color: theme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showVariableMenu({
    required BuildContext context,
    required Variable variable,
    required dynamic theme,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    variable.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: theme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (variable.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      variable.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit, color: theme.onSurface),
              title: const Text('Edit Variable'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.error),
              title: Text('Delete Variable', style: TextStyle(color: theme.error)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDelete(Variable variable) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Variable'),
        content: Text(
          'Are you sure you want to delete "${variable.name}"? '
          'Components using this variable may be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onDeleteVariable(variable.id);
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
  
  IconData _getTypeIcon(VariableType type) {
    switch (type) {
      case VariableType.string:
        return Icons.text_fields;
      case VariableType.number:
        return Icons.numbers;
      case VariableType.boolean:
        return Icons.toggle_on;
      case VariableType.date:
        return Icons.calendar_today;
      case VariableType.list:
        return Icons.list;
      case VariableType.map:
        return Icons.data_object;
    }
  }
}