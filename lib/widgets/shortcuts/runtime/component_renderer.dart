import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/models/theme_config.dart';
import '../../../models/shortcuts/models.dart';

/// Factory for rendering UI components dynamically
class ComponentRenderer {
  static Widget render({
    required UIComponent component,
    required ExecutionContext context,
    required Function(String, dynamic) onValueChanged,
    required ThemeConfig theme,
  }) {
    switch (component.type) {
      // Input Components
      case ComponentType.textInput:
        return _TextInputComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.multilineTextInput:
        return _MultilineTextInputComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.numberInput:
        return _NumberInputComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.dateTimePicker:
        return _DateTimePickerComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.slider:
        return _SliderComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      // Selection Components
      case ComponentType.singleSelect:
        return _SingleSelectComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.multiSelect:
        return _MultiSelectComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.dropdown:
        return _DropdownComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.toggle:
        return _ToggleComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.tagSelect:
        return _TagSelectComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      // Display Components
      case ComponentType.titleText:
        return _TitleTextComponent(
          component: component,
          context: context,
          theme: theme,
        );

      case ComponentType.descriptionText:
        return _DescriptionTextComponent(
          component: component,
          context: context,
          theme: theme,
        );

      case ComponentType.image:
        return _ImageComponent(
          component: component,
          context: context,
          theme: theme,
        );

      case ComponentType.progressIndicator:
        return _ProgressIndicatorComponent(
          component: component,
          context: context,
          theme: theme,
        );

      // Layout Components
      case ComponentType.groupContainer:
        return _GroupContainerComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.tabs:
        return _TabsComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.stepIndicator:
        return _StepIndicatorComponent(
          component: component,
          context: context,
          theme: theme,
        );

      // Logic Components
      case ComponentType.conditional:
        return _ConditionalComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.variableAssignment:
        return _VariableAssignmentComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      case ComponentType.variableTransform:
        return _VariableTransformComponent(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );

      // Prompt Components
      case ComponentType.roleDefinition:
      case ComponentType.contextProvider:
      case ComponentType.taskDescription:
      case ComponentType.textTemplate:
      case ComponentType.exampleProvider:
        return _PromptComponent(
          component: component,
          context: context,
          theme: theme,
        );

      default:
        return _UnknownComponent(
          component: component,
          theme: theme,
        );
    }
  }

  /// Check if component should be displayed based on conditional display
  static bool shouldDisplay(UIComponent component, ExecutionContext context) {
    if (component.conditionalDisplay == null) return true;
    return context.evaluateCondition(component.conditionalDisplay!);
  }
}

/// Text input component
class _TextInputComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _TextInputComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(
      text: this.context.getVariable(component.variableBinding ?? '') ?? '',
    );

    final label = component.properties['label'] ?? 'Input';
    final placeholder = component.properties['placeholder'] ?? '';
    final maxLength = component.properties['maxLength'] as int?;
    final required = component.properties['required'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          onChanged: (value) {
            if (component.variableBinding != null) {
              onValueChanged(component.variableBinding!, value);
            }
          },
          style: TextStyle(color: theme.inputText),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: theme.inputHint.withValues(alpha: theme.hintOpacity),
            ),
            filled: true,
            fillColor: theme.inputBackground,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.inputBorder.withValues(alpha: theme.borderOpacity),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.inputBorderFocused
                    .withValues(alpha: theme.borderOpacityFocused),
              ),
            ),
            counterText: '',
          ),
        ),
        if (component.validation?.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              component.validation!.errorMessage!,
              style: TextStyle(
                color: theme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// Multiline text input component
class _MultilineTextInputComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _MultilineTextInputComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(
      text: this.context.getVariable(component.variableBinding ?? '') ?? '',
    );

    final label = component.properties['label'] ?? 'Input';
    final placeholder = component.properties['placeholder'] ?? '';
    final rows = component.properties['rows'] ?? 4;
    final maxLength = component.properties['maxLength'] as int?;
    final required = component.properties['required'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: rows as int,
          maxLength: maxLength,
          onChanged: (value) {
            if (component.variableBinding != null) {
              onValueChanged(component.variableBinding!, value);
            }
          },
          style: TextStyle(color: theme.inputText),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: theme.inputHint.withValues(alpha: theme.hintOpacity),
            ),
            filled: true,
            fillColor: theme.inputBackground,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.inputBorder.withValues(alpha: theme.borderOpacity),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.inputBorderFocused
                    .withValues(alpha: theme.borderOpacityFocused),
              ),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// Number input component
class _NumberInputComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _NumberInputComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final value = useState<num?>(
      this.context.getVariable(component.variableBinding ?? '') as num?,
    );

    final label = component.properties['label'] ?? 'Number';
    final min = component.properties['min'] as num? ?? 0;
    final max = component.properties['max'] as num? ?? 100;
    final step = component.properties['step'] as num? ?? 1;
    final required = component.properties['required'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: theme.primary),
              onPressed: () {
                final newValue = (value.value ?? min) - step;
                if (newValue >= min) {
                  value.value = newValue;
                  if (component.variableBinding != null) {
                    onValueChanged(component.variableBinding!, newValue);
                  }
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: useTextEditingController(
                  text: value.value?.toString() ?? '',
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (text) {
                  final newValue = num.tryParse(text);
                  if (newValue != null && newValue >= min && newValue <= max) {
                    value.value = newValue;
                    if (component.variableBinding != null) {
                      onValueChanged(component.variableBinding!, newValue);
                    }
                  }
                },
                style: TextStyle(color: theme.inputText),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.inputBackground,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.inputBorder
                          .withValues(alpha: theme.borderOpacity),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.inputBorderFocused
                          .withValues(alpha: theme.borderOpacityFocused),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: theme.primary),
              onPressed: () {
                final newValue = (value.value ?? min) + step;
                if (newValue <= max) {
                  value.value = newValue;
                  if (component.variableBinding != null) {
                    onValueChanged(component.variableBinding!, newValue);
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Min: $min, Max: $max',
          style: TextStyle(
            color: theme.onBackground.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Date time picker component
class _DateTimePickerComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _DateTimePickerComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDate = useState<DateTime?>(
      this.context.getVariable(component.variableBinding ?? '') as DateTime?,
    );

    final label = component.properties['label'] ?? 'Date';
    final required = component.properties['required'] ?? false;
    final includeTime = component.properties['includeTime'] ?? false;

    Future<void> selectDate() async {
      final date = await showDatePicker(
        context: context,
        initialDate: selectedDate.value ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (date != null) {
        if (includeTime && context.mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime:
                TimeOfDay.fromDateTime(selectedDate.value ?? DateTime.now()),
          );

          if (time != null) {
            selectedDate.value = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          }
        } else {
          selectedDate.value = date;
        }

        if (component.variableBinding != null && selectedDate.value != null) {
          onValueChanged(component.variableBinding!, selectedDate.value!);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.inputBorder.withValues(alpha: theme.borderOpacity),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate.value != null
                        ? _formatDate(selectedDate.value!, includeTime)
                        : 'Select date${includeTime ? ' and time' : ''}',
                    style: TextStyle(
                      color: selectedDate.value != null
                          ? theme.inputText
                          : theme.inputHint
                              .withValues(alpha: theme.hintOpacity),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, bool includeTime) {
    if (includeTime) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Slider component
class _SliderComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _SliderComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final value = useState<double>(
      (this.context.getVariable(component.variableBinding ?? '') as num?)
              ?.toDouble() ??
          0.0,
    );

    final label = component.properties['label'] ?? 'Value';
    final min = (component.properties['min'] as num? ?? 0).toDouble();
    final max = (component.properties['max'] as num? ?? 100).toDouble();
    final divisions = component.properties['divisions'] as int?;
    final showValue = component.properties['showValue'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.onBackground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showValue)
              Text(
                value.value.toStringAsFixed(1),
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.primary,
            inactiveTrackColor: theme.inputBorder.withValues(alpha: 0.2),
            thumbColor: theme.primary,
            overlayColor: theme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (newValue) {
              value.value = newValue;
              if (component.variableBinding != null) {
                onValueChanged(component.variableBinding!, newValue);
              }
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              min.toString(),
              style: TextStyle(
                color: theme.onBackground.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            Text(
              max.toString(),
              style: TextStyle(
                color: theme.onBackground.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Single select component (radio buttons)
class _SingleSelectComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _SingleSelectComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = useState<String?>(
      this.context.getVariable(component.variableBinding ?? '') as String?,
    );

    final label = component.properties['label'] ?? 'Select';
    final options = component.properties['options'] as List<dynamic>? ?? [];
    final required = component.properties['required'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          final optionValue = option.toString();
          return RadioListTile<String>(
            title: Text(
              optionValue,
              style: TextStyle(color: theme.onBackground),
            ),
            value: optionValue,
            groupValue: selectedValue.value,
            activeColor: theme.primary,
            onChanged: (value) {
              selectedValue.value = value;
              if (component.variableBinding != null && value != null) {
                onValueChanged(component.variableBinding!, value);
              }
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }),
      ],
    );
  }
}

/// Multi select component (checkboxes)
class _MultiSelectComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _MultiSelectComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValues = useState<List<String>>(
      (this.context.getVariable(component.variableBinding ?? '')
                  as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );

    final label = component.properties['label'] ?? 'Select';
    final options = component.properties['options'] as List<dynamic>? ?? [];
    final minSelection = component.properties['minSelection'] as int? ?? 0;
    final maxSelection = component.properties['maxSelection'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (minSelection > 0 || maxSelection != null)
          Text(
            'Select ${minSelection > 0 ? 'at least $minSelection' : ''}'
            '${minSelection > 0 && maxSelection != null ? ' and ' : ''}'
            '${maxSelection != null ? 'up to $maxSelection' : ''}',
            style: TextStyle(
              color: theme.onBackground.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        const SizedBox(height: 8),
        ...options.map((option) {
          final optionValue = option.toString();
          final isSelected = selectedValues.value.contains(optionValue);

          return CheckboxListTile(
            title: Text(
              optionValue,
              style: TextStyle(color: theme.onBackground),
            ),
            value: isSelected,
            activeColor: theme.primary,
            onChanged: (checked) {
              if (checked ?? false) {
                if (maxSelection == null ||
                    selectedValues.value.length < maxSelection) {
                  selectedValues.value = [...selectedValues.value, optionValue];
                }
              } else {
                selectedValues.value = selectedValues.value
                    .where((v) => v != optionValue)
                    .toList();
              }

              if (component.variableBinding != null) {
                onValueChanged(
                    component.variableBinding!, selectedValues.value);
              }
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }),
      ],
    );
  }
}

/// Dropdown component
class _DropdownComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _DropdownComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = useState<String?>(
      this.context.getVariable(component.variableBinding ?? '') as String?,
    );

    final label = component.properties['label'] ?? 'Select';
    final options = component.properties['options'] as List<dynamic>? ?? [];
    final placeholder =
        component.properties['placeholder'] ?? 'Choose an option';
    final required = component.properties['required'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.inputBorder.withValues(alpha: theme.borderOpacity),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue.value,
              isExpanded: true,
              hint: Text(
                placeholder,
                style: TextStyle(
                  color: theme.inputHint.withValues(alpha: theme.hintOpacity),
                ),
              ),
              icon: Icon(Icons.arrow_drop_down, color: theme.primary),
              style: TextStyle(color: theme.inputText),
              dropdownColor: theme.surface,
              onChanged: (value) {
                selectedValue.value = value;
                if (component.variableBinding != null && value != null) {
                  onValueChanged(component.variableBinding!, value);
                }
              },
              items: options.map((option) {
                final optionValue = option.toString();
                return DropdownMenuItem<String>(
                  value: optionValue,
                  child: Text(optionValue),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Toggle component
class _ToggleComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _ToggleComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = useState<bool>(
      this.context.getVariable(component.variableBinding ?? '') as bool? ??
          false,
    );

    final label = component.properties['label'] ?? 'Toggle';
    final description = component.properties['description'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.onBackground.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: isOn.value,
            onChanged: (value) {
              isOn.value = value;
              if (component.variableBinding != null) {
                onValueChanged(component.variableBinding!, value);
              }
            },
            activeColor: theme.primary,
            inactiveThumbColor: theme.inputBorder,
            inactiveTrackColor: theme.inputBorder.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

/// Tag select component
class _TagSelectComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _TagSelectComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTags = useState<List<String>>(
      (this.context.getVariable(component.variableBinding ?? '')
                  as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );

    final label = component.properties['label'] ?? 'Tags';
    final options = component.properties['options'] as List<dynamic>? ?? [];
    final maxSelection = component.properties['maxSelection'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final optionValue = option.toString();
            final isSelected = selectedTags.value.contains(optionValue);

            return FilterChip(
              label: Text(optionValue),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  if (maxSelection == null ||
                      selectedTags.value.length < maxSelection) {
                    selectedTags.value = [...selectedTags.value, optionValue];
                  }
                } else {
                  selectedTags.value = selectedTags.value
                      .where((t) => t != optionValue)
                      .toList();
                }

                if (component.variableBinding != null) {
                  onValueChanged(
                      component.variableBinding!, selectedTags.value);
                }
              },
              backgroundColor: theme.surface,
              selectedColor: theme.primary,
              labelStyle: TextStyle(
                color: isSelected ? theme.onPrimary : theme.onSurface,
              ),
              checkmarkColor: theme.onPrimary,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Title text component
class _TitleTextComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final ThemeConfig theme;

  const _TitleTextComponent({
    required this.component,
    required this.context,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final text = _interpolateText(
      component.properties['text'] ?? 'Title',
      this.context,
    );
    final size = component.properties['size'] ?? 'medium';

    double fontSize;
    switch (size) {
      case 'large':
        fontSize = 24;
        break;
      case 'small':
        fontSize = 16;
        break;
      default:
        fontSize = 20;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: theme.onBackground,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }

  String _interpolateText(String template, ExecutionContext context) {
    // Simple variable interpolation: replace {{variable}} with value
    return template.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) {
        final variableName = match.group(1)!;
        final value = context.getVariable(variableName);
        return value?.toString() ?? '';
      },
    );
  }
}

/// Description text component
class _DescriptionTextComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final ThemeConfig theme;

  const _DescriptionTextComponent({
    required this.component,
    required this.context,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final text = _interpolateText(
      component.properties['text'] ?? 'Description',
      this.context,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          color: theme.onBackground.withValues(alpha: 0.8),
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  String _interpolateText(String template, ExecutionContext context) {
    return template.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) {
        final variableName = match.group(1)!;
        final value = context.getVariable(variableName);
        return value?.toString() ?? '';
      },
    );
  }
}

/// Image component
class _ImageComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final ThemeConfig theme;

  const _ImageComponent({
    required this.component,
    required this.context,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final source = component.properties['source'] ?? '';
    final width = component.properties['width'] as double?;
    final height = component.properties['height'] as double?;

    // For now, just show a placeholder
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: theme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Image: $source',
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
}

/// Progress indicator component
class _ProgressIndicatorComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final ThemeConfig theme;

  const _ProgressIndicatorComponent({
    required this.component,
    required this.context,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final progress = component.properties['progress'] as double? ?? 0.0;
    final label = component.properties['label'] as String?;
    final showPercentage = component.properties['showPercentage'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              color: theme.onBackground,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.inputBorder.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          minHeight: 8,
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: theme.onBackground.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Group container component
class _GroupContainerComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _GroupContainerComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final title = component.properties['title'] as String?;
    final childComponents =
        component.properties['children'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // TODO: Render child components
          Text(
            'Group with ${childComponents.length} components',
            style: TextStyle(
              color: theme.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tabs component
class _TabsComponent extends HookWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _TabsComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = component.properties['tabs'] as List<dynamic>? ?? [];
    final selectedIndex = useState(0);

    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value as Map<String, dynamic>;
              final isSelected = selectedIndex.value == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => selectedIndex.value = index,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tab['label'] ?? 'Tab ${index + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? theme.onPrimary : theme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // TODO: Render tab content
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Tab ${selectedIndex.value + 1} content',
            style: TextStyle(color: theme.onSurface),
          ),
        ),
      ],
    );
  }
}

/// Step indicator component
class _StepIndicatorComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final ThemeConfig theme;

  const _StepIndicatorComponent({
    required this.component,
    required this.context,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final steps = component.properties['steps'] as List<dynamic>? ?? [];
    final currentStep = component.properties['currentStep'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          // final step = entry.value.toString(); // Currently unused
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isActive || isCompleted ? theme.primary : theme.surface,
                    border: Border.all(
                      color: isActive || isCompleted
                          ? theme.primary
                          : theme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: theme.onPrimary,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color:
                                  isActive ? theme.onPrimary : theme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 1,
                      color: isCompleted
                          ? theme.primary
                          : theme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Conditional component
class _ConditionalComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _ConditionalComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final condition = component.properties['condition'] as String? ?? '';
    final isTrue = this.context.evaluateCondition(condition);
    final trueComponents =
        component.properties['trueComponents'] as List<dynamic>? ?? [];
    final falseComponents =
        component.properties['falseComponents'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.alt_route,
                size: 16,
                color: theme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'If: $condition',
                style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 16),
          padding: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: theme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TODO: Render conditional components
              Text(
                isTrue
                    ? 'Showing ${trueComponents.length} components (condition is true)'
                    : 'Showing ${falseComponents.length} components (condition is false)',
                style: TextStyle(
                  color: theme.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Variable assignment component
class _VariableAssignmentComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _VariableAssignmentComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final variableName = component.properties['variableName'] as String? ?? '';
    final value = component.properties['value'];

    // Execute the assignment
    if (variableName.isNotEmpty && value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onValueChanged(variableName, value);
      });
    }

    // This component is invisible to the user
    return const SizedBox.shrink();
  }
}

/// Variable transform component
class _VariableTransformComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;

  const _VariableTransformComponent({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final sourceVariable =
        component.properties['sourceVariable'] as String? ?? '';
    final targetVariable =
        component.properties['targetVariable'] as String? ?? '';
    final transformType =
        component.properties['transformType'] as String? ?? '';

    // Execute the transformation
    if (sourceVariable.isNotEmpty && targetVariable.isNotEmpty) {
      final sourceValue = this.context.getVariable(sourceVariable);
      if (sourceValue != null) {
        final transformedValue = _transform(sourceValue, transformType);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onValueChanged(targetVariable, transformedValue);
        });
      }
    }

    // This component is invisible to the user
    return const SizedBox.shrink();
  }

  dynamic _transform(dynamic value, String transformType) {
    // Simple transformations
    switch (transformType) {
      case 'uppercase':
        return value.toString().toUpperCase();
      case 'lowercase':
        return value.toString().toLowerCase();
      case 'trim':
        return value.toString().trim();
      case 'length':
        return value.toString().length;
      default:
        return value;
    }
  }
}

/// Prompt component (for all prompt-related components)
class _PromptComponent extends StatelessWidget {
  final UIComponent component;
  final ExecutionContext context;
  final ThemeConfig theme;

  const _PromptComponent({
    required this.component,
    required this.context,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Prompt components are not visible during runtime
    // They are used only during prompt generation
    return const SizedBox.shrink();
  }
}

/// Unknown component fallback
class _UnknownComponent extends StatelessWidget {
  final UIComponent component;
  final ThemeConfig theme;

  const _UnknownComponent({
    required this.component,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: theme.error,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Unknown component type',
            style: TextStyle(
              color: theme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type: ${component.type.toString().split('.').last}',
            style: TextStyle(
              color: theme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
