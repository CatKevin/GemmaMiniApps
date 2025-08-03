import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/variable.dart';
import '../../../models/shortcuts/shortcut_definition.dart' show VariableType;
import 'components/variable_definition_component.dart';

class VariablePanel extends HookWidget {
  final List<Variable> variables;
  final Function(Variable) onAddVariable;
  final Function(Variable) onUpdateVariable;
  final Function(String) onDeleteVariable;
  final Function(String) onVariableSelected;

  const VariablePanel({
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
    final isExpanded = useState(false);
    final selectedCategory = useState<VariableSource?>(null);
    final searchQuery = useState('');
    final showDefinitionDialog = useState(false);
    final editingVariable = useState<Variable?>(null);
    
    // Filter variables
    final filteredVariables = useMemoized(() {
      var filtered = variables;
      
      // Category filter
      if (selectedCategory.value != null) {
        filtered = filtered.where((v) => v.source == selectedCategory.value).toList();
      }
      
      // Search filter
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        filtered = filtered.where((v) => 
          v.name.toLowerCase().contains(query) ||
          (v.description?.toLowerCase().contains(query) ?? false)
        ).toList();
      }
      
      // Sort by source, then by name
      filtered.sort((a, b) {
        final sourceCompare = a.source.index.compareTo(b.source.index);
        if (sourceCompare != 0) return sourceCompare;
        return a.name.compareTo(b.name);
      });
      
      return filtered;
    }, [variables, selectedCategory.value, searchQuery.value]);
    
    // Group variables by source
    final groupedVariables = useMemoized(() {
      final groups = <VariableSource, List<Variable>>{};
      for (final variable in filteredVariables) {
        groups.putIfAbsent(variable.source, () => []).add(variable);
      }
      return groups;
    }, [filteredVariables]);
    
    return Stack(
      children: [
        // Main panel
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: BoxConstraints(
            minHeight: 61, // 加1像素补偿顶部边框
            maxHeight: isExpanded.value 
                ? MediaQuery.of(context).size.height * 0.5 
                : 61, // 加1像素补偿顶部边框
          ),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border(
              top: BorderSide(
                color: theme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              InkWell(
                onTap: () => isExpanded.value = !isExpanded.value,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.code,
                        color: theme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Variables',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: theme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${variables.length}',
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isExpanded.value) ...[
                        // Search field
                        SizedBox(
                          width: 200,
                          height: 32,
                          child: TextField(
                            style: TextStyle(
                              color: theme.onSurface,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search variables...',
                              hintStyle: TextStyle(
                                color: theme.onSurface.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 16,
                                color: theme.onSurface.withValues(alpha: 0.4),
                              ),
                              filled: true,
                              fillColor: theme.background,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) => searchQuery.value = value,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add variable button
                        IconButton(
                          onPressed: () {
                            editingVariable.value = null;
                            showDefinitionDialog.value = true;
                          },
                          icon: const Icon(Icons.add_circle),
                          color: theme.primary,
                          tooltip: 'Add Variable',
                        ),
                        const SizedBox(width: 8),
                      ],
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
              
              // Expanded content
              if (isExpanded.value)
                Expanded(
                  child: Column(
                    children: [
                      // Category filters
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 40,
                          maxHeight: 40,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryChip(
                              label: 'All',
                              isSelected: selectedCategory.value == null,
                              onTap: () => selectedCategory.value = null,
                              theme: theme,
                              context: context,
                            ),
                            ...VariableSource.values.map((source) {
                              final count = variables.where((v) => v.source == source).length;
                              if (count == 0) return const SizedBox.shrink();
                              
                              return _buildCategoryChip(
                                label: source.displayName,
                                count: count,
                                isSelected: selectedCategory.value == source,
                                onTap: () => selectedCategory.value = source,
                                theme: theme,
                                context: context,
                                icon: _getSourceIcon(source),
                              );
                            }),
                          ],
                        ),
                      ),
                      
                      // Variables list
                      Expanded(
                        child: filteredVariables.isEmpty
                            ? _buildEmptyState(theme, context)
                            : ListView(
                                padding: const EdgeInsets.all(20),
                                children: groupedVariables.entries.map((entry) {
                                  return _buildVariableGroup(
                                    source: entry.key,
                                    variables: entry.value,
                                    theme: theme,
                                    context: context,
                                    onEdit: (variable) {
                                      editingVariable.value = variable;
                                      showDefinitionDialog.value = true;
                                    },
                                    onDelete: onDeleteVariable,
                                    onSelect: onVariableSelected,
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Variable definition dialog
        if (showDefinitionDialog.value)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => showDefinitionDialog.value = false,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping the dialog
                    child: Container(
                      width: 500,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      margin: const EdgeInsets.all(20),
                      child: VariableDefinitionComponent(
                        initialVariable: editingVariable.value,
                        onSave: (variable) {
                          if (editingVariable.value != null) {
                            onUpdateVariable(variable);
                          } else {
                            onAddVariable(variable);
                          }
                          showDefinitionDialog.value = false;
                          editingVariable.value = null;
                        },
                        onCancel: () {
                          showDefinitionDialog.value = false;
                          editingVariable.value = null;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildCategoryChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic theme,
    required BuildContext context,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.primary : theme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? theme.primary 
                  : theme.onSurface.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? theme.onPrimary : theme.onSurface,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.onPrimary : theme.onSurface,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 4),
                Text(
                  '($count)',
                  style: TextStyle(
                    color: (isSelected ? theme.onPrimary : theme.onSurface)
                        .withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(dynamic theme, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code_off,
            size: 48,
            color: theme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No variables defined',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: theme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the + button to add your first variable',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVariableGroup({
    required VariableSource source,
    required List<Variable> variables,
    required dynamic theme,
    required BuildContext context,
    required Function(Variable) onEdit,
    required Function(String) onDelete,
    required Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                _getSourceIcon(source),
                size: 16,
                color: theme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                source.displayName,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: theme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Variables in group
        ...variables.map((variable) => _buildVariableItem(
          variable: variable,
          theme: theme,
          context: context,
          onEdit: onEdit,
          onDelete: onDelete,
          onSelect: onSelect,
        )),
        
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildVariableItem({
    required Variable variable,
    required dynamic theme,
    required BuildContext context,
    required Function(Variable) onEdit,
    required Function(String) onDelete,
    required Function(String) onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () => onSelect(variable.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Type icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(variable.type),
                  size: 18,
                  color: theme.primary,
                ),
              ),
              const SizedBox(width: 12),
              
              // Variable info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          variable.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: theme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            variable.type.displayName,
                            style: TextStyle(
                              color: theme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (variable.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        variable.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 18,
                          color: theme.onSurface.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(
                          Icons.content_copy,
                          size: 18,
                          color: theme.onSurface.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        const Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 18,
                          color: theme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: theme.error),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit(variable);
                      break;
                    case 'duplicate':
                      final duplicate = variable.copyWith(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: '${variable.name}_copy',
                        lastUpdated: DateTime.now(),
                      );
                      onEdit(duplicate);
                      break;
                    case 'delete':
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Delete Variable'),
                          content: Text(
                            'Are you sure you want to delete "${variable.name}"? '
                            'This may affect components using this variable.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back();
                                onDelete(variable.id);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: theme.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      break;
                  }
                },
              ),
            ],
          ),
        ),
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
  
  IconData _getSourceIcon(VariableSource source) {
    switch (source) {
      case VariableSource.userInput:
        return Icons.keyboard;
      case VariableSource.system:
        return Icons.settings;
      case VariableSource.calculated:
        return Icons.calculate;
      case VariableSource.constant:
        return Icons.lock;
    }
  }
}