import 'package:flutter/material.dart';
import '../../models/shortcuts/models.dart';

/// Service for managing component icons consistently across the app
class ComponentIconService {
  static final ComponentIconService _instance = ComponentIconService._internal();
  factory ComponentIconService() => _instance;
  ComponentIconService._internal();

  /// Get icon for a component type
  static IconData getIcon(ComponentType type) {
    switch (type) {
      // Input components
      case ComponentType.textInput:
        return Icons.text_fields;
      case ComponentType.multilineTextInput:
        return Icons.notes;
      case ComponentType.numberInput:
        return Icons.numbers;
      case ComponentType.dateTimePicker:
        return Icons.calendar_today;
      case ComponentType.slider:
        return Icons.tune;
      
      // Selection components
      case ComponentType.singleSelect:
        return Icons.radio_button_checked;
      case ComponentType.multiSelect:
        return Icons.check_box;
      case ComponentType.dropdown:
        return Icons.arrow_drop_down_circle;
      case ComponentType.toggle:
        return Icons.toggle_on;
      case ComponentType.switch_:
        return Icons.toggle_off;
      case ComponentType.tagSelect:
        return Icons.label_outline;
      case ComponentType.tagInput:
        return Icons.local_offer;
      
      // Display components
      case ComponentType.descriptionText:
        return Icons.description;
      case ComponentType.image:
        return Icons.image;
      case ComponentType.progressIndicator:
        return Icons.show_chart;
      
      // Layout components
      case ComponentType.groupContainer:
        return Icons.dashboard;
      case ComponentType.tabs:
        return Icons.tab;
      case ComponentType.stepIndicator:
        return Icons.linear_scale;
      
      // Logic components
      case ComponentType.conditional:
        return Icons.alt_route;
      case ComponentType.ifBlock:
        return Icons.call_split;
      case ComponentType.elseBlock:
        return Icons.merge_type;
      case ComponentType.elseIfBlock:
        return Icons.fork_right;
      case ComponentType.forLoop:
        return Icons.repeat;
      case ComponentType.whileLoop:
        return Icons.loop;
      case ComponentType.variableAssignment:
        return Icons.drive_file_rename_outline;
      case ComponentType.variableTransform:
        return Icons.transform;
      
      // Integration components
      case ComponentType.apiCall:
        return Icons.api;
      case ComponentType.fileOperation:
        return Icons.folder;
      case ComponentType.dataTransform:
        return Icons.swap_horiz;
      case ComponentType.jsonParser:
        return Icons.code;
      case ComponentType.csvParser:
        return Icons.table_chart;
      
      // Advanced UI components
      case ComponentType.fileUpload:
        return Icons.upload_file;
      case ComponentType.imageDisplay:
        return Icons.photo;
      case ComponentType.markdown:
        return Icons.text_format;
      case ComponentType.codeEditor:
        return Icons.code;
      case ComponentType.chartDisplay:
        return Icons.analytics;
      
      // Prompt components
      case ComponentType.roleDefinition:
        return Icons.person;
      case ComponentType.contextProvider:
        return Icons.info;
      case ComponentType.taskDescription:
        return Icons.task_alt;
      case ComponentType.text:
        return Icons.text_snippet;
      case ComponentType.exampleProvider:
        return Icons.lightbulb;
      
      // Special component
      case ComponentType.finalPromptBuilder:
        return Icons.auto_awesome;
      
      default:
        return Icons.widgets;
    }
  }

  /// Get color for a component category
  static Color getCategoryColor(ComponentCategory category) {
    switch (category) {
      case ComponentCategory.input:
        return Colors.teal;
      case ComponentCategory.selection:
        return Colors.indigo;
      case ComponentCategory.display:
        return Colors.purple;
      case ComponentCategory.layout:
        return Colors.amber;
      case ComponentCategory.logic:
        return Colors.blue;
      case ComponentCategory.prompt:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get color for a specific component type
  static Color getComponentColor(ComponentType type) {
    // Determine category from type
    if (_isInputComponent(type)) {
      return Colors.teal;
    } else if (_isSelectionComponent(type)) {
      return Colors.indigo;
    } else if (_isDisplayComponent(type)) {
      return Colors.purple;
    } else if (_isLayoutComponent(type)) {
      return Colors.amber;
    } else if (_isLogicComponent(type)) {
      return Colors.blue;
    } else if (_isPromptComponent(type)) {
      return Colors.green;
    } else if (_isIntegrationComponent(type)) {
      return Colors.deepOrange;
    } else if (_isAdvancedUIComponent(type)) {
      return Colors.cyan;
    } else {
      return Colors.grey;
    }
  }

  static bool _isInputComponent(ComponentType type) {
    return [
      ComponentType.textInput,
      ComponentType.multilineTextInput,
      ComponentType.numberInput,
      ComponentType.dateTimePicker,
      ComponentType.slider,
    ].contains(type);
  }

  static bool _isSelectionComponent(ComponentType type) {
    return [
      ComponentType.singleSelect,
      ComponentType.multiSelect,
      ComponentType.dropdown,
      ComponentType.toggle,
      ComponentType.switch_,
      ComponentType.tagSelect,
      ComponentType.tagInput,
    ].contains(type);
  }

  static bool _isDisplayComponent(ComponentType type) {
    return [
      ComponentType.descriptionText,
      ComponentType.image,
      ComponentType.progressIndicator,
    ].contains(type);
  }

  static bool _isLayoutComponent(ComponentType type) {
    return [
      ComponentType.groupContainer,
      ComponentType.tabs,
      ComponentType.stepIndicator,
    ].contains(type);
  }

  static bool _isLogicComponent(ComponentType type) {
    return [
      ComponentType.conditional,
      ComponentType.ifBlock,
      ComponentType.elseBlock,
      ComponentType.elseIfBlock,
      ComponentType.forLoop,
      ComponentType.whileLoop,
      ComponentType.variableAssignment,
      ComponentType.variableTransform,
    ].contains(type);
  }

  static bool _isPromptComponent(ComponentType type) {
    return [
      ComponentType.roleDefinition,
      ComponentType.contextProvider,
      ComponentType.taskDescription,
      ComponentType.text,
      ComponentType.exampleProvider,
      ComponentType.finalPromptBuilder,
    ].contains(type);
  }

  static bool _isIntegrationComponent(ComponentType type) {
    return [
      ComponentType.apiCall,
      ComponentType.fileOperation,
      ComponentType.dataTransform,
      ComponentType.jsonParser,
      ComponentType.csvParser,
    ].contains(type);
  }

  static bool _isAdvancedUIComponent(ComponentType type) {
    return [
      ComponentType.fileUpload,
      ComponentType.imageDisplay,
      ComponentType.markdown,
      ComponentType.codeEditor,
      ComponentType.chartDisplay,
    ].contains(type);
  }

  /// Get icon for composite component types
  static IconData getCompositeIcon(CompositeComponentType type) {
    switch (type) {
      case CompositeComponentType.ifElse:
        return Icons.call_split;
      case CompositeComponentType.switchCase:
        return Icons.menu_book;
      case CompositeComponentType.forEach:
        return Icons.repeat;
      case CompositeComponentType.whileLoop:
        return Icons.loop;
      case CompositeComponentType.tryError:
        return Icons.error_outline;
      default:
        return Icons.account_tree;
    }
  }

  /// Get color for composite component types (matches UnifiedComponentPanel)
  static Color getCompositeColor(CompositeComponentType type) {
    switch (type) {
      case CompositeComponentType.ifElse:
        return Colors.blue;
      case CompositeComponentType.switchCase:
        return Colors.orange;
      case CompositeComponentType.forEach:
        return Colors.green;
      case CompositeComponentType.whileLoop:
        return Colors.purple;
      case CompositeComponentType.tryError:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get display name for component type
  static String getComponentDisplayName(ComponentType type) {
    switch (type) {
      case ComponentType.textInput:
        return 'Text Input';
      case ComponentType.multilineTextInput:
        return 'Multiline Text';
      case ComponentType.numberInput:
        return 'Number Input';
      case ComponentType.dateTimePicker:
        return 'Date/Time Picker';
      case ComponentType.slider:
        return 'Slider';
      case ComponentType.singleSelect:
        return 'Single Select';
      case ComponentType.multiSelect:
        return 'Multi Select';
      case ComponentType.dropdown:
        return 'Dropdown';
      case ComponentType.toggle:
        return 'Toggle';
      case ComponentType.switch_:
        return 'Switch';
      case ComponentType.tagSelect:
        return 'Tag Select';
      case ComponentType.tagInput:
        return 'Tag Input';
      case ComponentType.descriptionText:
        return 'Description Text';
      case ComponentType.image:
        return 'Image';
      case ComponentType.progressIndicator:
        return 'Progress Indicator';
      case ComponentType.groupContainer:
        return 'Group Container';
      case ComponentType.tabs:
        return 'Tabs';
      case ComponentType.stepIndicator:
        return 'Step Indicator';
      case ComponentType.conditional:
        return 'Conditional';
      case ComponentType.ifBlock:
        return 'IF Block';
      case ComponentType.elseBlock:
        return 'ELSE Block';
      case ComponentType.elseIfBlock:
        return 'ELSE IF Block';
      case ComponentType.forLoop:
        return 'FOR Loop';
      case ComponentType.whileLoop:
        return 'WHILE Loop';
      case ComponentType.variableAssignment:
        return 'Variable Assignment';
      case ComponentType.variableTransform:
        return 'Variable Transform';
      case ComponentType.apiCall:
        return 'API Call';
      case ComponentType.fileOperation:
        return 'File Operation';
      case ComponentType.dataTransform:
        return 'Data Transform';
      case ComponentType.jsonParser:
        return 'JSON Parser';
      case ComponentType.csvParser:
        return 'CSV Parser';
      case ComponentType.fileUpload:
        return 'File Upload';
      case ComponentType.imageDisplay:
        return 'Image Display';
      case ComponentType.markdown:
        return 'Markdown';
      case ComponentType.codeEditor:
        return 'Code Editor';
      case ComponentType.chartDisplay:
        return 'Chart Display';
      case ComponentType.roleDefinition:
        return 'Role Definition';
      case ComponentType.contextProvider:
        return 'Context Provider';
      case ComponentType.taskDescription:
        return 'Task Description';
      case ComponentType.text:
        return 'Text';
      case ComponentType.exampleProvider:
        return 'Example Provider';
      case ComponentType.finalPromptBuilder:
        return 'Final Prompt Builder';
      default:
        return type.toString().split('.').last;
    }
  }
}