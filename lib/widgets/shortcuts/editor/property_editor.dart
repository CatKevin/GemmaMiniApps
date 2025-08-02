import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../core/theme/models/theme_config.dart';
import '../../../models/shortcuts/models.dart';
import 'rich_text_field.dart';
import 'expression_editor.dart';

class ComponentPropertyEditor extends HookWidget {
  final UIComponent component;
  final ComponentTemplate template;
  final Function(String key, dynamic value) onPropertyChanged;
  final Map<String, VariableDefinition> availableVariables;
  
  const ComponentPropertyEditor({
    super.key,
    required this.component,
    required this.template,
    required this.onPropertyChanged,
    required this.availableVariables,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...template.editableProperties.map((property) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPropertyField(context, property),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildPropertyField(BuildContext context, ComponentProperty property) {
    final theme = ThemeController.to.currentThemeConfig;
    
    switch (property.type) {
      case PropertyType.text:
        return _buildTextField(property, theme);
      case PropertyType.number:
        return _buildNumberField(property, theme);
      case PropertyType.boolean:
        return _buildBooleanField(property, theme);
      case PropertyType.select:
        return _buildSelectField(property, theme);
      case PropertyType.multiSelect:
        return _buildMultiSelectField(property, theme);
      case PropertyType.variable:
        return _buildVariableField(property, theme);
      case PropertyType.expression:
        return _buildExpressionField(property, theme);
      case PropertyType.richText:
        return _buildRichTextField(context, property, theme);
    }
  }
  
  Widget _buildTextField(ComponentProperty property, ThemeConfig theme) {
    final controller = useTextEditingController(
      text: component.properties[property.key]?.toString() ?? property.defaultValue?.toString() ?? '',
    );
    
    return TextField(
      controller: controller,
      onChanged: (value) => onPropertyChanged(property.key, value),
      style: TextStyle(color: theme.onSurface),
      decoration: InputDecoration(
        labelText: property.label,
        labelStyle: TextStyle(
          color: theme.onSurface.withValues(alpha: 0.6),
        ),
        hintText: property.defaultValue?.toString() ?? '',
        hintStyle: TextStyle(
          color: theme.onSurface.withValues(alpha: 0.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.primary,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
  
  Widget _buildNumberField(ComponentProperty property, ThemeConfig theme) {
    final controller = useTextEditingController(
      text: component.properties[property.key]?.toString() ?? property.defaultValue?.toString() ?? '',
    );
    
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final numValue = num.tryParse(value);
        if (numValue != null) {
          onPropertyChanged(property.key, numValue);
        }
      },
      style: TextStyle(color: theme.onSurface),
      decoration: InputDecoration(
        labelText: property.label,
        labelStyle: TextStyle(
          color: theme.onSurface.withValues(alpha: 0.6),
        ),
        hintText: property.defaultValue?.toString() ?? '',
        hintStyle: TextStyle(
          color: theme.onSurface.withValues(alpha: 0.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.primary,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
  
  Widget _buildBooleanField(ComponentProperty property, ThemeConfig theme) {
    final value = component.properties[property.key] ?? property.defaultValue ?? false;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          property.label,
          style: TextStyle(
            color: theme.onSurface,
            fontSize: 14,
          ),
        ),
        Switch(
          value: value,
          onChanged: (newValue) => onPropertyChanged(property.key, newValue),
          activeColor: theme.primary,
          inactiveThumbColor: theme.onSurface.withValues(alpha: 0.3),
          inactiveTrackColor: theme.onSurface.withValues(alpha: 0.1),
        ),
      ],
    );
  }
  
  Widget _buildSelectField(ComponentProperty property, ThemeConfig theme) {
    final currentValue = component.properties[property.key] ?? property.defaultValue;
    final options = property.options ?? [];
    
    return DropdownButtonFormField<dynamic>(
      value: options.contains(currentValue) ? currentValue : null,
      onChanged: (value) => onPropertyChanged(property.key, value),
      style: TextStyle(color: theme.onSurface),
      dropdownColor: theme.surface,
      decoration: InputDecoration(
        labelText: property.label,
        labelStyle: TextStyle(
          color: theme.onSurface.withValues(alpha: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.primary,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option.toString()),
        );
      }).toList(),
    );
  }
  
  Widget _buildMultiSelectField(ComponentProperty property, ThemeConfig theme) {
    final currentValue = component.properties[property.key] as List<String>? ?? 
                        (property.defaultValue as List<dynamic>?)?.cast<String>() ?? [];
    
    // Create a list of controllers for each option
    final controllers = currentValue.map((value) => 
      useTextEditingController(text: value)
    ).toList();
    
    // Sync controllers when values change
    useEffect(() {
      for (var i = 0; i < controllers.length && i < currentValue.length; i++) {
        if (controllers[i].text != currentValue[i]) {
          controllers[i].text = currentValue[i];
        }
      }
      return null;
    }, [currentValue]);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.label,
          style: TextStyle(
            color: theme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.onSurface.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ...currentValue.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = index < controllers.length 
                    ? controllers[index] 
                    : TextEditingController(text: entry.value);
                
                return Container(
                  key: ValueKey('option_$index'),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: index > 0
                        ? Border(
                            top: BorderSide(
                              color: theme.onSurface.withValues(alpha: 0.1),
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onChanged: (newValue) {
                            final newList = List<String>.from(currentValue);
                            if (index < newList.length) {
                              newList[index] = newValue;
                              onPropertyChanged(property.key, newList);
                            }
                          },
                          style: TextStyle(
                            color: theme.onSurface,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Option ${index + 1}',
                            hintStyle: TextStyle(
                              color: theme.onSurface.withValues(alpha: 0.3),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: theme.error,
                          size: 20,
                        ),
                        onPressed: () {
                          final newList = List<String>.from(currentValue);
                          newList.removeAt(index);
                          onPropertyChanged(property.key, newList);
                        },
                      ),
                    ],
                  ),
                );
              }),
              InkWell(
                onTap: () {
                  final newList = List<String>.from(currentValue);
                  newList.add('Option ${currentValue.length + 1}');
                  onPropertyChanged(property.key, newList);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(7),
                      bottomRight: Radius.circular(7),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: theme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Option',
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildVariableField(ComponentProperty property, ThemeConfig theme) {
    // Check if we're editing variableBinding or a custom variable property
    final isVariableBinding = property.key == 'variableName';
    final currentValue = isVariableBinding 
        ? (component.variableBinding ?? '') 
        : (component.properties[property.key]?.toString() ?? '');
    
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: currentValue),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return availableVariables.keys;
        }
        return availableVariables.keys.where((name) =>
          name.toLowerCase().contains(textEditingValue.text.toLowerCase())
        );
      },
      onSelected: (selection) {
        if (isVariableBinding) {
          onPropertyChanged('variableBinding', selection);
        } else {
          onPropertyChanged(property.key, selection);
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            if (isVariableBinding) {
              onPropertyChanged('variableBinding', value);
            } else {
              onPropertyChanged(property.key, value);
            }
          },
          style: TextStyle(color: theme.onSurface),
          decoration: InputDecoration(
            labelText: property.label,
            labelStyle: TextStyle(
              color: theme.onSurface.withValues(alpha: 0.6),
            ),
            hintText: 'e.g., userName',
            hintStyle: TextStyle(
              color: theme.onSurface.withValues(alpha: 0.3),
            ),
            prefixIcon: Icon(
              Icons.code,
              color: theme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.onSurface.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: TextStyle(
                        color: theme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildExpressionField(ComponentProperty property, ThemeConfig theme) {
    final currentValue = component.properties[property.key]?.toString() ?? '';
    
    return ExpressionEditor(
      initialValue: currentValue,
      onChanged: (value) => onPropertyChanged(property.key, value),
      availableVariables: availableVariables,
      label: property.label,
      hint: 'e.g., age > 18',
    );
  }
  
  Widget _buildRichTextField(BuildContext context, ComponentProperty property, ThemeConfig theme) {
    return RichTextField(
      initialContent: component.properties[property.key]?.toString() ?? '',
      onContentChanged: (content) => onPropertyChanged(property.key, content),
      availableVariables: availableVariables,
      label: property.label,
    );
  }
}