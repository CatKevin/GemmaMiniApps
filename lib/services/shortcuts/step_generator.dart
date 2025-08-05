import 'package:flutter/material.dart';
import '../../models/shortcuts/models.dart';

/// Intelligent step generator for runtime rendering
class StepGenerator {
  /// Generate optimized steps from shortcut definition
  static List<RenderStep> generateSteps(ShortcutDefinition shortcut) {
    final steps = <RenderStep>[];
    final processedComponents = <String>{};
    
    // Phase 1: Flatten all components from all screens
    final allComponents = _flattenComponents(shortcut);
    
    // Phase 2: Pre-process variable-only components
    final variableOnlyComponents = allComponents
        .where((c) => _isVariableOnlyComponent(c))
        .toList();
    
    // Mark them as processed
    for (final component in variableOnlyComponents) {
      processedComponents.add(component.id);
    }
    
    // Phase 3: Generate welcome step if needed
    if (_shouldAddWelcomeStep(shortcut)) {
      steps.add(RenderStep(
        id: 'welcome',
        title: 'Welcome to ${shortcut.name}',
        subtitle: shortcut.description,
        components: [],
        type: StepType.welcome,
        metadata: {
          'icon': shortcut.icon,
          'showAnimation': true,
        },
      ));
    }
    
    // Phase 4: Group components into logical steps
    final remainingComponents = allComponents
        .where((c) => !processedComponents.contains(c.id))
        .toList();
    
    while (remainingComponents.isNotEmpty) {
      final component = remainingComponents.first;
      
      // Skip if already processed
      if (processedComponents.contains(component.id)) {
        remainingComponents.remove(component);
        continue;
      }
      
      // Special handling for composite components
      if (_isCompositeComponent(component)) {
        final step = _createCompositeStep(component);
        steps.add(step);
        processedComponents.add(component.id);
        remainingComponents.remove(component);
        continue;
      }
      
      // Group related components
      final group = _findRelatedComponents(
        component, 
        remainingComponents,
        processedComponents,
      );
      
      if (group.isNotEmpty) {
        final step = _createStepFromGroup(group);
        steps.add(step);
        
        // Mark all as processed
        for (final c in group) {
          processedComponents.add(c.id);
          remainingComponents.remove(c);
        }
      }
    }
    
    // Phase 5: Add confirmation step if needed
    if (_shouldAddConfirmationStep(shortcut)) {
      steps.add(RenderStep(
        id: 'confirmation',
        title: 'Review & Confirm',
        subtitle: 'Please review your inputs before generating',
        components: [],
        type: StepType.confirmation,
        metadata: {
          'showSummary': true,
        },
      ));
    }
    
    return steps;
  }
  
  /// Flatten all components from all screens
  static List<UIComponent> _flattenComponents(ShortcutDefinition shortcut) {
    final components = <UIComponent>[];
    
    for (final screen in shortcut.screens) {
      // Skip FinalPromptBuilder components
      final screenComponents = screen.components
          .where((c) => c.type != ComponentType.finalPromptBuilder)
          .toList();
      
      components.addAll(screenComponents);
    }
    
    return components;
  }
  
  /// Check if component is variable-only (no UI needed)
  static bool _isVariableOnlyComponent(UIComponent component) {
    return component.type == ComponentType.text ||
           component.type == ComponentType.variableAssignment ||
           component.type == ComponentType.variableTransform ||
           (component.type == ComponentType.roleDefinition && 
            component.properties['showInRuntime'] != true);
  }
  
  /// Check if component is a composite component
  static bool _isCompositeComponent(UIComponent component) {
    return component.properties['isComposite'] == true;
  }
  
  /// Create step for composite component
  static RenderStep _createCompositeStep(UIComponent component) {
    final compositeData = component.properties['compositeData'] as Map<String, dynamic>?;
    final compositeType = compositeData?['type'] ?? '';
    
    String title = 'Make Your Choice';
    String? subtitle;
    
    if (compositeType == 'switchCase') {
      final switchVar = compositeData?['switchVariable'] ?? '';
      title = _generateTitleFromVariable(switchVar);
      subtitle = 'Select one option to continue';
    }
    
    return RenderStep(
      id: 'composite_${component.id}',
      title: title,
      subtitle: subtitle,
      components: [component],
      type: StepType.selection,
      metadata: {
        'isComposite': true,
        'compositeType': compositeType,
      },
    );
  }
  
  /// Find related components that should be grouped together
  static List<UIComponent> _findRelatedComponents(
    UIComponent seed,
    List<UIComponent> candidates,
    Set<String> processed,
  ) {
    final group = <UIComponent>[seed];
    
    // Rules for grouping
    for (final candidate in candidates) {
      if (processed.contains(candidate.id)) continue;
      
      // Rule 1: Group similar input types
      if (_areSimilarInputTypes(seed, candidate)) {
        group.add(candidate);
        continue;
      }
      
      // Rule 2: Group by common prefix in variable names
      if (_haveRelatedVariableNames(seed, candidate)) {
        group.add(candidate);
        continue;
      }
      
      // Rule 3: Stop at display components
      if (_isDisplayComponent(candidate)) {
        break;
      }
      
      // Rule 4: Stop at composite components
      if (_isCompositeComponent(candidate)) {
        break;
      }
      
      // Rule 5: Maximum group size
      if (group.length >= 4) {
        break;
      }
    }
    
    return group;
  }
  
  /// Check if two components are similar input types
  static bool _areSimilarInputTypes(UIComponent a, UIComponent b) {
    const inputTypes = {
      ComponentType.textInput,
      ComponentType.multilineTextInput,
      ComponentType.numberInput,
    };
    
    const selectionTypes = {
      ComponentType.singleSelect,
      ComponentType.multiSelect,
      ComponentType.dropdown,
      ComponentType.tagSelect,
    };
    
    return (inputTypes.contains(a.type) && inputTypes.contains(b.type)) ||
           (selectionTypes.contains(a.type) && selectionTypes.contains(b.type));
  }
  
  /// Check if components have related variable names
  static bool _haveRelatedVariableNames(UIComponent a, UIComponent b) {
    final varA = a.variableBinding;
    final varB = b.variableBinding;
    
    if (varA == null || varB == null) return false;
    
    // Check for common prefixes
    final prefixA = varA.split('_').first;
    final prefixB = varB.split('_').first;
    
    return prefixA == prefixB && prefixA.isNotEmpty;
  }
  
  /// Check if component is a display component
  static bool _isDisplayComponent(UIComponent component) {
    return component.type == ComponentType.titleText ||
           component.type == ComponentType.descriptionText ||
           component.type == ComponentType.image ||
           component.type == ComponentType.progressIndicator;
  }
  
  /// Create a step from a group of components
  static RenderStep _createStepFromGroup(List<UIComponent> group) {
    // Determine step type
    final stepType = _determineStepType(group);
    
    // Generate title based on components
    final title = _generateStepTitle(group);
    final subtitle = _generateStepSubtitle(group);
    
    return RenderStep(
      id: 'step_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      components: group,
      type: stepType,
      metadata: {
        'componentCount': group.length,
      },
    );
  }
  
  /// Determine the type of step based on components
  static StepType _determineStepType(List<UIComponent> components) {
    if (components.every((c) => _isDisplayComponent(c))) {
      return StepType.display;
    }
    
    if (components.any((c) => c.type == ComponentType.singleSelect ||
                             c.type == ComponentType.multiSelect ||
                             c.type == ComponentType.dropdown)) {
      return StepType.selection;
    }
    
    return StepType.input;
  }
  
  /// Generate a meaningful title for the step
  static String _generateStepTitle(List<UIComponent> components) {
    // Look for title components
    final titleComponent = components.firstWhere(
      (c) => c.type == ComponentType.titleText,
      orElse: () => components.first,
    );
    
    if (titleComponent.type == ComponentType.titleText) {
      return titleComponent.properties['text'] ?? 'Information';
    }
    
    // Generate based on component types
    if (components.every((c) => c.type == ComponentType.textInput ||
                               c.type == ComponentType.multilineTextInput)) {
      return 'Text Information';
    }
    
    if (components.any((c) => c.type == ComponentType.singleSelect ||
                             c.type == ComponentType.dropdown)) {
      return 'Make Your Selection';
    }
    
    // Fallback to first component's label
    final firstLabel = components.first.properties['label'];
    if (firstLabel != null && firstLabel.toString().isNotEmpty) {
      return firstLabel.toString();
    }
    
    return 'Step ${components.length}';
  }
  
  /// Generate subtitle for the step
  static String? _generateStepSubtitle(List<UIComponent> components) {
    // Look for description components
    final descComponent = components.firstWhere(
      (c) => c.type == ComponentType.descriptionText,
      orElse: () => components.first,
    );
    
    if (descComponent.type == ComponentType.descriptionText) {
      final text = descComponent.properties['text'] ?? '';
      // Truncate if too long
      return text.toString().length > 100 
          ? '${text.toString().substring(0, 97)}...'
          : text.toString();
    }
    
    // Count required fields
    final requiredCount = components
        .where((c) => c.properties['required'] == true)
        .length;
    
    if (requiredCount > 0) {
      return '$requiredCount required field${requiredCount > 1 ? 's' : ''}';
    }
    
    return null;
  }
  
  /// Generate title from variable name
  static String _generateTitleFromVariable(String variableName) {
    if (variableName.isEmpty) return 'Make Your Choice';
    
    // Remove {{ }} if present
    variableName = variableName.replaceAll(RegExp(r'[{}]'), '');
    
    // Convert snake_case or camelCase to Title Case
    final words = variableName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .toList();
    
    return 'Choose ${words.join(' ')}';
  }
  
  /// Check if should add welcome step
  static bool _shouldAddWelcomeStep(ShortcutDefinition shortcut) {
    // Add welcome step for complex shortcuts
    final totalComponents = shortcut.screens
        .map((s) => s.components.length)
        .reduce((a, b) => a + b);
    
    return totalComponents > 5 || shortcut.name.length > 20;
  }
  
  /// Check if should add confirmation step
  static bool _shouldAddConfirmationStep(ShortcutDefinition shortcut) {
    // Add confirmation for shortcuts with many inputs
    final inputComponents = shortcut.screens
        .expand((s) => s.components)
        .where((c) => c.variableBinding != null)
        .length;
    
    return inputComponents > 3;
  }
}

/// Step type enumeration
enum StepType {
  welcome,      // Welcome screen
  input,        // Input collection
  selection,    // Selection/choice
  display,      // Information display
  confirmation, // Review and confirm
  processing,   // Processing/loading
  result,       // Final result
}

/// Render step model
class RenderStep {
  final String id;
  final String title;
  final String? subtitle;
  final List<UIComponent> components;
  final StepType type;
  final Map<String, dynamic>? metadata;
  final TransitionEffect? transitionIn;
  final TransitionEffect? transitionOut;
  
  RenderStep({
    required this.id,
    required this.title,
    this.subtitle,
    required this.components,
    required this.type,
    this.metadata,
    this.transitionIn,
    this.transitionOut,
  });
  
  /// Check if step has any required fields
  bool get hasRequiredFields {
    return components.any((c) => c.properties['required'] == true);
  }
  
  /// Get all variable bindings in this step
  List<String> get variableBindings {
    return components
        .where((c) => c.variableBinding != null)
        .map((c) => c.variableBinding!)
        .toList();
  }
}

/// Transition effect configuration
class TransitionEffect {
  final TransitionType type;
  final Duration duration;
  final Curve curve;
  
  const TransitionEffect({
    required this.type,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  });
}

/// Transition types
enum TransitionType {
  slide,
  fade,
  scale,
  slideUp,
  slideDown,
  custom,
}