import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/theme/models/theme_config.dart';
import '../../../models/shortcuts/models.dart';
import '../../../models/shortcuts/composite_component.dart';
import './component_renderer.dart';
import './advanced_ui_theme.dart';
import './safe_opacity.dart';

/// Optimized component renderer with advanced features
class OptimizedComponentRenderer {
  /// Render component with optimizations
  static Widget render(
    UIComponent component,
    ExecutionContext context,
    Function(String, dynamic) onValueChanged,
    ThemeConfig theme,
  ) {
    // Skip variable-only components
    if (_isVariableOnlyComponent(component)) {
      return const SizedBox.shrink();
    }
    
    // Special handling for composite components
    if (component.properties['isComposite'] == true) {
      return _renderComposite(component, context, onValueChanged, theme);
    }
    
    // Enhance normal components
    return _enhancedComponentRender(component, context, onValueChanged, theme);
  }
  
  /// Check if component is variable-only
  static bool _isVariableOnlyComponent(UIComponent component) {
    // Text components with output variables are hidden
    if (component.type == ComponentType.text &&
        component.properties['outputVariable'] != null) {
      return true;
    }
    
    // Other prompt components that should be hidden
    if (component.type == ComponentType.variableAssignment ||
        component.type == ComponentType.variableTransform) {
      return true;
    }
    
    return false;
  }
  
  /// Render composite component with optimizations
  static Widget _renderComposite(
    UIComponent component,
    ExecutionContext context,
    Function(String, dynamic) onValueChanged,
    ThemeConfig theme,
  ) {
    final compositeData = component.properties['compositeData'] as Map<String, dynamic>?;
    if (compositeData == null) {
      return const SizedBox.shrink();
    }
    
    final compositeComponent = CompositeComponent.fromJson(compositeData);
    
    switch (compositeComponent.type) {
      case CompositeComponentType.ifElse:
        return _OptimizedIfElseRenderer(
          component: compositeComponent as IfElseComponent,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );
      case CompositeComponentType.switchCase:
        return _OptimizedSwitchCaseRenderer(
          component: compositeComponent as SwitchCaseComponent,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );
      default:
        return ComponentRenderer.render(
          component: component,
          context: context,
          onValueChanged: onValueChanged,
          theme: theme,
        );
    }
  }
  
  /// Enhanced render for normal components
  static Widget _enhancedComponentRender(
    UIComponent component,
    ExecutionContext context,
    Function(String, dynamic) onValueChanged,
    ThemeConfig theme,
  ) {
    final baseWidget = ComponentRenderer.render(
      component: component,
      context: context,
      onValueChanged: onValueChanged,
      theme: theme,
    );
    
    // Skip enhancement for certain component types
    if (component.type == ComponentType.descriptionText) {
      return baseWidget;
    }
    
    // Add glassmorphic container for input components
    if (_isInputComponent(component)) {
      return AdvancedUITheme.glassmorphicContainer(
        opacity: 0.05,
        blur: 10,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        child: baseWidget,
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: baseWidget,
    );
  }
  
  /// Check if component is an input type
  static bool _isInputComponent(UIComponent component) {
    const inputTypes = {
      ComponentType.textInput,
      ComponentType.multilineTextInput,
      ComponentType.numberInput,
      ComponentType.dateTimePicker,
      ComponentType.slider,
      ComponentType.singleSelect,
      ComponentType.multiSelect,
      ComponentType.dropdown,
      ComponentType.toggle,
      ComponentType.tagSelect,
    };
    
    return inputTypes.contains(component.type);
  }
}

/// Optimized IF-ELSE renderer
class _OptimizedIfElseRenderer extends HookWidget {
  final IfElseComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;
  
  const _OptimizedIfElseRenderer({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    // Evaluate condition without showing it
    final condition = component.sections.first.properties['expression'] ?? '';
    final isTrue = this.context.evaluateCondition(condition);
    
    // Find the section to render
    ComponentSection? sectionToRender;
    
    if (isTrue) {
      sectionToRender = component.sections.firstWhere((s) => s.label == 'THEN');
    } else {
      // Check ELSE IF conditions
      for (final section in component.sections) {
        if (section.label == 'ELSE IF') {
          final elseIfCondition = section.properties['expression'] ?? '';
          if (this.context.evaluateCondition(elseIfCondition)) {
            sectionToRender = section;
            break;
          }
        }
      }
      
      // Default to ELSE
      sectionToRender ??= component.sections.firstWhere(
        (s) => s.label == 'ELSE',
        orElse: () => ComponentSection(
          id: 'empty',
          label: 'ELSE',
          type: CompositeSectionType.branch,
        ),
      );
    }
    
    // Render only the matching section content
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(sectionToRender.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sectionToRender.children.map((editableComp) {
          return OptimizedComponentRenderer.render(
            editableComp.component,
            this.context,
            onValueChanged,
            theme,
          );
        }).toList(),
      ),
    );
  }
}

/// Optimized Switch-Case renderer
class _OptimizedSwitchCaseRenderer extends HookWidget {
  final SwitchCaseComponent component;
  final ExecutionContext context;
  final Function(String, dynamic) onValueChanged;
  final ThemeConfig theme;
  
  const _OptimizedSwitchCaseRenderer({
    required this.component,
    required this.context,
    required this.onValueChanged,
    required this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    final switchVar = component.switchVariable;
    final selectedOption = useState<String?>(
      this.context.getVariable(switchVar)?.toString()
    );
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 400),
    );
    
    // Extract options
    final options = <String>[];
    for (final section in component.sections) {
      if (section.type == CompositeSectionType.caseOption) {
        final caseValue = section.properties['value'] as String?;
        if (caseValue != null) {
          options.add(caseValue);
        }
      }
    }
    
    // Start animation when widget is built
    useEffect(() {
      animationController.forward();
      return null;
    }, []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Options list (vertical layout)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedOption.value == option;
              
              return Padding(
                padding: EdgeInsets.only(bottom: index < options.length - 1 ? 12 : 0),
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    final delay = (index * 0.08).clamp(0.0, 0.4);
                    final animation = Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ).animate(CurvedAnimation(
                      parent: animationController,
                      curve: Interval(
                        delay,
                        (delay + 0.4).clamp(0.0, 1.0),
                        curve: Curves.easeOutBack,
                      ),
                    ));
                    
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - animation.value)),
                      child: SafeOpacity(
                        opacity: animation.value,
                        child: child,
                      ),
                    );
                  },
                  child: _OptionCard(
                    option: option,
                    isSelected: isSelected,
                    onTap: () {
                      selectedOption.value = option;
                      onValueChanged(switchVar, option);
                      HapticFeedback.lightImpact();
                    },
                    theme: theme,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Option card widget
class _OptionCard extends StatelessWidget {
  final String option;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeConfig theme;
  
  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primary,
                      theme.primary.withValues(alpha: 0.85),
                    ],
                  )
                : null,
            color: isSelected ? null : theme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.primary
                  : theme.onSurface.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? theme.onPrimary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? theme.onPrimary
                        : theme.onSurface.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: theme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? theme.onPrimary : theme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isSelected
                    ? theme.onPrimary
                    : theme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}