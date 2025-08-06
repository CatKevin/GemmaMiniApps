import '../../models/shortcuts/models.dart';

/// Service for building prompts from shortcut definitions and collected data
class PromptBuilder {
  /// Build prompt from a template string directly (for FinalPromptBuilder)
  static String buildPromptFromTemplate({
    required String template,
    required ExecutionContext context,
  }) {
    return _processTemplate(template, context);
  }
  
  /// Build a complete prompt from a shortcut definition and execution context
  static String buildPrompt({
    required ShortcutDefinition definition,
    required ExecutionContext context,
  }) {
    final promptTemplate = definition.promptTemplate;
    final sections = List<PromptSection>.from(promptTemplate.sections);
    
    // Sort sections by order
    sections.sort((a, b) => a.order.compareTo(b.order));
    
    final processedSections = <String>[];
    
    for (final section in sections) {
      // Check if section should be included based on condition
      if (section.condition != null && section.condition!.isNotEmpty) {
        if (!context.evaluateCondition(section.condition!)) {
          continue; // Skip this section
        }
      }
      
      // Process the section content
      final processedContent = _processTemplate(section.content, context);
      
      if (processedContent.isNotEmpty) {
        processedSections.add(processedContent);
      }
    }
    
    // Apply assembly logic
    return _assemblePrompt(processedSections, promptTemplate.assemblyLogic);
  }
  
  /// Process a template string, replacing variables with their values
  static String _processTemplate(String template, ExecutionContext context) {
    // Handle variable interpolation: {{variableName}}
    String processed = template.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) {
        final variableName = match.group(1)!;
        final value = context.getVariable(variableName);
        
        if (value == null) {
          return ''; // Empty string for missing variables
        }
        
        // Handle different value types
        if (value is List) {
          // Join list items with commas
          return value.map((item) => item.toString()).join(', ');
        } else if (value is Map) {
          // Convert map to readable format
          return value.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(', ');
        } else if (value is DateTime) {
          // Format datetime
          return _formatDateTime(value);
        } else {
          // Convert to string
          return value.toString();
        }
      },
    );
    
    // Handle conditional blocks: {{if condition}}content{{/if}}
    processed = _processConditionals(processed, context);
    
    // Handle loops: {{each items as item}}content{{/each}}
    processed = _processLoops(processed, context);
    
    return processed.trim();
  }
  
  /// Process conditional blocks in the template
  static String _processConditionals(String template, ExecutionContext context) {
    // Support both {{if}} and {{#if}} syntax
    final conditionalPattern = RegExp(
      r'\{\{#?if\s+(.+?)\}\}([\s\S]*?)\{\{\/if\}\}',
      multiLine: true,
    );
    
    return template.replaceAllMapped(conditionalPattern, (match) {
      final condition = match.group(1)!;
      final content = match.group(2)!;
      
      if (context.evaluateCondition(condition)) {
        return _processTemplate(content, context);
      }
      return '';
    });
  }
  
  /// Process loop blocks in the template
  static String _processLoops(String template, ExecutionContext context) {
    // Support both {{each}} and {{#each}} syntax
    final loopPattern = RegExp(
      r'\{\{#?each\s+(\w+)\s+as\s+(\w+)\}\}([\s\S]*?)\{\{\/each\}\}',
      multiLine: true,
    );
    
    return template.replaceAllMapped(loopPattern, (match) {
      final listVariableName = match.group(1)!;
      final itemVariableName = match.group(2)!;
      final content = match.group(3)!;
      
      final list = context.getVariable(listVariableName);
      if (list is! List) return '';
      
      final results = <String>[];
      
      for (final item in list) {
        // Create a temporary context with the loop variable
        final loopContext = context.clone();
        loopContext.setVariable(itemVariableName, item);
        
        results.add(_processTemplate(content, loopContext));
      }
      
      return results.join('\n');
    });
  }
  
  /// Assemble processed sections according to the assembly logic
  static String _assemblePrompt(List<String> sections, String assemblyLogic) {
    switch (assemblyLogic) {
      case 'sequential':
        // Simply join sections with double newlines
        return sections.join('\n\n');
        
      case 'numbered':
        // Number each section
        return sections.asMap().entries
            .map((entry) => '${entry.key + 1}. ${entry.value}')
            .join('\n\n');
        
      case 'bulleted':
        // Bullet each section
        return sections
            .map((section) => '• $section')
            .join('\n\n');
        
      case 'paragraphs':
        // Join with single newlines for paragraph style
        return sections.join('\n');
        
      default:
        // Default to sequential
        return sections.join('\n\n');
    }
  }
  
  /// Format a DateTime value
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
           '${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// Extract prompt components from UI components (for editor preview)
  static List<PromptSection> extractPromptSections(List<UIComponent> components) {
    final sections = <PromptSection>[];
    int order = 0;
    
    for (final component in components) {
      PromptSection? section;
      
      switch (component.type) {
        case ComponentType.roleDefinition:
          section = PromptSection(
            id: component.id,
            type: PromptSectionType.role,
            content: component.properties['role'] ?? '',
            condition: component.conditionalDisplay,
            order: order++,
          );
          break;
          
        case ComponentType.contextProvider:
          section = PromptSection(
            id: component.id,
            type: PromptSectionType.context,
            content: component.properties['context'] ?? '',
            condition: component.conditionalDisplay,
            order: order++,
          );
          break;
          
        case ComponentType.taskDescription:
          section = PromptSection(
            id: component.id,
            type: PromptSectionType.task,
            content: component.properties['task'] ?? '',
            condition: component.conditionalDisplay,
            order: order++,
          );
          break;
          
        case ComponentType.text:
          section = PromptSection(
            id: component.id,
            type: PromptSectionType.custom,
            content: component.properties['content'] ?? '',
            condition: component.conditionalDisplay,
            order: order++,
          );
          break;
          
        case ComponentType.exampleProvider:
          section = PromptSection(
            id: component.id,
            type: PromptSectionType.examples,
            content: component.properties['examples'] ?? '',
            condition: component.conditionalDisplay,
            order: order++,
          );
          break;
          
        default:
          // Skip non-prompt components
          break;
      }
      
      if (section != null) {
        sections.add(section);
      }
    }
    
    return sections;
  }
  
  /// Preview prompt with sample data (for editor)
  static String previewPrompt({
    required List<UIComponent> components,
    required Map<String, dynamic> sampleData,
  }) {
    // Create a temporary execution context with sample data
    final context = ExecutionContext(
      shortcutId: 'preview',
      currentScreenId: 'preview',
      variables: sampleData,
    );
    
    // Extract prompt sections from components
    final sections = extractPromptSections(components);
    
    // Create a temporary prompt template
    final promptTemplate = PromptTemplate(
      sections: sections,
      assemblyLogic: 'sequential',
    );
    
    // Build the prompt
    final processedSections = <String>[];
    
    for (final section in sections) {
      if (section.condition != null && section.condition!.isNotEmpty) {
        if (!context.evaluateCondition(section.condition!)) {
          continue;
        }
      }
      
      final processedContent = _processTemplate(section.content, context);
      if (processedContent.isNotEmpty) {
        processedSections.add(processedContent);
      }
    }
    
    return _assemblePrompt(processedSections, promptTemplate.assemblyLogic);
  }
  
  /// Validate prompt template for errors
  static List<String> validatePromptTemplate({
    required PromptTemplate template,
    required Map<String, VariableDefinition> availableVariables,
  }) {
    final errors = <String>[];
    
    for (final section in template.sections) {
      // Check for undefined variables
      final variablePattern = RegExp(r'\{\{(\w+)\}\}');
      final matches = variablePattern.allMatches(section.content);
      
      for (final match in matches) {
        final variableName = match.group(1)!;
        if (!availableVariables.containsKey(variableName)) {
          errors.add('Undefined variable "$variableName" in section ${section.id}');
        }
      }
      
      // Check condition syntax
      if (section.condition != null && section.condition!.isNotEmpty) {
        try {
          // Try to parse the condition
          final parts = section.condition!.split(' ');
          if (parts.length < 2) {
            errors.add('Invalid condition syntax in section ${section.id}');
          }
        } catch (e) {
          errors.add('Error parsing condition in section ${section.id}: $e');
        }
      }
    }
    
    return errors;
  }
}