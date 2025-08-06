import 'package:flutter/material.dart';
import '../../models/shortcuts/models.dart';

/// Service for managing preset/built-in shortcuts
class PresetShortcutsService {
  static final PresetShortcutsService _instance = PresetShortcutsService._internal();
  factory PresetShortcutsService() => _instance;
  PresetShortcutsService._internal();

  /// Get all preset shortcuts
  List<ShortcutDefinition> getPresetShortcuts() {
    return [
      _createAIWritingAssistant(),
      _createCustomerSupportTicket(),
      _createProductReviewGenerator(),
      _createLearningPlanBuilder(),
      _createCodeGeneratorAssistant(),
    ];
  }

  /// 1. AI Writing Assistant - Showcases Menu Logic branching
  ShortcutDefinition _createAIWritingAssistant() {
    final now = DateTime.now();
    final id = 'preset_ai_writing_assistant';
    
    // Create variables
    final variables = <String, VariableDefinition>{
      'articleType': VariableDefinition(
        name: 'articleType',
        type: VariableType.string,
        defaultValue: '',
        description: 'Type of article to write',
      ),
      'topic': VariableDefinition(
        name: 'topic',
        type: VariableType.string,
        defaultValue: '',
        description: 'Main topic of the article',
      ),
      'tone': VariableDefinition(
        name: 'tone',
        type: VariableType.string,
        defaultValue: 'professional',
        description: 'Writing tone',
      ),
      'writingGuidelines': VariableDefinition(
        name: 'writingGuidelines',
        type: VariableType.string,
        defaultValue: '',
        description: 'Generated writing guidelines',
      ),
      // Blog Post specific
      'keywords': VariableDefinition(
        name: 'keywords',
        type: VariableType.string,
        defaultValue: '',
        description: 'SEO keywords for the article',
      ),
      'targetAudience': VariableDefinition(
        name: 'targetAudience',
        type: VariableType.string,
        defaultValue: '',
        description: 'Target audience',
      ),
      // News Article specific
      'urgency': VariableDefinition(
        name: 'urgency',
        type: VariableType.number,
        defaultValue: 5,
        description: 'News urgency level',
      ),
      'source': VariableDefinition(
        name: 'source',
        type: VariableType.string,
        defaultValue: '',
        description: 'News source',
      ),
      // Technical Documentation specific
      'techDepth': VariableDefinition(
        name: 'techDepth',
        type: VariableType.string,
        defaultValue: '',
        description: 'Technical depth level',
      ),
      'includeCode': VariableDefinition(
        name: 'includeCode',
        type: VariableType.boolean,
        defaultValue: false,
        description: 'Include code examples',
      ),
      // Creative Story specific
      'genre': VariableDefinition(
        name: 'genre',
        type: VariableType.string,
        defaultValue: '',
        description: 'Story genre',
      ),
      'wordCount': VariableDefinition(
        name: 'wordCount',
        type: VariableType.number,
        defaultValue: 1000,
        description: 'Target word count',
      ),
    };

    // Create components
    final components = [
      // Title and Description
      UIComponent(
        id: 'desc_1',
        type: ComponentType.descriptionText,
        properties: {
          'title': 'AI Writing Assistant',
          'content': 'Let me help you create amazing content tailored to your needs.',
        },
      ),
      // Topic input
      UIComponent(
        id: 'topic_input',
        type: ComponentType.textInput,
        properties: {
          'label': 'What topic would you like to write about?',
          'placeholder': 'Enter your topic here...',
          'required': true,
        },
        variableBinding: 'topic',
      ),
      // Menu Logic for article type
      UIComponent(
        id: 'article_type_menu',
        type: ComponentType.groupContainer,
        properties: {
          'isComposite': true,
          'compositeType': 'CompositeComponentType.switchCase',
          'compositeData': {
            'id': 'article_type_switch',
            'type': 'CompositeComponentType.switchCase',
            'switchVariable': 'articleType',
            'caseOptions': ['Blog Post', 'News Article', 'Technical Documentation', 'Creative Story'],
            'sections': [
              {
                'id': 'article_type_switch_switch',
                'label': 'MENU',
                'type': 'CompositeSectionType.condition',
                'properties': {'variable': 'articleType'},
                'children': [],
              },
              // Blog Post branch
              {
                'id': 'article_type_switch_case_blog',
                'label': 'CASE "Blog Post"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Blog Post'},
                'children': [
                  {
                    'id': 'blog_keywords',
                    'component': {
                      'id': 'blog_keywords_comp',
                      'type': 'tagInput',
                      'properties': {
                        'label': 'SEO Keywords',
                        'placeholder': 'Add keywords...',
                      },
                      'variableBinding': 'keywords',
                    },
                    'order': 0,
                  },
                  {
                    'id': 'blog_audience',
                    'component': {
                      'id': 'blog_audience_comp',
                      'type': 'textInput',
                      'properties': {
                        'label': 'Target Audience',
                        'placeholder': 'Who is your target audience?',
                      },
                      'variableBinding': 'targetAudience',
                    },
                    'order': 1,
                  },
                ],
              },
              // News Article branch
              {
                'id': 'article_type_switch_case_news',
                'label': 'CASE "News Article"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'News Article'},
                'children': [
                  {
                    'id': 'news_urgency',
                    'component': {
                      'id': 'news_urgency_comp',
                      'type': 'slider',
                      'properties': {
                        'label': 'News Urgency Level',
                        'min': 1,
                        'max': 10,
                        'step': 1,
                        'showLabels': true,
                      },
                      'variableBinding': 'urgency',
                    },
                    'order': 0,
                  },
                  {
                    'id': 'news_source',
                    'component': {
                      'id': 'news_source_comp',
                      'type': 'textInput',
                      'properties': {
                        'label': 'News Source',
                        'placeholder': 'Enter the source of information',
                      },
                      'variableBinding': 'source',
                    },
                    'order': 1,
                  },
                ],
              },
              // Technical Documentation branch
              {
                'id': 'article_type_switch_case_tech',
                'label': 'CASE "Technical Documentation"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Technical Documentation'},
                'children': [
                  {
                    'id': 'tech_depth',
                    'component': {
                      'id': 'tech_depth_comp',
                      'type': 'singleSelect',
                      'properties': {
                        'label': 'Technical Depth',
                        'options': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
                      },
                      'variableBinding': 'techDepth',
                    },
                    'order': 0,
                  },
                  {
                    'id': 'code_examples',
                    'component': {
                      'id': 'code_examples_comp',
                      'type': 'toggle',
                      'properties': {
                        'label': 'Include Code Examples',
                      },
                      'variableBinding': 'includeCode',
                    },
                    'order': 1,
                  },
                ],
              },
              // Creative Story branch
              {
                'id': 'article_type_switch_case_creative',
                'label': 'CASE "Creative Story"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Creative Story'},
                'children': [
                  {
                    'id': 'story_genre',
                    'component': {
                      'id': 'story_genre_comp',
                      'type': 'dropdown',
                      'properties': {
                        'label': 'Story Genre',
                        'options': ['Fantasy', 'Sci-Fi', 'Mystery', 'Romance', 'Thriller'],
                      },
                      'variableBinding': 'genre',
                    },
                    'order': 0,
                  },
                  {
                    'id': 'story_length',
                    'component': {
                      'id': 'story_length_comp',
                      'type': 'numberInput',
                      'properties': {
                        'label': 'Approximate Word Count',
                        'min': 100,
                        'max': 10000,
                        'step': 100,
                      },
                      'variableBinding': 'wordCount',
                    },
                    'order': 1,
                  },
                ],
              },
              // Default branch
              {
                'id': 'article_type_switch_default',
                'label': 'DEFAULT',
                'type': 'CompositeSectionType.default_',
                'children': [],
              },
              // End Menu
              {
                'id': 'article_type_switch_endswitch',
                'label': 'END MENU',
                'type': 'CompositeSectionType.terminator',
                'children': [],
              },
            ],
          },
        },
      ),
      // Tone selection
      UIComponent(
        id: 'tone_select',
        type: ComponentType.singleSelect,
        properties: {
          'label': 'Select Writing Tone',
          'options': ['Professional', 'Casual', 'Friendly', 'Formal', 'Humorous', 'Inspirational'],
          'required': true,
        },
        variableBinding: 'tone',
      ),
      // Text component for guidelines
      UIComponent(
        id: 'guidelines_text',
        type: ComponentType.text,
        properties: {
          'content': 'Based on your selections, I will create {{articleType}} about {{topic}} with a {{tone}} tone.{{#if keywords}} Keywords: {{keywords}}.{{/if}}{{#if targetAudience}} Target audience: {{targetAudience}}.{{/if}}{{#if urgency}} Urgency level: {{urgency}}/10.{{/if}}{{#if source}} Source: {{source}}.{{/if}}{{#if techDepth}} Technical depth: {{techDepth}}.{{/if}}{{#if includeCode}} Code examples will be included.{{/if}}{{#if genre}} Genre: {{genre}}.{{/if}}{{#if wordCount}} Target length: {{wordCount}} words.{{/if}}',
          'outputVariable': 'writingGuidelines',
        },
      ),
      // Final Prompt Builder
      UIComponent(
        id: 'final_prompt',
        type: ComponentType.finalPromptBuilder,
        properties: {
          'promptTemplate': 'Write a {{tone}} {{articleType}} about "{{topic}}".\n\nWriting Guidelines:\n{{writingGuidelines}}\n\n{{#if articleType == "Blog Post"}}SEO Requirements:\n- Keywords to include: {{keywords}}\n- Target audience: {{targetAudience}}\n- Optimize for search engines while maintaining readability\n{{/if}}{{#if articleType == "News Article"}}News Requirements:\n- Urgency level: {{urgency}}/10\n- Information source: {{source}}\n- Follow journalistic standards and inverted pyramid structure\n{{/if}}{{#if articleType == "Technical Documentation"}}Technical Requirements:\n- Technical depth: {{techDepth}}\n- Include code examples: {{includeCode}}\n- Use clear technical terminology and structure\n{{/if}}{{#if articleType == "Creative Story"}}Story Requirements:\n- Genre: {{genre}}\n- Target word count: {{wordCount}} words\n- Include compelling narrative and character development\n{{/if}}\nAdditional requirements:\n- Make it engaging and informative\n- Use clear and concise language\n- Include relevant examples where appropriate',
        },
      ),
    ];

    // Create screens
    final screens = [
      ScreenDefinition(
        id: 'main',
        title: 'AI Writing Assistant',
        components: components,
        actions: {},
      ),
    ];

    return ShortcutDefinition(
      id: id,
      name: 'AI Writing Assistant',
      description: 'Create amazing content with AI-powered writing assistance',
      category: 'productivity',
      icon: ShortcutIcon(iconData: Icons.edit_note, color: Colors.blue),
      screens: screens,
      startScreenId: 'main',
      transitions: {},
      variables: variables,
      promptTemplate: PromptTemplate(
        sections: [],
        assemblyLogic: 'final_prompt',
      ),
      version: '1.0.0',
      author: 'System',
      isBuiltIn: true,
      createdAt: now,
      updatedAt: now,
      usageCount: 0,
    );
  }

  /// 2. Customer Support Ticket - Showcases IF-ELSE conditions
  ShortcutDefinition _createCustomerSupportTicket() {
    final now = DateTime.now();
    final id = 'preset_customer_support';
    
    final variables = <String, VariableDefinition>{
      'urgencyLevel': VariableDefinition(
        name: 'urgencyLevel',
        type: VariableType.number,
        defaultValue: 5,
        description: 'Urgency level of the issue',
      ),
      'issueType': VariableDefinition(
        name: 'issueType',
        type: VariableType.string,
        defaultValue: '',
        description: 'Type of issue',
      ),
      'customerEmail': VariableDefinition(
        name: 'customerEmail',
        type: VariableType.string,
        defaultValue: '',
        description: 'Customer email address',
      ),
      'issueDescription': VariableDefinition(
        name: 'issueDescription',
        type: VariableType.string,
        defaultValue: '',
        description: 'Detailed issue description',
      ),
      'processingStrategy': VariableDefinition(
        name: 'processingStrategy',
        type: VariableType.string,
        defaultValue: '',
        description: 'How to process this ticket',
      ),
    };

    final components = [
      UIComponent(
        id: 'title_2',
        type: ComponentType.descriptionText,
        properties: {
          'title': 'Customer Support Ticket System',
          'content': 'Create and manage support tickets efficiently',
        },
      ),
      UIComponent(
        id: 'urgency_slider',
        type: ComponentType.slider,
        properties: {
          'label': 'Issue Urgency Level',
          'min': 1,
          'max': 10,
          'step': 1,
          'showLabels': true,
        },
        variableBinding: 'urgencyLevel',
      ),
      UIComponent(
        id: 'issue_type_select',
        type: ComponentType.singleSelect,
        properties: {
          'label': 'Issue Type',
          'options': ['Technical Problem', 'Billing Issue', 'Feature Request', 'Account Access', 'General Inquiry'],
          'required': true,
        },
        variableBinding: 'issueType',
      ),
      UIComponent(
        id: 'customer_email_input',
        type: ComponentType.textInput,
        properties: {
          'label': 'Customer Email',
          'placeholder': 'customer@example.com',
          'required': true,
        },
        variableBinding: 'customerEmail',
      ),
      UIComponent(
        id: 'issue_description_input',
        type: ComponentType.multilineTextInput,
        properties: {
          'label': 'Issue Description',
          'placeholder': 'Please describe the issue in detail...',
          'rows': 5,
          'required': true,
        },
        variableBinding: 'issueDescription',
      ),
      // IF-ELSE Logic for urgency handling
      UIComponent(
        id: 'urgency_logic',
        type: ComponentType.groupContainer,
        properties: {
          'isComposite': true,
          'compositeType': 'CompositeComponentType.ifElse',
          'compositeData': {
            'id': 'urgency_if_else',
            'type': 'CompositeComponentType.ifElse',
            'conditionExpression': 'urgencyLevel > 7',
            'sections': [
              {
                'id': 'urgency_if_else_if',
                'label': 'IF',
                'type': 'CompositeSectionType.condition',
                'properties': {'expression': 'urgencyLevel > 7'},
                'children': [],
              },
              {
                'id': 'urgency_if_else_then',
                'label': 'THEN',
                'type': 'CompositeSectionType.branch',
                'children': [
                  {
                    'id': 'urgent_text',
                    'component': {
                      'id': 'urgent_text_comp',
                      'type': 'text',
                      'properties': {
                        'content': 'URGENT: This ticket requires immediate attention. Escalating to senior support team.',
                        'outputVariable': 'processingStrategy',
                      },
                    },
                    'order': 0,
                  },
                  {
                    'id': 'urgent_priority',
                    'component': {
                      'id': 'urgent_priority_comp',
                      'type': 'descriptionText',
                      'properties': {
                        'title': '🚨 HIGH PRIORITY TICKET',
                        'content': 'This ticket requires immediate attention',
                      },
                    },
                    'order': 1,
                  },
                ],
              },
              {
                'id': 'urgency_if_else_elseif_1',
                'label': 'ELSE IF',
                'type': 'CompositeSectionType.branch',
                'properties': {'expression': 'urgencyLevel > 4'},
                'children': [
                  {
                    'id': 'moderate_text',
                    'component': {
                      'id': 'moderate_text_comp',
                      'type': 'text',
                      'properties': {
                        'content': 'MODERATE: Standard processing with expected resolution within 24 hours.',
                        'outputVariable': 'processingStrategy',
                      },
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'urgency_if_else_else',
                'label': 'ELSE',
                'type': 'CompositeSectionType.branch',
                'children': [
                  {
                    'id': 'low_text',
                    'component': {
                      'id': 'low_text_comp',
                      'type': 'text',
                      'properties': {
                        'content': 'ROUTINE: Added to regular queue for processing within 48-72 hours.',
                        'outputVariable': 'processingStrategy',
                      },
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'urgency_if_else_endif',
                'label': 'END IF',
                'type': 'CompositeSectionType.terminator',
                'children': [],
              },
            ],
          },
        },
      ),
      UIComponent(
        id: 'final_prompt_2',
        type: ComponentType.finalPromptBuilder,
        properties: {
          'promptTemplate': 'Create a support ticket response for:\n\nCustomer: {{customerEmail}}\nIssue Type: {{issueType}}\nUrgency Level: {{urgencyLevel}}/10\n\nProcessing Strategy:\n{{processingStrategy}}\n\nIssue Description:\n{{issueDescription}}\n\nPlease provide a professional, empathetic response that addresses the issue and sets clear expectations for resolution.',
        },
      ),
    ];

    final screens = [
      ScreenDefinition(
        id: 'main',
        title: 'Customer Support Ticket',
        components: components,
        actions: {},
      ),
    ];

    return ShortcutDefinition(
      id: id,
      name: 'Customer Support Ticket',
      description: 'Intelligent ticket routing based on urgency and issue type',
      category: 'business',
      icon: ShortcutIcon(iconData: Icons.support_agent, color: Colors.orange),
      screens: screens,
      startScreenId: 'main',
      transitions: {},
      variables: variables,
      promptTemplate: PromptTemplate(
        sections: [],
        assemblyLogic: 'final_prompt',
      ),
      version: '1.0.0',
      author: 'System',
      isBuiltIn: true,
      createdAt: now,
      updatedAt: now,
      usageCount: 0,
    );
  }

  /// 3. Product Review Generator - Showcases comprehensive data collection
  ShortcutDefinition _createProductReviewGenerator() {
    final now = DateTime.now();
    final id = 'preset_product_review';
    
    final variables = <String, VariableDefinition>{
      'productName': VariableDefinition(
        name: 'productName',
        type: VariableType.string,
        defaultValue: '',
        description: 'Name of the product',
      ),
      'productCategory': VariableDefinition(
        name: 'productCategory',
        type: VariableType.string,
        defaultValue: '',
        description: 'Product category',
      ),
      'features': VariableDefinition(
        name: 'features',
        type: VariableType.list,
        defaultValue: [],
        description: 'Product features',
      ),
      'pros': VariableDefinition(
        name: 'pros',
        type: VariableType.string,
        defaultValue: '',
        description: 'Product advantages',
      ),
      'cons': VariableDefinition(
        name: 'cons',
        type: VariableType.string,
        defaultValue: '',
        description: 'Product disadvantages',
      ),
      'rating': VariableDefinition(
        name: 'rating',
        type: VariableType.number,
        defaultValue: 3,
        description: 'Overall rating',
      ),
      'price': VariableDefinition(
        name: 'price',
        type: VariableType.number,
        defaultValue: 0,
        description: 'Product price',
      ),
      'reviewFramework': VariableDefinition(
        name: 'reviewFramework',
        type: VariableType.string,
        defaultValue: '',
        description: 'Review structure',
      ),
    };

    final components = [
      UIComponent(
        id: 'desc_3',
        type: ComponentType.descriptionText,
        properties: {
          'title': 'Product Review Generator',
          'content': 'Create comprehensive product reviews with detailed analysis',
        },
      ),
      UIComponent(
        id: 'product_name_input',
        type: ComponentType.textInput,
        properties: {
          'label': 'Product Name',
          'placeholder': 'Enter product name...',
          'required': true,
        },
        variableBinding: 'productName',
      ),
      UIComponent(
        id: 'product_category_dropdown',
        type: ComponentType.dropdown,
        properties: {
          'label': 'Product Category',
          'options': ['Electronics', 'Home & Garden', 'Fashion', 'Books', 'Toys & Games', 'Sports', 'Health & Beauty', 'Food & Beverages'],
        },
        variableBinding: 'productCategory',
      ),
      UIComponent(
        id: 'features_select',
        type: ComponentType.multiSelect,
        properties: {
          'label': 'Key Features (select all that apply)',
          'options': ['High Quality', 'Durable', 'Eco-Friendly', 'User-Friendly', 'Innovative Design', 'Good Value', 'Warranty Included', 'Fast Shipping'],
        },
        variableBinding: 'features',
      ),
      UIComponent(
        id: 'pros_input',
        type: ComponentType.tagInput,
        properties: {
          'label': 'Pros (add multiple)',
          'placeholder': 'Add advantages...',
        },
        variableBinding: 'pros',
      ),
      UIComponent(
        id: 'cons_input',
        type: ComponentType.tagInput,
        properties: {
          'label': 'Cons (add multiple)',
          'placeholder': 'Add disadvantages...',
        },
        variableBinding: 'cons',
      ),
      UIComponent(
        id: 'rating_slider',
        type: ComponentType.slider,
        properties: {
          'label': 'Overall Rating',
          'min': 1,
          'max': 5,
          'step': 0.5,
          'showLabels': true,
        },
        variableBinding: 'rating',
      ),
      UIComponent(
        id: 'price_input',
        type: ComponentType.numberInput,
        properties: {
          'label': 'Price (USD)',
          'min': 0,
          'max': 10000,
          'step': 1,
        },
        variableBinding: 'price',
      ),
      UIComponent(
        id: 'review_framework_text',
        type: ComponentType.text,
        properties: {
          'content': 'Product: {{productName}}\nCategory: {{productCategory}}\nRating: {{rating}} stars\nPrice: \${{price}}\n\nKey Features: {{features}}\nPros: {{pros}}\nCons: {{cons}}',
          'outputVariable': 'reviewFramework',
        },
      ),
      UIComponent(
        id: 'final_prompt_3',
        type: ComponentType.finalPromptBuilder,
        properties: {
          'promptTemplate': 'Write a detailed product review for:\n\n{{reviewFramework}}\n\nThe review should be:\n- Balanced and objective\n- Include specific examples\n- Mention value for money\n- Provide a clear recommendation\n- Be approximately 500 words',
        },
      ),
    ];

    final screens = [
      ScreenDefinition(
        id: 'main',
        title: 'Product Review Generator',
        components: components,
        actions: {},
      ),
    ];

    return ShortcutDefinition(
      id: id,
      name: 'Product Review Generator',
      description: 'Generate comprehensive product reviews with ratings',
      category: 'business',
      icon: ShortcutIcon(iconData: Icons.star_rate, color: Colors.amber),
      screens: screens,
      startScreenId: 'main',
      transitions: {},
      variables: variables,
      promptTemplate: PromptTemplate(
        sections: [],
        assemblyLogic: 'final_prompt',
      ),
      version: '1.0.0',
      author: 'System',
      isBuiltIn: true,
      createdAt: now,
      updatedAt: now,
      usageCount: 0,
    );
  }

  /// 4. Learning Plan Builder - Showcases nested logic
  ShortcutDefinition _createLearningPlanBuilder() {
    final now = DateTime.now();
    final id = 'preset_learning_plan';
    
    final variables = <String, VariableDefinition>{
      'subject': VariableDefinition(
        name: 'subject',
        type: VariableType.string,
        defaultValue: '',
        description: 'Learning subject',
      ),
      'currentLevel': VariableDefinition(
        name: 'currentLevel',
        type: VariableType.string,
        defaultValue: 'beginner',
        description: 'Current skill level',
      ),
      'targetLevel': VariableDefinition(
        name: 'targetLevel',
        type: VariableType.string,
        defaultValue: 'intermediate',
        description: 'Target skill level',
      ),
      'timeAvailable': VariableDefinition(
        name: 'timeAvailable',
        type: VariableType.number,
        defaultValue: 30,
        description: 'Available time in days',
      ),
      'learningStyle': VariableDefinition(
        name: 'learningStyle',
        type: VariableType.list,
        defaultValue: [],
        description: 'Preferred learning styles',
      ),
      'startDate': VariableDefinition(
        name: 'startDate',
        type: VariableType.date,
        defaultValue: null,
        description: 'Plan start date',
      ),
      'difficulty': VariableDefinition(
        name: 'difficulty',
        type: VariableType.string,
        defaultValue: '',
        description: 'Learning difficulty assessment',
      ),
      // Programming specific
      'programmingLanguage': VariableDefinition(
        name: 'programmingLanguage',
        type: VariableType.string,
        defaultValue: '',
        description: 'Programming language to learn',
      ),
      'projectType': VariableDefinition(
        name: 'projectType',
        type: VariableType.string,
        defaultValue: '',
        description: 'Type of project to build',
      ),
      // Language Learning specific
      'targetLanguage': VariableDefinition(
        name: 'targetLanguage',
        type: VariableType.string,
        defaultValue: '',
        description: 'Language to learn',
      ),
      'languageGoal': VariableDefinition(
        name: 'languageGoal',
        type: VariableType.string,
        defaultValue: '',
        description: 'Purpose of learning the language',
      ),
      // Design specific
      'designTools': VariableDefinition(
        name: 'designTools',
        type: VariableType.list,
        defaultValue: [],
        description: 'Design tools to learn',
      ),
      // Music specific
      'instrument': VariableDefinition(
        name: 'instrument',
        type: VariableType.string,
        defaultValue: '',
        description: 'Musical instrument to learn',
      ),
    };

    final components = [
      UIComponent(
        id: 'title_4',
        type: ComponentType.descriptionText,
        properties: {
          'title': 'Personalized Learning Plan Builder',
          'content': 'Create a customized learning plan tailored to your goals',
        },
      ),
      // Menu Logic for subject selection
      UIComponent(
        id: 'subject_menu',
        type: ComponentType.groupContainer,
        properties: {
          'isComposite': true,
          'compositeType': 'CompositeComponentType.switchCase',
          'compositeData': {
            'id': 'subject_switch',
            'type': 'CompositeComponentType.switchCase',
            'switchVariable': 'subject',
            'caseOptions': ['Programming', 'Language Learning', 'Design', 'Music'],
            'sections': [
              {
                'id': 'subject_switch_switch',
                'label': 'MENU',
                'type': 'CompositeSectionType.condition',
                'properties': {'variable': 'subject'},
                'children': [],
              },
              {
                'id': 'subject_switch_case_prog',
                'label': 'CASE "Programming"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Programming'},
                'children': [
                  {
                    'id': 'prog_lang',
                    'component': {
                      'id': 'prog_lang_comp',
                      'type': 'dropdown',
                      'properties': {
                        'label': 'Programming Language',
                        'options': ['Python', 'JavaScript', 'Java', 'C++', 'Go', 'Rust'],
                      },
                      'variableBinding': 'programmingLanguage',
                    },
                    'order': 0,
                  },
                  {
                    'id': 'prog_project',
                    'component': {
                      'id': 'prog_project_comp',
                      'type': 'singleSelect',
                      'properties': {
                        'label': 'Project Type',
                        'options': ['Web App', 'Mobile App', 'Data Science', 'Game Development', 'System Programming'],
                      },
                      'variableBinding': 'projectType',
                    },
                    'order': 1,
                  },
                ],
              },
              {
                'id': 'subject_switch_case_lang',
                'label': 'CASE "Language Learning"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Language Learning'},
                'children': [
                  {
                    'id': 'target_lang',
                    'component': {
                      'id': 'target_lang_comp',
                      'type': 'dropdown',
                      'properties': {
                        'label': 'Target Language',
                        'options': ['Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Korean'],
                      },
                      'variableBinding': 'targetLanguage',
                    },
                    'order': 0,
                  },
                  {
                    'id': 'lang_goal',
                    'component': {
                      'id': 'lang_goal_comp',
                      'type': 'singleSelect',
                      'properties': {
                        'label': 'Learning Goal',
                        'options': ['Travel', 'Business', 'Academic', 'Cultural Interest'],
                      },
                      'variableBinding': 'languageGoal',
                    },
                    'order': 1,
                  },
                ],
              },
              {
                'id': 'subject_switch_case_design',
                'label': 'CASE "Design"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Design'},
                'children': [
                  {
                    'id': 'design_tool',
                    'component': {
                      'id': 'design_tool_comp',
                      'type': 'multiSelect',
                      'properties': {
                        'label': 'Design Tools',
                        'options': ['Photoshop', 'Illustrator', 'Figma', 'Sketch', 'After Effects'],
                      },
                      'variableBinding': 'designTools',
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'subject_switch_case_music',
                'label': 'CASE "Music"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Music'},
                'children': [
                  {
                    'id': 'instrument',
                    'component': {
                      'id': 'instrument_comp',
                      'type': 'dropdown',
                      'properties': {
                        'label': 'Instrument',
                        'options': ['Piano', 'Guitar', 'Violin', 'Drums', 'Voice'],
                      },
                      'variableBinding': 'instrument',
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'subject_switch_default',
                'label': 'DEFAULT',
                'type': 'CompositeSectionType.default_',
                'children': [],
              },
              {
                'id': 'subject_switch_endswitch',
                'label': 'END MENU',
                'type': 'CompositeSectionType.terminator',
                'children': [],
              },
            ],
          },
        },
      ),
      UIComponent(
        id: 'current_level_select',
        type: ComponentType.singleSelect,
        properties: {
          'label': 'Current Skill Level',
          'options': ['Complete Beginner', 'Beginner', 'Intermediate', 'Advanced', 'Expert'],
          'required': true,
        },
        variableBinding: 'currentLevel',
      ),
      UIComponent(
        id: 'target_level_select',
        type: ComponentType.singleSelect,
        properties: {
          'label': 'Target Skill Level',
          'options': ['Beginner', 'Intermediate', 'Advanced', 'Expert', 'Master'],
          'required': true,
        },
        variableBinding: 'targetLevel',
      ),
      UIComponent(
        id: 'time_slider',
        type: ComponentType.slider,
        properties: {
          'label': 'Available Time (days)',
          'min': 7,
          'max': 365,
          'step': 7,
          'showLabels': true,
        },
        variableBinding: 'timeAvailable',
      ),
      UIComponent(
        id: 'learning_style_select',
        type: ComponentType.multiSelect,
        properties: {
          'label': 'Preferred Learning Styles',
          'options': ['Video Tutorials', 'Books', 'Interactive Exercises', 'Projects', 'Mentorship', 'Group Study'],
        },
        variableBinding: 'learningStyle',
      ),
      UIComponent(
        id: 'start_date_picker',
        type: ComponentType.dateTimePicker,
        properties: {
          'label': 'Start Date',
          'mode': 'date',
        },
        variableBinding: 'startDate',
      ),
      // Nested IF-ELSE for difficulty assessment
      UIComponent(
        id: 'difficulty_logic',
        type: ComponentType.groupContainer,
        properties: {
          'isComposite': true,
          'compositeType': 'CompositeComponentType.ifElse',
          'compositeData': {
            'id': 'difficulty_assessment',
            'type': 'CompositeComponentType.ifElse',
            'conditionExpression': 'currentLevel == "Complete Beginner" && targetLevel == "Expert"',
            'sections': [
              {
                'id': 'difficulty_if',
                'label': 'IF',
                'type': 'CompositeSectionType.condition',
                'properties': {'expression': 'currentLevel == "Complete Beginner" && targetLevel == "Expert"'},
                'children': [],
              },
              {
                'id': 'difficulty_then',
                'label': 'THEN',
                'type': 'CompositeSectionType.branch',
                'children': [
                  {
                    'id': 'very_challenging',
                    'component': {
                      'id': 'very_challenging_comp',
                      'type': 'text',
                      'properties': {
                        'content': 'This is a very ambitious goal! We will create an intensive, structured learning path with milestone checkpoints.',
                        'outputVariable': 'difficulty',
                      },
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'difficulty_else',
                'label': 'ELSE',
                'type': 'CompositeSectionType.branch',
                'children': [
                  {
                    'id': 'achievable',
                    'component': {
                      'id': 'achievable_comp',
                      'type': 'text',
                      'properties': {
                        'content': 'Great goal! We will create a balanced learning plan to help you reach your target.',
                        'outputVariable': 'difficulty',
                      },
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'difficulty_endif',
                'label': 'END IF',
                'type': 'CompositeSectionType.terminator',
                'children': [],
              },
            ],
          },
        },
      ),
      UIComponent(
        id: 'final_prompt_4',
        type: ComponentType.finalPromptBuilder,
        properties: {
          'promptTemplate': 'Create a personalized {{timeAvailable}}-day learning plan for:\n\nSubject: {{subject}}\n{{#if subject == "Programming"}}Programming Language: {{programmingLanguage}}\nProject Type: {{projectType}}\n{{/if}}{{#if subject == "Language Learning"}}Target Language: {{targetLanguage}}\nLearning Goal: {{languageGoal}}\n{{/if}}{{#if subject == "Design"}}Design Tools to Learn: {{designTools}}\n{{/if}}{{#if subject == "Music"}}Instrument: {{instrument}}\n{{/if}}Current Level: {{currentLevel}}\nTarget Level: {{targetLevel}}\n\nAssessment: {{difficulty}}\n\nPreferred Learning Styles: {{learningStyle}}\nStart Date: {{startDate}}\n\nPlease include:\n- Weekly milestones\n- Recommended resources specific to {{#if programmingLanguage}}{{programmingLanguage}}{{/if}}{{#if targetLanguage}}{{targetLanguage}}{{/if}}{{#if designTools}}{{designTools}}{{/if}}{{#if instrument}}{{instrument}}{{/if}}\n- Practice exercises\n- Progress checkpoints\n- Time management tips\n{{#if projectType}}- Project-based learning focused on {{projectType}}{{/if}}\n{{#if languageGoal}}- Content tailored for {{languageGoal}} purposes{{/if}}',
        },
      ),
    ];

    final screens = [
      ScreenDefinition(
        id: 'main',
        title: 'Learning Plan Builder',
        components: components,
        actions: {},
      ),
    ];

    return ShortcutDefinition(
      id: id,
      name: 'Learning Plan Builder',
      description: 'Create personalized learning roadmaps for any skill',
      category: 'education',
      icon: ShortcutIcon(iconData: Icons.school, color: Colors.green),
      screens: screens,
      startScreenId: 'main',
      transitions: {},
      variables: variables,
      promptTemplate: PromptTemplate(
        sections: [],
        assemblyLogic: 'final_prompt',
      ),
      version: '1.0.0',
      author: 'System',
      isBuiltIn: true,
      createdAt: now,
      updatedAt: now,
      usageCount: 0,
    );
  }

  /// 5. Code Generator Assistant - Showcases complex logic combinations
  ShortcutDefinition _createCodeGeneratorAssistant() {
    final now = DateTime.now();
    final id = 'preset_code_generator';
    
    final variables = <String, VariableDefinition>{
      'language': VariableDefinition(
        name: 'language',
        type: VariableType.string,
        defaultValue: '',
        description: 'Programming language',
      ),
      'framework': VariableDefinition(
        name: 'framework',
        type: VariableType.string,
        defaultValue: '',
        description: 'Framework to use',
      ),
      'functionality': VariableDefinition(
        name: 'functionality',
        type: VariableType.string,
        defaultValue: '',
        description: 'Code functionality description',
      ),
      'codeFeatures': VariableDefinition(
        name: 'codeFeatures',
        type: VariableType.list,
        defaultValue: [],
        description: 'Code features to include',
      ),
      'includeTests': VariableDefinition(
        name: 'includeTests',
        type: VariableType.boolean,
        defaultValue: false,
        description: 'Include test code',
      ),
      'includeComments': VariableDefinition(
        name: 'includeComments',
        type: VariableType.boolean,
        defaultValue: true,
        description: 'Include code comments',
      ),
      'codeStyle': VariableDefinition(
        name: 'codeStyle',
        type: VariableType.string,
        defaultValue: 'clean',
        description: 'Code style preference',
      ),
      'codeSpecs': VariableDefinition(
        name: 'codeSpecs',
        type: VariableType.string,
        defaultValue: '',
        description: 'Generated code specifications',
      ),
      'testFramework': VariableDefinition(
        name: 'testFramework',
        type: VariableType.string,
        defaultValue: '',
        description: 'Testing framework to use',
      ),
    };

    final components = [
      UIComponent(
        id: 'desc_5',
        type: ComponentType.descriptionText,
        properties: {
          'title': 'Smart Code Generator',
          'content': 'Generate production-ready code with your specifications',
        },
      ),
      UIComponent(
        id: 'functionality_input',
        type: ComponentType.multilineTextInput,
        properties: {
          'label': 'What do you want the code to do?',
          'placeholder': 'Describe the functionality in detail...',
          'rows': 4,
          'required': true,
        },
        variableBinding: 'functionality',
      ),
      // Menu Logic for language selection
      UIComponent(
        id: 'language_menu',
        type: ComponentType.groupContainer,
        properties: {
          'isComposite': true,
          'compositeType': 'CompositeComponentType.switchCase',
          'compositeData': {
            'id': 'language_switch',
            'type': 'CompositeComponentType.switchCase',
            'switchVariable': 'language',
            'caseOptions': ['Python', 'JavaScript', 'Java', 'Go', 'TypeScript'],
            'sections': [
              {
                'id': 'language_switch_switch',
                'label': 'MENU',
                'type': 'CompositeSectionType.condition',
                'properties': {'variable': 'language'},
                'children': [],
              },
              {
                'id': 'language_switch_case_python',
                'label': 'CASE "Python"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Python'},
                'children': [
                  {
                    'id': 'python_framework',
                    'component': {
                      'id': 'python_framework_comp',
                      'type': 'dropdown',
                      'properties': {
                        'label': 'Python Framework',
                        'options': ['None', 'Django', 'Flask', 'FastAPI', 'Pandas', 'NumPy'],
                      },
                      'variableBinding': 'framework',
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'language_switch_case_js',
                'label': 'CASE "JavaScript"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'JavaScript'},
                'children': [
                  {
                    'id': 'js_framework',
                    'component': {
                      'id': 'js_framework_comp',
                      'type': 'dropdown',
                      'properties': {
                        'label': 'JavaScript Framework',
                        'options': ['None', 'React', 'Vue', 'Angular', 'Express', 'Next.js'],
                      },
                      'variableBinding': 'framework',
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'language_switch_case_java',
                'label': 'CASE "Java"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Java'},
                'children': [
                  {
                    'id': 'java_framework',
                    'component': {
                      'id': 'java_framework_comp',
                      'type': 'dropdown',
                      'properties': {
                        'label': 'Java Framework',
                        'options': ['None', 'Spring Boot', 'Spring MVC', 'Hibernate', 'Struts'],
                      },
                      'variableBinding': 'framework',
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'language_switch_case_go',
                'label': 'CASE "Go"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'Go'},
                'children': [
                  {
                    'id': 'go_framework',
                    'component': {
                      'id': 'go_framework_comp',
                      'type': 'dropdown',
                      'properties': {
                        'label': 'Go Framework',
                        'options': ['None', 'Gin', 'Echo', 'Fiber', 'Beego'],
                      },
                      'variableBinding': 'framework',
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'language_switch_case_ts',
                'label': 'CASE "TypeScript"',
                'type': 'CompositeSectionType.caseOption',
                'properties': {'value': 'TypeScript'},
                'children': [
                  {
                    'id': 'ts_framework',
                    'component': {
                      'id': 'ts_framework_comp',
                      'type': 'dropdown',
                      'properties': {
                        'label': 'TypeScript Framework',
                        'options': ['None', 'NestJS', 'Express + TypeScript', 'Angular', 'React + TypeScript'],
                      },
                      'variableBinding': 'framework',
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'language_switch_default',
                'label': 'DEFAULT',
                'type': 'CompositeSectionType.default_',
                'children': [],
              },
              {
                'id': 'language_switch_endswitch',
                'label': 'END MENU',
                'type': 'CompositeSectionType.terminator',
                'children': [],
              },
            ],
          },
        },
      ),
      UIComponent(
        id: 'code_features_select',
        type: ComponentType.multiSelect,
        properties: {
          'label': 'Code Features',
          'options': ['Async/Await', 'Error Handling', 'Logging', 'Input Validation', 'Performance Optimization', 'Security Best Practices'],
        },
        variableBinding: 'codeFeatures',
      ),
      UIComponent(
        id: 'include_tests_toggle',
        type: ComponentType.toggle,
        properties: {
          'label': 'Include Unit Tests',
        },
        variableBinding: 'includeTests',
      ),
      // IF-ELSE for test framework selection
      UIComponent(
        id: 'test_logic',
        type: ComponentType.groupContainer,
        properties: {
          'isComposite': true,
          'compositeType': 'CompositeComponentType.ifElse',
          'compositeData': {
            'id': 'test_if_else',
            'type': 'CompositeComponentType.ifElse',
            'conditionExpression': 'includeTests == true',
            'sections': [
              {
                'id': 'test_if',
                'label': 'IF',
                'type': 'CompositeSectionType.condition',
                'properties': {'expression': 'includeTests == true'},
                'children': [],
              },
              {
                'id': 'test_then',
                'label': 'THEN',
                'type': 'CompositeSectionType.branch',
                'children': [
                  {
                    'id': 'test_framework',
                    'component': {
                      'id': 'test_framework_comp',
                      'type': 'singleSelect',
                      'properties': {
                        'label': 'Testing Framework',
                        'options': ['Default for Language', 'Jest', 'Pytest', 'JUnit', 'Go Test', 'Mocha'],
                      },
                      'variableBinding': 'testFramework',
                    },
                    'order': 0,
                  },
                ],
              },
              {
                'id': 'test_else',
                'label': 'ELSE',
                'type': 'CompositeSectionType.branch',
                'children': [],
              },
              {
                'id': 'test_endif',
                'label': 'END IF',
                'type': 'CompositeSectionType.terminator',
                'children': [],
              },
            ],
          },
        },
      ),
      UIComponent(
        id: 'include_comments_toggle',
        type: ComponentType.toggle,
        properties: {
          'label': 'Include Comments',
        },
        variableBinding: 'includeComments',
      ),
      UIComponent(
        id: 'code_style_select',
        type: ComponentType.singleSelect,
        properties: {
          'label': 'Code Style',
          'options': ['Clean & Minimal', 'Detailed & Verbose', 'Performance Optimized', 'Enterprise Standard'],
        },
        variableBinding: 'codeStyle',
      ),
      UIComponent(
        id: 'code_specs_text',
        type: ComponentType.text,
        properties: {
          'content': 'Language: {{language}}\nFramework: {{framework}}\nFeatures: {{codeFeatures}}\nTests: {{includeTests}}{{#if includeTests}}\nTest Framework: {{testFramework}}{{/if}}\nComments: {{includeComments}}\nStyle: {{codeStyle}}',
          'outputVariable': 'codeSpecs',
        },
      ),
      UIComponent(
        id: 'final_prompt_5',
        type: ComponentType.finalPromptBuilder,
        properties: {
          'promptTemplate': 'Generate {{language}} code with the following specifications:\n\n{{codeSpecs}}\n\nFunctionality Requirements:\n{{functionality}}\n\nCode Requirements:\n- Use {{framework}} framework\n- Follow {{codeStyle}} coding style\n- Include comprehensive error handling\n- Follow best practices for {{language}}\n- Make the code production-ready\n{{#if includeTests}}- Include complete unit tests using {{testFramework}} framework{{/if}}\n{{#if includeComments}}- Add detailed comments{{/if}}\n\nSpecific Features to Include:\n{{codeFeatures}}\n\nEnsure the code is:\n- Well-structured and modular\n- Properly typed (if applicable)\n- Following SOLID principles\n- Ready for deployment',
        },
      ),
    ];

    final screens = [
      ScreenDefinition(
        id: 'main',
        title: 'Code Generator',
        components: components,
        actions: {},
      ),
    ];

    return ShortcutDefinition(
      id: id,
      name: 'Code Generator Assistant',
      description: 'Generate production-ready code with custom specifications',
      category: 'development',
      icon: ShortcutIcon(iconData: Icons.code, color: Colors.purple),
      screens: screens,
      startScreenId: 'main',
      transitions: {},
      variables: variables,
      promptTemplate: PromptTemplate(
        sections: [],
        assemblyLogic: 'final_prompt',
      ),
      version: '1.0.0',
      author: 'System',
      isBuiltIn: true,
      createdAt: now,
      updatedAt: now,
      usageCount: 0,
    );
  }
}