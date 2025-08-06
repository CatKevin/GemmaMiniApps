import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/variable.dart';
import '../../../models/shortcuts/shortcut_definition.dart' show VariableType;

class EnhancedVariableSelector extends HookWidget {
  final String? currentValue;
  final List<Variable> availableVariables;
  final Function(String?) onVariableSelected;
  final Function(Variable) onCreateVariable;
  final String? componentLabel;
  final VariableType? suggestedType;
  final bool allowNull;

  const EnhancedVariableSelector({
    super.key,
    this.currentValue,
    required this.availableVariables,
    required this.onVariableSelected,
    required this.onCreateVariable,
    this.componentLabel,
    this.suggestedType,
    this.allowNull = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final isDropdownOpen = useState(false);
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final hoveredIndex = useState(-1);
    final showCreateDialog = useState(false);
    
    // Filter variables based on search
    final filteredVariables = useMemoized(() {
      if (searchQuery.value.isEmpty) return availableVariables;
      final query = searchQuery.value.toLowerCase();
      return availableVariables.where((v) => 
        v.name.toLowerCase().contains(query) ||
        (v.description?.toLowerCase().contains(query) ?? false)
      ).toList();
    }, [availableVariables, searchQuery.value]);
    
    // Get current variable
    Variable? currentVariable;
    try {
      currentVariable = availableVariables.firstWhere((v) => v.name == currentValue);
    } catch (e) {
      currentVariable = null;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main selector button
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            isDropdownOpen.value = !isDropdownOpen.value;
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDropdownOpen.value 
                    ? theme.primary 
                    : theme.onSurface.withValues(alpha: 0.2),
                width: isDropdownOpen.value ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (currentVariable != null) ...[
                  // Show selected variable
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getTypeIcon(currentVariable.type),
                      size: 16,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentVariable.name,
                          style: TextStyle(
                            color: theme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (currentVariable.description != null)
                          Text(
                            currentVariable.description!,
                            style: TextStyle(
                              color: theme.onSurface.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.add_circle_outline,
                    color: theme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select or create variable',
                      style: TextStyle(
                        color: theme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
                AnimatedRotation(
                  turns: isDropdownOpen.value ? 0.5 : 0,
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
        
        // Dropdown panel
        if (isDropdownOpen.value)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.onSurface.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: TextStyle(color: theme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search variables...',
                      hintStyle: TextStyle(
                        color: theme.onSurface.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
                
                // Create new variable option
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    isDropdownOpen.value = false;
                    showCreateDialog.value = true;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.05),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add,
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
                                'Create New Variable',
                                style: TextStyle(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (componentLabel != null)
                                Text(
                                  'Based on "$componentLabel"',
                                  style: TextStyle(
                                    color: theme.primary.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: theme.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Clear selection option (if allowed)
                if (allowNull && currentValue != null)
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onVariableSelected(null);
                      isDropdownOpen.value = false;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.clear,
                            color: theme.onSurface.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Clear Selection',
                            style: TextStyle(
                              color: theme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Variable list
                Expanded(
                  child: filteredVariables.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: theme.onSurface.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No variables found',
                                  style: TextStyle(
                                    color: theme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try creating a new one',
                                  style: TextStyle(
                                    color: theme.onSurface.withValues(alpha: 0.3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: filteredVariables.length,
                          itemBuilder: (context, index) {
                            final variable = filteredVariables[index];
                            final isSelected = variable.name == currentValue;
                            final isHovered = hoveredIndex.value == index;
                            
                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onVariableSelected(variable.name);
                                isDropdownOpen.value = false;
                              },
                              onHover: (hover) {
                                if (hover) {
                                  hoveredIndex.value = index;
                                } else if (hoveredIndex.value == index) {
                                  hoveredIndex.value = -1;
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.primary.withValues(alpha: 0.1)
                                      : isHovered
                                          ? theme.onSurface.withValues(alpha: 0.05)
                                          : null,
                                  border: Border(
                                    left: BorderSide(
                                      color: isSelected
                                          ? theme.primary
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.background,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getTypeIcon(variable.type),
                                        size: 20,
                                        color: isSelected
                                            ? theme.primary
                                            : theme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                variable.name,
                                                style: TextStyle(
                                                  color: theme.onSurface,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.onSurface.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  variable.type.displayName,
                                                  style: TextStyle(
                                                    color: theme.onSurface.withValues(alpha: 0.6),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (variable.description != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              variable.description!,
                                              style: TextStyle(
                                                color: theme.onSurface.withValues(alpha: 0.5),
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        color: theme.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
        // Inline variable creation dialog
        if (showCreateDialog.value)
          _buildInlineVariableCreator(
            context: context,
            theme: theme,
            onClose: () => showCreateDialog.value = false,
            onCreate: (variable) {
              onCreateVariable(variable);
              onVariableSelected(variable.name);
              showCreateDialog.value = false;
            },
          ),
      ],
    );
  }
  
  Widget _buildInlineVariableCreator({
    required BuildContext context,
    required dynamic theme,
    required VoidCallback onClose,
    required Function(Variable) onCreate,
  }) {
    final nameController = useTextEditingController(
      text: _generateVariableName(componentLabel),
    );
    final descriptionController = useTextEditingController();
    final selectedType = useState<VariableType>(suggestedType ?? VariableType.string);
    final nameError = useState<String?>(null);
    
    void createVariable() {
      // Validate name
      if (nameController.text.trim().isEmpty) {
        nameError.value = 'Variable name is required';
        return;
      }
      
      final validNameRegex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
      if (!validNameRegex.hasMatch(nameController.text.trim())) {
        nameError.value = 'Invalid format. Use letters, numbers, and underscores';
        return;
      }
      
      // Check if variable already exists
      if (availableVariables.any((v) => v.name == nameController.text.trim())) {
        nameError.value = 'Variable name already exists';
        return;
      }
      
      // Create variable
      final variable = Variable(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        type: selectedType.value,
        value: selectedType.value.defaultValue,
        description: descriptionController.text.trim().isEmpty 
            ? null 
            : descriptionController.text.trim(),
        source: VariableSource.userInput,
        lastUpdated: DateTime.now(),
      );
      
      onCreate(variable);
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Variable Creation',
                style: TextStyle(
                  color: theme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: theme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Variable name
          TextField(
            controller: nameController,
            autofocus: true,
            style: TextStyle(color: theme.onSurface),
            decoration: InputDecoration(
              labelText: 'Variable Name',
              labelStyle: TextStyle(
                color: theme.onSurface.withValues(alpha: 0.6),
              ),
              hintText: 'e.g., userName',
              hintStyle: TextStyle(
                color: theme.onSurface.withValues(alpha: 0.3),
              ),
              errorText: nameError.value,
              filled: true,
              fillColor: theme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.primary,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.text_fields,
                color: theme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            onChanged: (_) => nameError.value = null,
            onSubmitted: (_) => createVariable(),
          ),
          
          const SizedBox(height: 12),
          
          // Variable type selector
          Wrap(
            spacing: 8,
            children: [
              VariableType.string,
              VariableType.number,
              VariableType.boolean,
              VariableType.date,
            ].map((type) {
              final isSelected = selectedType.value == type;
              return InkWell(
                onTap: () => selectedType.value = type,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primary
                        : theme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? theme.primary
                          : theme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        size: 16,
                        color: isSelected
                            ? theme.onPrimary
                            : theme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          color: isSelected
                              ? theme.onPrimary
                              : theme.onSurface,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Description (optional)
          TextField(
            controller: descriptionController,
            style: TextStyle(color: theme.onSurface, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              labelStyle: TextStyle(
                color: theme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              hintText: 'What is this variable for?',
              hintStyle: TextStyle(
                color: theme.onSurface.withValues(alpha: 0.3),
                fontSize: 12,
              ),
              filled: true,
              fillColor: theme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.primary,
                  width: 2,
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(
                  foregroundColor: theme.onSurface.withValues(alpha: 0.6),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: createVariable,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create & Use'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _generateVariableName(String? label) {
    if (label == null || label.isEmpty) return '';
    
    // Convert label to camelCase variable name
    final words = label.split(RegExp(r'[\s\-_]+'));
    if (words.isEmpty) return '';
    
    String name = words.first.toLowerCase();
    for (int i = 1; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        name += words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
      }
    }
    
    // Remove non-alphanumeric characters
    name = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    
    // Ensure it starts with a letter
    if (name.isNotEmpty && !RegExp(r'^[a-zA-Z]').hasMatch(name)) {
      name = 'var$name';
    }
    
    return name;
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
      case VariableType.imageList:
        return Icons.image;
    }
  }
}

