import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'shortcut_definition.dart';
import 'composite_component.dart';

/// Component that can be added from the component panel
class ComponentTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final ComponentCategory category;
  final ComponentType type;
  final Map<String, dynamic> defaultProperties;
  final List<ComponentProperty> editableProperties;

  ComponentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.type,
    required this.defaultProperties,
    required this.editableProperties,
  });
}

/// Category for grouping components
enum ComponentCategory {
  input,
  selection,
  display,
  layout,
  logic,
  prompt,
}

/// Property that can be edited in the editor
class ComponentProperty {
  final String key;
  final String label;
  final PropertyType type;
  final dynamic defaultValue;
  final bool required;
  final List<dynamic>? options; // For select types
  final Map<String, dynamic>? constraints;

  ComponentProperty({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.required = false,
    this.options,
    this.constraints,
  });
}

/// Types of properties that can be edited
enum PropertyType {
  text,
  number,
  boolean,
  select,
  multiSelect,
  variable,
  expression,
  richText,
}

/// Editor state for a component being edited
class EditableComponent {
  final String id;
  final UIComponent component;
  final bool isExpanded;
  final bool isSelected;
  final int order;
  final quill.QuillController? richTextController;
  final bool isComposite;
  final CompositeComponent? compositeComponent;
  final String? parentSectionId; // For components inside composite sections

  EditableComponent({
    required this.id,
    required this.component,
    this.isExpanded = false,
    this.isSelected = false,
    required this.order,
    this.richTextController,
    this.isComposite = false,
    this.compositeComponent,
    this.parentSectionId,
  });

  EditableComponent copyWith({
    String? id,
    UIComponent? component,
    bool? isExpanded,
    bool? isSelected,
    int? order,
    quill.QuillController? richTextController,
    bool? isComposite,
    CompositeComponent? compositeComponent,
    String? parentSectionId,
  }) {
    return EditableComponent(
      id: id ?? this.id,
      component: component ?? this.component,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      order: order ?? this.order,
      richTextController: richTextController ?? this.richTextController,
      isComposite: isComposite ?? this.isComposite,
      compositeComponent: compositeComponent ?? this.compositeComponent,
      parentSectionId: parentSectionId ?? this.parentSectionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'component': component.toJson(),
      'isExpanded': isExpanded,
      'isSelected': isSelected,
      'order': order,
      'isComposite': isComposite,
      'compositeComponent': compositeComponent?.toJson(),
      'parentSectionId': parentSectionId,
    };
  }

  factory EditableComponent.fromJson(Map<String, dynamic> json) {
    return EditableComponent(
      id: json['id'],
      component: UIComponent.fromJson(json['component']),
      isExpanded: json['isExpanded'] ?? false,
      isSelected: json['isSelected'] ?? false,
      order: json['order'],
      isComposite: json['isComposite'] ?? false,
      compositeComponent: json['compositeComponent'] != null
          ? CompositeComponent.fromJson(json['compositeComponent'])
          : null,
      parentSectionId: json['parentSectionId'],
    );
  }
}

/// Editor session state
class EditorSession {
  final String shortcutId;
  final String shortcutName;
  final List<EditableComponent> components;
  final Map<String, VariableDefinition> variables;
  final Set<String> expandedComponents;
  final String? selectedComponentId;
  final bool hasUnsavedChanges;
  final DateTime lastModified;

  EditorSession({
    required this.shortcutId,
    required this.shortcutName,
    required this.components,
    required this.variables,
    required this.expandedComponents,
    this.selectedComponentId,
    required this.hasUnsavedChanges,
    required this.lastModified,
  });

  EditorSession copyWith({
    String? shortcutId,
    String? shortcutName,
    List<EditableComponent>? components,
    Map<String, VariableDefinition>? variables,
    Set<String>? expandedComponents,
    String? selectedComponentId,
    bool? hasUnsavedChanges,
    DateTime? lastModified,
  }) {
    return EditorSession(
      shortcutId: shortcutId ?? this.shortcutId,
      shortcutName: shortcutName ?? this.shortcutName,
      components: components ?? this.components,
      variables: variables ?? this.variables,
      expandedComponents: expandedComponents ?? this.expandedComponents,
      selectedComponentId: selectedComponentId,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Variable reference in rich text
class VariableReference {
  final String variableName;
  final int startIndex;
  final int endIndex;

  VariableReference({
    required this.variableName,
    required this.startIndex,
    required this.endIndex,
  });
}

/// Preview data for testing shortcuts
class PreviewData {
  final Map<String, dynamic> sampleVariables;
  final String generatedPrompt;
  final List<String> warnings;

  PreviewData({
    required this.sampleVariables,
    required this.generatedPrompt,
    required this.warnings,
  });
}

/// Component drag state
class DragState {
  final String componentId;
  final int originalIndex;
  final int currentIndex;
  final bool isDragging;

  DragState({
    required this.componentId,
    required this.originalIndex,
    required this.currentIndex,
    required this.isDragging,
  });
}

/// Available component templates
class ComponentTemplateLibrary {
  static final List<ComponentTemplate> templates = [
    // Input Components
    ComponentTemplate(
      id: 'text-input',
      name: 'Text Input',
      description: 'Single line text input',
      icon: Icons.text_fields,
      category: ComponentCategory.input,
      type: ComponentType.textInput,
      defaultProperties: {
        'placeholder': 'Enter text...',
        'maxLength': 100,
        'required': false,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'placeholder',
          label: 'Placeholder',
          type: PropertyType.text,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'maxLength',
          label: 'Max Length',
          type: PropertyType.number,
          defaultValue: 100,
        ),
        ComponentProperty(
          key: 'required',
          label: 'Required',
          type: PropertyType.boolean,
          defaultValue: false,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'multiline-input',
      name: 'Multiline Text',
      description: 'Multi-line text input',
      icon: Icons.notes,
      category: ComponentCategory.input,
      type: ComponentType.multilineTextInput,
      defaultProperties: {
        'placeholder': 'Enter detailed text...',
        'rows': 4,
        'maxLength': 500,
        'required': false,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'placeholder',
          label: 'Placeholder',
          type: PropertyType.text,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'rows',
          label: 'Rows',
          type: PropertyType.number,
          defaultValue: 4,
        ),
        ComponentProperty(
          key: 'maxLength',
          label: 'Max Length',
          type: PropertyType.number,
          defaultValue: 500,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'number-input',
      name: 'Number Input',
      description: 'Numeric input field',
      icon: Icons.numbers,
      category: ComponentCategory.input,
      type: ComponentType.numberInput,
      defaultProperties: {
        'min': 0,
        'max': 100,
        'step': 1,
        'required': false,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'min',
          label: 'Minimum',
          type: PropertyType.number,
          defaultValue: 0,
        ),
        ComponentProperty(
          key: 'max',
          label: 'Maximum',
          type: PropertyType.number,
          defaultValue: 100,
        ),
        ComponentProperty(
          key: 'step',
          label: 'Step',
          type: PropertyType.number,
          defaultValue: 1,
        ),
      ],
    ),
    
    // Selection Components
    ComponentTemplate(
      id: 'single-select',
      name: 'Single Select',
      description: 'Radio button selection',
      icon: Icons.radio_button_checked,
      category: ComponentCategory.selection,
      type: ComponentType.singleSelect,
      defaultProperties: {
        'options': ['Option 1', 'Option 2', 'Option 3'],
        'required': true,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'options',
          label: 'Options',
          type: PropertyType.multiSelect,
          required: true,
        ),
        ComponentProperty(
          key: 'required',
          label: 'Required',
          type: PropertyType.boolean,
          defaultValue: true,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'multi-select',
      name: 'Multi Select',
      description: 'Checkbox selection',
      icon: Icons.check_box,
      category: ComponentCategory.selection,
      type: ComponentType.multiSelect,
      defaultProperties: {
        'options': ['Option 1', 'Option 2', 'Option 3'],
        'minSelection': 0,
        'maxSelection': null,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'options',
          label: 'Options',
          type: PropertyType.multiSelect,
          required: true,
        ),
        ComponentProperty(
          key: 'minSelection',
          label: 'Min Selection',
          type: PropertyType.number,
          defaultValue: 0,
        ),
        ComponentProperty(
          key: 'maxSelection',
          label: 'Max Selection',
          type: PropertyType.number,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'dropdown',
      name: 'Dropdown',
      description: 'Dropdown menu selection',
      icon: Icons.arrow_drop_down_circle,
      category: ComponentCategory.selection,
      type: ComponentType.dropdown,
      defaultProperties: {
        'options': ['Option 1', 'Option 2', 'Option 3'],
        'placeholder': 'Select an option',
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'options',
          label: 'Options',
          type: PropertyType.multiSelect,
          required: true,
        ),
        ComponentProperty(
          key: 'placeholder',
          label: 'Placeholder',
          type: PropertyType.text,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'toggle',
      name: 'Toggle',
      description: 'On/Off toggle switch',
      icon: Icons.toggle_on,
      category: ComponentCategory.selection,
      type: ComponentType.toggle,
      defaultProperties: {
        'defaultValue': false,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'defaultValue',
          label: 'Default State',
          type: PropertyType.boolean,
          defaultValue: false,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'slider',
      name: 'Slider',
      description: 'Value slider input',
      icon: Icons.tune,
      category: ComponentCategory.input,
      type: ComponentType.slider,
      defaultProperties: {
        'min': 0,
        'max': 100,
        'step': 1,
        'showLabels': true,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'min',
          label: 'Minimum Value',
          type: PropertyType.number,
          defaultValue: 0,
        ),
        ComponentProperty(
          key: 'max',
          label: 'Maximum Value',
          type: PropertyType.number,
          defaultValue: 100,
        ),
        ComponentProperty(
          key: 'step',
          label: 'Step',
          type: PropertyType.number,
          defaultValue: 1,
        ),
        ComponentProperty(
          key: 'showLabels',
          label: 'Show Labels',
          type: PropertyType.boolean,
          defaultValue: true,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'date-time-picker',
      name: 'Date/Time Picker',
      description: 'Date and time selection',
      icon: Icons.calendar_today,
      category: ComponentCategory.input,
      type: ComponentType.dateTimePicker,
      defaultProperties: {
        'mode': 'date',
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'mode',
          label: 'Mode',
          type: PropertyType.select,
          defaultValue: 'date',
          options: ['date', 'time', 'datetime'],
        ),
      ],
    ),
    ComponentTemplate(
      id: 'tag-input',
      name: 'Tag Input',
      description: 'Multiple tag input',
      icon: Icons.local_offer,
      category: ComponentCategory.selection,
      type: ComponentType.tagInput,
      defaultProperties: {
        'placeholder': 'Add tags...',
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'placeholder',
          label: 'Placeholder',
          type: PropertyType.text,
          defaultValue: 'Add tags...',
        ),
      ],
    ),
    ComponentTemplate(
      id: 'image-input',
      name: 'Image Input',
      description: 'Image upload and capture',
      icon: Icons.add_a_photo,
      category: ComponentCategory.input,
      type: ComponentType.imageInput,
      defaultProperties: {
        'allowCamera': true,
        'allowGallery': true,
        'maxImages': 1,
        'required': false,
      },
      editableProperties: [
        ComponentProperty(
          key: 'label',
          label: 'Label',
          type: PropertyType.text,
          required: true,
        ),
        ComponentProperty(
          key: 'variableName',
          label: 'Variable Name',
          type: PropertyType.variable,
          required: false,
        ),
        ComponentProperty(
          key: 'allowCamera',
          label: 'Allow Camera',
          type: PropertyType.boolean,
          defaultValue: true,
        ),
        ComponentProperty(
          key: 'allowGallery',
          label: 'Allow Gallery',
          type: PropertyType.boolean,
          defaultValue: true,
        ),
        ComponentProperty(
          key: 'maxImages',
          label: 'Max Images',
          type: PropertyType.number,
          defaultValue: 1,
        ),
        ComponentProperty(
          key: 'required',
          label: 'Required',
          type: PropertyType.boolean,
          defaultValue: false,
        ),
      ],
    ),
    
    // Display Components
    ComponentTemplate(
      id: 'description-text',
      name: 'Description Text',
      description: 'Display title and description text',
      icon: Icons.description,
      category: ComponentCategory.display,
      type: ComponentType.descriptionText,
      defaultProperties: {
        'title': '',
        'content': 'Enter your description here',
      },
      editableProperties: [
        ComponentProperty(
          key: 'title',
          label: 'Title (Optional)',
          type: PropertyType.text,
          required: false,
        ),
        ComponentProperty(
          key: 'content',
          label: 'Content',
          type: PropertyType.text,
          required: true,
        ),
      ],
    ),
    
    // Logic Components
    // Individual logic blocks have been replaced by composite components
    // Use IF-ELSE, SWITCH-CASE, FOR-EACH, etc. from the ADD LOGIC button
    
    // Prompt Components
    ComponentTemplate(
      id: 'text',
      name: 'Text',
      description: 'Rich text with variables',
      icon: Icons.text_snippet,
      category: ComponentCategory.prompt,
      type: ComponentType.text,
      defaultProperties: {
        'content': '',
      },
      editableProperties: [
        ComponentProperty(
          key: 'content',
          label: 'Content',
          type: PropertyType.richText,
          required: true,
        ),
        ComponentProperty(
          key: 'outputVariable',
          label: 'Output Variable',
          type: PropertyType.variable,
          required: false,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'task-description',
      name: 'Task Description',
      description: 'Define the task',
      icon: Icons.task_alt,
      category: ComponentCategory.prompt,
      type: ComponentType.taskDescription,
      defaultProperties: {
        'task': '',
      },
      editableProperties: [
        ComponentProperty(
          key: 'task',
          label: 'Task Description',
          type: PropertyType.richText,
          required: true,
        ),
      ],
    ),
    ComponentTemplate(
      id: 'final-prompt-builder',
      name: 'Final Prompt Builder',
      description: 'Build final prompt with variables',
      icon: Icons.auto_awesome,
      category: ComponentCategory.prompt,
      type: ComponentType.finalPromptBuilder,
      defaultProperties: {
        'template': '',
      },
      editableProperties: [
        ComponentProperty(
          key: 'template',
          label: 'Prompt Template',
          type: PropertyType.richText,
          required: true,
        ),
      ],
    ),
  ];

  static ComponentTemplate? getTemplate(ComponentType type) {
    return templates.firstWhere(
      (t) => t.type == type,
      orElse: () => templates.first,
    );
  }

  static List<ComponentTemplate> getByCategory(ComponentCategory category) {
    return templates.where((t) => t.category == category).toList();
  }
}

/// Predefined shortcut templates
class ShortcutTemplates {
  static final List<ShortcutTemplate> templates = [
    ShortcutTemplate(
      id: 'form-collector',
      name: 'Form Collector',
      description: 'Collect structured information from users',
      icon: Icons.assignment,
      category: 'productivity',
      components: [
        UIComponent(
          id: 'title',
          type: ComponentType.descriptionText,
          properties: {
            'title': 'Please fill out the form',
            'content': 'Complete all required fields below',
          },
        ),
        UIComponent(
          id: 'name-input',
          type: ComponentType.textInput,
          properties: {
            'label': 'Full Name',
            'placeholder': 'Enter your full name',
            'required': true,
          },
          variableBinding: 'userName',
        ),
        UIComponent(
          id: 'email-input',
          type: ComponentType.textInput,
          properties: {
            'label': 'Email Address',
            'placeholder': 'your.email@example.com',
            'required': true,
            'validation': 'email',
          },
          variableBinding: 'userEmail',
        ),
        UIComponent(
          id: 'reason-input',
          type: ComponentType.multilineTextInput,
          properties: {
            'label': 'Reason for Contact',
            'placeholder': 'Tell us why you are reaching out...',
            'rows': 4,
          },
          variableBinding: 'contactReason',
        ),
      ],
    ),
    ShortcutTemplate(
      id: 'decision-tree',
      name: 'Decision Tree',
      description: 'Guide users through a decision-making process',
      icon: Icons.account_tree,
      category: 'business',
      components: [
        UIComponent(
          id: 'title',
          type: ComponentType.descriptionText,
          properties: {
            'title': 'Let\'s find the best option for you',
            'content': 'Answer a few questions to get personalized recommendations',
          },
        ),
        UIComponent(
          id: 'budget-question',
          type: ComponentType.singleSelect,
          properties: {
            'label': 'What is your budget range?',
            'options': [r'Under $100', r'$100-$500', r'$500-$1000', r'Over $1000'],
          },
          variableBinding: 'budgetRange',
        ),
        UIComponent(
          id: 'if-low-budget',
          type: ComponentType.ifBlock,
          properties: {
            'condition': r'budgetRange == "Under $100"',
            'children': [],
          },
        ),
      ],
    ),
    ShortcutTemplate(
      id: 'survey',
      name: 'Survey Template',
      description: 'Create a multi-question survey',
      icon: Icons.poll,
      category: 'research',
      components: [
        UIComponent(
          id: 'title',
          type: ComponentType.descriptionText,
          properties: {
            'title': 'Customer Satisfaction Survey',
            'content': 'Help us improve by sharing your feedback',
          },
        ),
        UIComponent(
          id: 'description',
          type: ComponentType.descriptionText,
          properties: {
            'text': 'Your feedback helps us improve our service',
          },
        ),
        UIComponent(
          id: 'rating',
          type: ComponentType.slider,
          properties: {
            'label': 'How satisfied are you with our service?',
            'min': 1,
            'max': 10,
            'step': 1,
            'showLabels': true,
          },
          variableBinding: 'satisfactionRating',
        ),
        UIComponent(
          id: 'improvements',
          type: ComponentType.multiSelect,
          properties: {
            'label': 'What could we improve?',
            'options': ['Speed', 'Quality', 'Communication', 'Price', 'Features'],
          },
          variableBinding: 'improvementAreas',
        ),
      ],
    ),
    ShortcutTemplate(
      id: 'content-generator',
      name: 'Content Generator',
      description: 'Generate content based on user inputs',
      icon: Icons.auto_awesome,
      category: 'creative',
      components: [
        UIComponent(
          id: 'title',
          type: ComponentType.descriptionText,
          properties: {
            'title': 'AI Content Generator',
            'content': 'Create high-quality content with AI assistance',
          },
        ),
        UIComponent(
          id: 'content-type',
          type: ComponentType.dropdown,
          properties: {
            'label': 'What type of content do you need?',
            'options': ['Blog Post', 'Social Media', 'Email', 'Product Description'],
          },
          variableBinding: 'contentType',
        ),
        UIComponent(
          id: 'topic',
          type: ComponentType.textInput,
          properties: {
            'label': 'Topic or Subject',
            'placeholder': 'What should the content be about?',
          },
          variableBinding: 'contentTopic',
        ),
        UIComponent(
          id: 'tone',
          type: ComponentType.singleSelect,
          properties: {
            'label': 'Tone of Voice',
            'options': ['Professional', 'Casual', 'Friendly', 'Formal', 'Humorous'],
          },
          variableBinding: 'contentTone',
        ),
      ],
    ),
    // OOTD Style Check Template
    ShortcutTemplate(
      id: 'ootd-style-check',
      name: 'OOTD Style Check',
      description: 'Get instant fashion feedback and styling tips from your AI personal stylist',
      icon: Icons.checkroom,
      category: 'life',
      components: [
        UIComponent(
          id: 'title',
          type: ComponentType.descriptionText,
          properties: {
            'title': '✨ OOTD Style Check ✨',
            'content': 'Take a photo of your outfit and get instant feedback from your AI personal stylist!',
          },
        ),
        UIComponent(
          id: 'outfit-image',
          type: ComponentType.imageInput,
          properties: {
            'label': 'Upload Your Outfit Photo',
            'allowCamera': true,
            'allowGallery': true,
            'maxImages': 1,
            'required': true,
          },
          variableBinding: 'outfitImage',
        ),
        UIComponent(
          id: 'occasion-input',
          type: ComponentType.dropdown,
          properties: {
            'label': 'What\'s the occasion?',
            'options': [
              'Work/Office',
              'Casual Hangout',
              'Date Night',
              'Party/Club',
              'Formal Event',
              'Sports/Gym',
              'Weekend Brunch',
              'Travel',
              'Other'
            ],
            'placeholder': 'Select the occasion',
          },
          variableBinding: 'occasion',
        ),
        UIComponent(
          id: 'weather-input',
          type: ComponentType.singleSelect,
          properties: {
            'label': 'What\'s the weather like?',
            'options': [
              'Hot & Sunny',
              'Warm',
              'Cool',
              'Cold',
              'Rainy',
              'Snowy',
              'Windy'
            ],
          },
          variableBinding: 'weather',
        ),
        UIComponent(
          id: 'style-preferences',
          type: ComponentType.multiSelect,
          properties: {
            'label': 'What style vibe are you going for? (Optional)',
            'options': [
              'Minimalist',
              'Trendy',
              'Classic',
              'Edgy',
              'Bohemian',
              'Preppy',
              'Streetwear',
              'Business Casual',
              'Athleisure',
              'Vintage'
            ],
          },
          variableBinding: 'stylePreferences',
        ),
        UIComponent(
          id: 'specific-concerns',
          type: ComponentType.multilineTextInput,
          properties: {
            'label': 'Any specific concerns or questions? (Optional)',
            'placeholder': 'e.g., "Is this too formal?", "Do the colors work together?"',
            'rows': 3,
            'required': false,
          },
          variableBinding: 'specificConcerns',
        ),
        UIComponent(
          id: 'role-definition',
          type: ComponentType.roleDefinition,
          properties: {
            'role': 'You are a friendly, encouraging, and fashion-forward personal stylist with years of experience in fashion and styling. Your goal is to help people feel confident and stylish by providing constructive, positive, and actionable fashion advice.',
          },
        ),
        UIComponent(
          id: 'task-description',
          type: ComponentType.taskDescription,
          properties: {
            'task': 'Analyze the uploaded outfit photo and provide detailed fashion feedback.',
          },
        ),
        UIComponent(
          id: 'context-provider',
          type: ComponentType.contextProvider,
          properties: {
            'context': 'The user has shared their Outfit of the Day (OOTD) and wants your expert opinion. Consider the occasion: {{occasion}}, weather: {{weather}}, and their style preferences: {{stylePreferences}}. {{#if specificConcerns}}They also mentioned: {{specificConcerns}}{{/if}}',
          },
        ),
        UIComponent(
          id: 'prompt-text',
          type: ComponentType.text,
          properties: {
            'content': '''Please analyze my outfit based on the photo I've provided. 

Structure your response as follows:

**First Impression** 💫
Start with a warm, encouraging opening that highlights what's working well in the outfit.

**Style Analysis** 👗
- **Color Palette & Coordination**: How well do the colors work together?
- **Fit & Silhouette**: Comment on the fit, proportions, and overall silhouette
- **Style Cohesion**: Does everything work together as a cohesive look?
- **Occasion Appropriateness**: Is this suitable for {{occasion}} and {{weather}} weather?

**What's Working** ✅
List 2-3 specific things that are particularly good about this outfit.

**Styling Suggestions** 💡
Provide 2-3 specific, actionable suggestions to elevate this look. Frame these as fun ideas rather than criticisms:
- "Have you thought about trying..."
- "This would look even more amazing with..."
- "A fun twist could be..."

**Quick Tips** 🎯
Share 1-2 quick styling tips relevant to this type of outfit or occasion.

**Confidence Boost** ⭐
End with an encouraging, confidence-boosting message that makes me feel great about my style choices.

Remember to:
- Be friendly and supportive, like a best friend who's great at fashion
- Use encouraging language and emoji to keep it fun
- Provide specific, actionable advice
- Consider the context (occasion, weather, style preferences)
- Focus on positives while gently suggesting improvements''',
          },
        ),
        UIComponent(
          id: 'final-prompt',
          type: ComponentType.finalPromptBuilder,
          properties: {
            'includeImage': true,
            'imageVariable': 'outfitImage',
            'outputFormat': 'markdown',
          },
        ),
      ],
    ),
    // Quick Fit Check Template (Simplified version)
    ShortcutTemplate(
      id: 'quick-fit-check',
      name: 'Quick Fit Check',
      description: 'Get a quick vibe check on your outfit - perfect for when you need fast feedback!',
      icon: Icons.flash_on,
      category: 'life',
      components: [
        UIComponent(
          id: 'title',
          type: ComponentType.descriptionText,
          properties: {
            'title': '👗 Quick Fit Check 👖',
            'content': 'Snap a pic and get instant vibes on your fit!',
          },
        ),
        UIComponent(
          id: 'outfit-photo',
          type: ComponentType.imageInput,
          properties: {
            'label': 'Show me your fit! 📸',
            'allowCamera': true,
            'allowGallery': true,
            'maxImages': 1,
            'required': true,
          },
          variableBinding: 'fitPhoto',
        ),
        UIComponent(
          id: 'vibe-check',
          type: ComponentType.textInput,
          properties: {
            'label': 'Where you heading? (Optional)',
            'placeholder': 'e.g., brunch, work, date, just vibing',
            'required': false,
          },
          variableBinding: 'goingWhere',
        ),
        UIComponent(
          id: 'role-def',
          type: ComponentType.roleDefinition,
          properties: {
            'role': 'You are a Gen-Z fashion bestie who gives honest but hype fashion advice. You speak casually using modern slang and emojis, and you always gas up your friends while keeping it real.',
          },
        ),
        UIComponent(
          id: 'prompt',
          type: ComponentType.text,
          properties: {
            'content': '''Yo! Check out my fit and give me the vibe check! {{#if goingWhere}}I'm heading to {{goingWhere}}.{{/if}}

Drop your take in this format:

**The Vibe** ✨
Quick first impression - is it giving? What's the energy?

**Fire Elements** 🔥
2-3 things that are absolutely slaying

**Level Up Ideas** 📈
1-2 quick tweaks that would make this fit go even harder (keep it positive tho!)

**Final Verdict** 💯
Rate the fit and drop a hype comment!

Keep it:
- Short and snappy (this is a quick check!)
- Fun with emojis but not overboard
- Honest but always supportive
- Use current slang naturally (slay, fire, it's giving, ate, no cap, etc.)
- Like you're hyping up your bestie before they head out''',
          },
        ),
        UIComponent(
          id: 'final',
          type: ComponentType.finalPromptBuilder,
          properties: {
            'includeImage': true,
            'imageVariable': 'fitPhoto',
            'outputFormat': 'markdown',
          },
        ),
      ],
    ),
    // Professional Dress Code Analyzer
    ShortcutTemplate(
      id: 'dress-code-analyzer',
      name: 'Professional Dress Code Check',
      description: 'Ensure your outfit meets professional standards for work, interviews, or business events',
      icon: Icons.business_center,
      category: 'business',
      components: [
        UIComponent(
          id: 'title',
          type: ComponentType.descriptionText,
          properties: {
            'title': '💼 Professional Dress Code Analyzer',
            'content': 'Make sure your outfit is appropriate for professional settings',
          },
        ),
        UIComponent(
          id: 'outfit-upload',
          type: ComponentType.imageInput,
          properties: {
            'label': 'Upload Your Professional Outfit',
            'allowCamera': true,
            'allowGallery': true,
            'maxImages': 1,
            'required': true,
          },
          variableBinding: 'professionalOutfit',
        ),
        UIComponent(
          id: 'dress-code',
          type: ComponentType.dropdown,
          properties: {
            'label': 'What\'s your workplace dress code?',
            'options': [
              'Business Formal',
              'Business Professional',
              'Business Casual',
              'Smart Casual',
              'Creative/Startup Casual',
              'Not Sure'
            ],
            'required': true,
          },
          variableBinding: 'dressCode',
        ),
        UIComponent(
          id: 'event-type',
          type: ComponentType.singleSelect,
          properties: {
            'label': 'What\'s the occasion?',
            'options': [
              'Regular workday',
              'Important meeting',
              'Client presentation',
              'Job interview',
              'Company event',
              'Conference/Networking',
              'Video call'
            ],
          },
          variableBinding: 'eventType',
        ),
        UIComponent(
          id: 'industry',
          type: ComponentType.dropdown,
          properties: {
            'label': 'Industry/Field',
            'options': [
              'Finance/Banking',
              'Law',
              'Tech/Software',
              'Healthcare',
              'Education',
              'Creative/Design',
              'Consulting',
              'Real Estate',
              'Government',
              'Other'
            ],
          },
          variableBinding: 'industry',
        ),
        UIComponent(
          id: 'role-setup',
          type: ComponentType.roleDefinition,
          properties: {
            'role': 'You are a professional image consultant with extensive experience in corporate dress codes across various industries. You provide clear, practical advice on professional attire while being sensitive to individual style and comfort.',
          },
        ),
        UIComponent(
          id: 'context-setup',
          type: ComponentType.contextProvider,
          properties: {
            'context': 'The user needs to ensure their outfit is appropriate for {{eventType}} in the {{industry}} industry with a {{dressCode}} dress code.',
          },
        ),
        UIComponent(
          id: 'analysis-prompt',
          type: ComponentType.text,
          properties: {
            'content': '''Please analyze my professional outfit for appropriateness and impact.

**Dress Code Compliance** ✅
Does this outfit meet {{dressCode}} standards for {{industry}}? 
- Rate compliance: Fully Appropriate / Mostly Appropriate / Needs Adjustment
- Explain your assessment

**Professional Impact** 💼
- **First Impression**: What message does this outfit convey?
- **Authority & Credibility**: Does it project competence and professionalism?
- **Industry Appropriateness**: Is this suitable for {{industry}} culture?

**Detailed Analysis** 📋
Evaluate each element:
- **Top/Shirt**: Fit, color, style appropriateness
- **Bottom/Pants/Skirt**: Length, fit, formality level
- **Footwear**: Style and condition assessment
- **Accessories**: Are they enhancing or distracting?
- **Grooming/Overall Polish**: General presentation

**Areas of Excellence** ⭐
What aspects of this outfit work particularly well?

**Professional Recommendations** 📝
Provide 2-3 specific adjustments that would enhance professionalism:
- Be specific and actionable
- Consider the {{eventType}} context
- Respect the {{dressCode}} requirements

**Quick Tips for {{industry}}** 💡
Share 1-2 industry-specific dress code insights

**Confidence Builder** 🎯
End with encouragement about professional presentation

Note: Consider cultural sensitivity and avoid assumptions about body type or personal style preferences.''',
          },
        ),
        UIComponent(
          id: 'build-prompt',
          type: ComponentType.finalPromptBuilder,
          properties: {
            'includeImage': true,
            'imageVariable': 'professionalOutfit',
            'outputFormat': 'markdown',
          },
        ),
      ],
    ),
  ];
  
  static ShortcutTemplate? getTemplate(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
  
  static List<ShortcutTemplate> getByCategory(String category) {
    return templates.where((t) => t.category == category).toList();
  }
}

/// Shortcut template definition
class ShortcutTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String category;
  final List<UIComponent> components;
  
  const ShortcutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.components,
  });
}