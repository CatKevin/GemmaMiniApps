import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../core/theme/controllers/theme_controller.dart';
import '../../../../models/shortcuts/variable.dart';
import '../../../../models/shortcuts/shortcut_definition.dart' show VariableType;

class VariableDefinitionComponent extends HookWidget {
  final Variable? initialVariable;
  final Function(Variable) onSave;
  final VoidCallback onCancel;

  const VariableDefinitionComponent({
    super.key,
    this.initialVariable,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    // State management
    final nameController = useTextEditingController(
      text: initialVariable?.name ?? '',
    );
    final descriptionController = useTextEditingController(
      text: initialVariable?.description ?? '',
    );
    final selectedType = useState<VariableType>(
      initialVariable?.type ?? VariableType.string,
    );
    final selectedSource = useState<VariableSource>(
      initialVariable?.source ?? VariableSource.userInput,
    );
    final defaultValue = useState<dynamic>(
      initialVariable?.value ?? selectedType.value.defaultValue,
    );
    
    // Validation
    final nameError = useState<String?>(null);
    
    // Update default value when type changes
    useEffect(() {
      if (initialVariable == null) {
        defaultValue.value = selectedType.value.defaultValue;
      }
      return null;
    }, [selectedType.value]);
    
    void validateAndSave() {
      // Validate name
      if (nameController.text.trim().isEmpty) {
        nameError.value = 'Variable name is required';
        return;
      }
      
      // Check for valid variable name format
      final validNameRegex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
      if (!validNameRegex.hasMatch(nameController.text.trim())) {
        nameError.value = 'Invalid name format. Use letters, numbers, and underscores';
        return;
      }
      
      nameError.value = null;
      
      // Create or update variable
      final variable = Variable(
        id: initialVariable?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        type: selectedType.value,
        value: defaultValue.value,
        description: descriptionController.text.trim().isEmpty 
            ? null 
            : descriptionController.text.trim(),
        source: selectedSource.value,
        lastUpdated: DateTime.now(),
      );
      
      onSave(variable);
    }
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: 500,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
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
                  Icons.code_rounded,
                  color: theme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  initialVariable == null ? 'Define Variable' : 'Edit Variable',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Form content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Variable name
                _buildLabel('Variable Name', theme, context),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: theme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'e.g., userName, selectedDate',
                    hintStyle: TextStyle(
                      color: theme.onSurface.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: theme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.primary,
                        width: 2,
                      ),
                    ),
                    errorText: nameError.value,
                    prefixIcon: Icon(
                      Icons.text_fields,
                      color: theme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  onChanged: (_) => nameError.value = null,
                ),
                
                const SizedBox(height: 20),
                
                // Variable type
                _buildLabel('Variable Type', theme, context),
                const SizedBox(height: 8),
                _buildTypeSelector(selectedType, theme, context),
                
                const SizedBox(height: 20),
                
                // Variable source
                _buildLabel('Variable Source', theme, context),
                const SizedBox(height: 8),
                _buildSourceSelector(selectedSource, theme, context),
                
                const SizedBox(height: 20),
                
                // Default value
                _buildLabel('Default Value', theme, context),
                const SizedBox(height: 8),
                _buildDefaultValueInput(
                  selectedType.value, 
                  defaultValue, 
                  theme, 
                  context,
                ),
                
                const SizedBox(height: 20),
                
                // Description
                _buildLabel('Description (Optional)', theme, context),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(color: theme.onSurface),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'What is this variable used for?',
                    hintStyle: TextStyle(
                      color: theme.onSurface.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: theme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.onSurface.withValues(alpha: 0.6),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: validateAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(initialVariable == null ? 'Create' : 'Update'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLabel(String text, dynamic theme, BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: theme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }
  
  Widget _buildTypeSelector(
    ValueNotifier<VariableType> selectedType,
    dynamic theme,
    BuildContext context,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VariableType.values.map((type) {
        final isSelected = selectedType.value == type;
        return InkWell(
          onTap: () => selectedType.value = type,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? theme.primary : theme.background,
              borderRadius: BorderRadius.circular(12),
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
                  color: isSelected ? theme.onPrimary : theme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  type.displayName,
                  style: TextStyle(
                    color: isSelected ? theme.onPrimary : theme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildSourceSelector(
    ValueNotifier<VariableSource> selectedSource,
    dynamic theme,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VariableSource>(
          value: selectedSource.value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          dropdownColor: theme.surface,
          style: TextStyle(color: theme.onSurface),
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.onSurface.withValues(alpha: 0.6),
          ),
          items: VariableSource.values.map((source) {
            return DropdownMenuItem(
              value: source,
              child: Row(
                children: [
                  Icon(
                    _getSourceIcon(source),
                    size: 18,
                    color: theme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(source.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              selectedSource.value = value;
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildDefaultValueInput(
    VariableType type,
    ValueNotifier<dynamic> defaultValue,
    dynamic theme,
    BuildContext context,
  ) {
    switch (type) {
      case VariableType.string:
        return TextField(
          controller: TextEditingController(text: defaultValue.value ?? ''),
          style: TextStyle(color: theme.onSurface),
          decoration: _getInputDecoration('Enter default text', theme),
          onChanged: (value) => defaultValue.value = value,
        );
        
      case VariableType.number:
        return TextField(
          controller: TextEditingController(
            text: defaultValue.value?.toString() ?? '0',
          ),
          style: TextStyle(color: theme.onSurface),
          keyboardType: TextInputType.number,
          decoration: _getInputDecoration('Enter default number', theme),
          onChanged: (value) {
            final num = double.tryParse(value);
            if (num != null) {
              defaultValue.value = num;
            }
          },
        );
        
      case VariableType.boolean:
        return Container(
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: SwitchListTile(
            title: Text(
              defaultValue.value == true ? 'True' : 'False',
              style: TextStyle(color: theme.onSurface),
            ),
            value: defaultValue.value ?? false,
            activeColor: theme.primary,
            onChanged: (value) => defaultValue.value = value,
          ),
        );
        
      case VariableType.date:
        return InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: defaultValue.value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              defaultValue.value = date;
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Text(
                  defaultValue.value != null
                      ? '${(defaultValue.value as DateTime).year}-${(defaultValue.value as DateTime).month.toString().padLeft(2, '0')}-${(defaultValue.value as DateTime).day.toString().padLeft(2, '0')}'
                      : 'Select date',
                  style: TextStyle(
                    color: defaultValue.value != null
                        ? theme.onSurface
                        : theme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        );
        
      case VariableType.list:
      case VariableType.map:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            type == VariableType.list
                ? 'Default: Empty list []'
                : 'Default: Empty object {}',
            style: TextStyle(
              color: theme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        );
        
      case VariableType.imageList:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.image,
                color: theme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Default: No images selected',
                style: TextStyle(
                  color: theme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
    }
  }
  
  InputDecoration _getInputDecoration(String hint, dynamic theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.onSurface.withValues(alpha: 0.4),
      ),
      filled: true,
      fillColor: theme.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.primary,
          width: 2,
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
      case VariableType.imageList:
        return Icons.image;
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