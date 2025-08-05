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
    if (component.type == ComponentType.titleText ||
        component.type == ComponentType.descriptionText) {
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
      return () {
        // Dispose animation controller properly
        animationController.dispose();
      };
    }, []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title section
        AdvancedUITheme.glassmorphicContainer(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_open, color: theme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose Your Option',
                        style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select one option to continue',
                  style: TextStyle(
                    color: theme.onBackground.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Options grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: options.length <= 2 ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: options.length <= 2 ? 3.5 : 1.5,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedOption.value == option;
              
              return AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  final delay = (index * 0.1).clamp(0.0, 0.5);
                  final animation = Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: animationController,
                    curve: Interval(
                      delay,
                      (delay + 0.5).clamp(0.0, 1.0),
                      curve: Curves.easeOutBack,
                    ),
                  ));
                  
                  return Transform.scale(
                    scale: 0.8 + (0.2 * animation.value),
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primary,
                      theme.primary.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: isSelected ? null : theme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.primary
                  : theme.onSurface.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected
                      ? theme.onPrimary
                      : theme.onSurface.withValues(alpha: 0.5),
                  size: 32,
                  key: ValueKey(isSelected),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                option,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? theme.onPrimary : theme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}