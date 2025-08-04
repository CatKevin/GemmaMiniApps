import 'package:get/get.dart';
import '../../models/shortcuts/models.dart';
import '../../models/shortcuts/composite_component.dart';
import '../../services/shortcuts/storage_service.dart';

class EditorController extends GetxController {
  // Observable states
  final Rx<EditorSession?> session = Rx<EditorSession?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Storage service
  ShortcutsStorageService? _storageService;
  
  // Current shortcut being edited
  ShortcutDefinition? _originalShortcut;
  
  @override
  void onInit() {
    super.onInit();
    _initializeStorageService();
  }
  
  Future<void> _initializeStorageService() async {
    try {
      _storageService = await ShortcutsStorageService.initialize();
    } catch (e) {
      errorMessage.value = 'Failed to initialize storage: ${e.toString()}';
    }
  }
  
  /// Initialize editor with existing shortcut or create new
  void initializeEditor(ShortcutDefinition? existingShortcut) {
    _originalShortcut = existingShortcut;
    
    if (existingShortcut != null) {
      // Edit existing shortcut
      final components = _convertToEditableComponents(existingShortcut.screens);
      
      // Ensure FinalPromptBuilder is at the end
      _ensureFinalPromptBuilder(components);
      
      session.value = EditorSession(
        shortcutId: existingShortcut.id,
        shortcutName: existingShortcut.name,
        components: components,
        variables: Map.from(existingShortcut.variables),
        expandedComponents: {},
        selectedComponentId: null,
        hasUnsavedChanges: false,
        lastModified: DateTime.now(),
      );
    } else {
      // Create new shortcut
      final components = <EditableComponent>[];
      
      // Add default FinalPromptBuilder component
      _ensureFinalPromptBuilder(components);
      
      session.value = EditorSession(
        shortcutId: DateTime.now().millisecondsSinceEpoch.toString(),
        shortcutName: '',
        components: components,
        variables: {},
        expandedComponents: {},
        selectedComponentId: null,
        hasUnsavedChanges: false,
        lastModified: DateTime.now(),
      );
    }
  }
  
  /// Ensure there's a FinalPromptBuilder at the end of components
  void _ensureFinalPromptBuilder(List<EditableComponent> components) {
    // Remove any existing FinalPromptBuilder components
    components.removeWhere((c) => c.component.type == ComponentType.finalPromptBuilder);
    
    // Add FinalPromptBuilder at the end
    final finalPromptBuilder = UIComponent(
      id: 'final_prompt_builder_${DateTime.now().millisecondsSinceEpoch}',
      type: ComponentType.finalPromptBuilder,
      properties: {
        'promptTemplate': 'Enter your prompt here. Use {{variableName}} to insert variables.',
        'enablePreview': true,
        'previewVariables': <String, dynamic>{},
      },
    );
    
    components.add(EditableComponent(
      id: finalPromptBuilder.id,
      component: finalPromptBuilder,
      order: components.length,
      isExpanded: true, // Always expanded by default
    ));
    
    // Update order for all components
    for (int i = 0; i < components.length; i++) {
      components[i] = components[i].copyWith(order: i);
    }
  }
  
  /// Convert screens to editable components
  List<EditableComponent> _convertToEditableComponents(List<ScreenDefinition> screens) {
    final components = <EditableComponent>[];
    int order = 0;
    
    for (final screen in screens) {
      for (final component in screen.components) {
        // Check if this is a composite component
        if (component.properties['isComposite'] == true) {
          // Reconstruct the composite component
          final compositeData = component.properties['compositeData'] as Map<String, dynamic>?;
          if (compositeData != null) {
            try {
              final compositeComponent = CompositeComponent.fromJson(compositeData);
              components.add(EditableComponent(
                id: compositeComponent.id,
                component: component,
                order: order++,
                isComposite: true,
                compositeComponent: compositeComponent,
              ));
            } catch (e) {
              // If reconstruction fails, add as regular component
              components.add(EditableComponent(
                id: '${screen.id}_${component.id}',
                component: component,
                order: order++,
              ));
            }
          } else {
            // No composite data, add as regular component
            components.add(EditableComponent(
              id: '${screen.id}_${component.id}',
              component: component,
              order: order++,
            ));
          }
        } else {
          // Regular component
          components.add(EditableComponent(
            id: '${screen.id}_${component.id}',
            component: component,
            order: order++,
          ));
        }
      }
    }
    
    return components;
  }
  
  /// Add a new component
  void addComponent(ComponentTemplate template) {
    if (session.value == null) return;
    
    // Don't allow adding another FinalPromptBuilder
    if (template.type == ComponentType.finalPromptBuilder) return;
    
    final newComponent = UIComponent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: template.type,
      properties: Map.from(template.defaultProperties),
    );
    
    final updatedComponents = List<EditableComponent>.from(session.value!.components);
    
    // Find FinalPromptBuilder index
    final finalPromptIndex = updatedComponents.indexWhere(
      (c) => c.component.type == ComponentType.finalPromptBuilder
    );
    
    // Insert before FinalPromptBuilder if it exists, otherwise at the end
    final insertIndex = finalPromptIndex != -1 
        ? finalPromptIndex 
        : updatedComponents.length;
    
    final editableComponent = EditableComponent(
      id: newComponent.id,
      component: newComponent,
      order: insertIndex,
    );
    
    updatedComponents.insert(insertIndex, editableComponent);
    
    // Update order for all components
    for (int i = 0; i < updatedComponents.length; i++) {
      updatedComponents[i] = updatedComponents[i].copyWith(order: i);
    }
    
    session.value = session.value!.copyWith(
      components: updatedComponents,
      hasUnsavedChanges: true,
      lastModified: DateTime.now(),
    );
  }
  
  /// Add a composite component (IF-ELSE, SWITCH-CASE, etc.)
  void addCompositeComponent(CompositeComponentType type, {Map<String, dynamic>? config}) {
    if (session.value == null) return;
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    CompositeComponent compositeComponent;
    
    switch (type) {
      case CompositeComponentType.ifElse:
        compositeComponent = IfElseComponent(
          id: id,
          conditionExpression: config?['condition'] ?? '',
        );
        break;
      case CompositeComponentType.switchCase:
        // Use default options for direct creation
        compositeComponent = SwitchCaseComponent(
          id: id,
          switchVariable: 'Select an option from the menu',
          caseOptions: ['Option 1', 'Option 2', 'Option 3'],
        );
        break;
      default:
        return; // Not implemented yet
    }
    
    final updatedComponents = List<EditableComponent>.from(session.value!.components);
    
    // Find FinalPromptBuilder index
    final finalPromptIndex = updatedComponents.indexWhere(
      (c) => c.component.type == ComponentType.finalPromptBuilder
    );
    
    // Insert before FinalPromptBuilder if it exists, otherwise at the end
    final insertIndex = finalPromptIndex != -1 
        ? finalPromptIndex 
        : updatedComponents.length;
    
    var editableComponent = compositeComponent.toEditableComponent();
    editableComponent = editableComponent.copyWith(order: insertIndex);
    
    updatedComponents.insert(insertIndex, editableComponent);
    
    // Update order for all components
    for (int i = 0; i < updatedComponents.length; i++) {
      updatedComponents[i] = updatedComponents[i].copyWith(order: i);
    }
    
    session.value = session.value!.copyWith(
      components: updatedComponents,
      hasUnsavedChanges: true,
      lastModified: DateTime.now(),
    );
  }
  
  /// Add a component to a specific section of a composite component
  void addComponentToSection(String sectionId, EditableComponent component) {
    if (session.value == null) return;
    
    // Find the composite component containing this section
    for (var i = 0; i < session.value!.components.length; i++) {
      final comp = session.value!.components[i];
      if (comp.isComposite && comp.compositeComponent != null) {
        final section = comp.compositeComponent!.sections
            .firstWhereOrNull((s) => s.id == sectionId);
        
        if (section != null) {
          // Add component to section
          component = component.copyWith(parentSectionId: sectionId);
          section.children.add(component);
          
          // Update session
          session.value = session.value!.copyWith(
            hasUnsavedChanges: true,
            lastModified: DateTime.now(),
          );
          break;
        }
      }
    }
  }
  
  /// Reorder components within a section
  void reorderComponentsInSection(int oldIndex, int newIndex, String sectionId) {
    if (session.value == null) return;
    
    // Find the section and reorder its children
    for (var comp in session.value!.components) {
      if (comp.isComposite && comp.compositeComponent != null) {
        final section = comp.compositeComponent!.sections
            .firstWhereOrNull((s) => s.id == sectionId);
        
        if (section != null && section.children.length > oldIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          
          final item = section.children.removeAt(oldIndex);
          section.children.insert(newIndex, item);
          
          // Update order values
          for (int i = 0; i < section.children.length; i++) {
            section.children[i] = section.children[i].copyWith(order: i);
          }
          
          session.value = session.value!.copyWith(
            hasUnsavedChanges: true,
            lastModified: DateTime.now(),
          );
          break;
        }
      }
    }
  }
  
  /// Update SWITCH-CASE options based on menu selector
  void updateSwitchCaseOptions(String switchCaseId, List<String> newOptions) {
    if (session.value == null) return;
    
    final componentIndex = session.value!.components
        .indexWhere((c) => c.id == switchCaseId && c.isComposite);
    
    if (componentIndex != -1) {
      final component = session.value!.components[componentIndex];
      if (component.compositeComponent is SwitchCaseComponent) {
        final switchCase = component.compositeComponent as SwitchCaseComponent;
        switchCase.updateCases(newOptions);
        
        session.value = session.value!.copyWith(
          hasUnsavedChanges: true,
          lastModified: DateTime.now(),
        );
      }
    }
  }
  
  /// Remove a component
  void removeComponent(String componentId) {
    if (session.value == null) return;
    
    // First try to remove from main list
    final componentIndex = session.value!.components
        .indexWhere((c) => c.id == componentId);
    
    if (componentIndex != -1) {
      // Don't allow removing FinalPromptBuilder
      if (session.value!.components[componentIndex].component.type == ComponentType.finalPromptBuilder) {
        return;
      }
      
      // Found in main list
      final updatedComponents = session.value!.components
          .where((c) => c.id != componentId)
          .toList();
      
      // Reorder remaining components
      for (int i = 0; i < updatedComponents.length; i++) {
        updatedComponents[i] = updatedComponents[i].copyWith(order: i);
      }
      
      session.value = session.value!.copyWith(
        components: updatedComponents,
        hasUnsavedChanges: true,
        lastModified: DateTime.now(),
      );
      return;
    }
    
    // Not found in main list, search in composite component sections
    for (final comp in session.value!.components) {
      if (comp.isComposite && comp.compositeComponent != null) {
        for (final section in comp.compositeComponent!.sections) {
          final childIndex = section.children.indexWhere((c) => c.id == componentId);
          if (childIndex != -1) {
            // Remove from section
            section.children.removeAt(childIndex);
            
            // Update order values in section
            for (int i = 0; i < section.children.length; i++) {
              section.children[i] = section.children[i].copyWith(order: i);
            }
            
            // Force UI update
            session.value = session.value!.copyWith(
              hasUnsavedChanges: true,
              lastModified: DateTime.now(),
            );
            return;
          }
        }
      }
    }
  }
  
  /// Move component from section to main list
  void moveComponentToMainList(String componentId, int targetIndex) {
    if (session.value == null) return;
    
    EditableComponent? componentToMove;
    
    // Find and remove component from section
    for (final comp in session.value!.components) {
      if (comp.isComposite && comp.compositeComponent != null) {
        for (final section in comp.compositeComponent!.sections) {
          final childIndex = section.children.indexWhere((c) => c.id == componentId);
          if (childIndex != -1) {
            componentToMove = section.children.removeAt(childIndex);
            
            // Update order values in section
            for (int i = 0; i < section.children.length; i++) {
              section.children[i] = section.children[i].copyWith(order: i);
            }
            break;
          }
        }
        if (componentToMove != null) break;
      }
    }
    
    if (componentToMove == null) return;
    
    // Clear parent section ID
    componentToMove = componentToMove.copyWith(
      parentSectionId: null,
      order: targetIndex,
    );
    
    // Add to main list
    final updatedComponents = List<EditableComponent>.from(session.value!.components);
    updatedComponents.insert(targetIndex, componentToMove);
    
    // Update order values
    for (int i = 0; i < updatedComponents.length; i++) {
      updatedComponents[i] = updatedComponents[i].copyWith(order: i);
    }
    
    session.value = session.value!.copyWith(
      components: updatedComponents,
      hasUnsavedChanges: true,
      lastModified: DateTime.now(),
    );
  }
  
  /// Move component from main list to a specific section
  void moveComponentToSection(String componentId, String targetSectionId, int targetIndex) {
    if (session.value == null) return;
    
    // Find and remove component from main list
    final componentIndex = session.value!.components.indexWhere((c) => c.id == componentId);
    if (componentIndex == -1) return;
    
    final componentToMove = session.value!.components[componentIndex];
    final updatedComponents = List<EditableComponent>.from(session.value!.components);
    updatedComponents.removeAt(componentIndex);
    
    // Update order values in main list
    for (int i = 0; i < updatedComponents.length; i++) {
      updatedComponents[i] = updatedComponents[i].copyWith(order: i);
    }
    
    // Find the target section and add component
    bool added = false;
    for (var comp in updatedComponents) {
      if (comp.isComposite && comp.compositeComponent != null) {
        final section = comp.compositeComponent!.sections
            .firstWhereOrNull((s) => s.id == targetSectionId);
        
        if (section != null) {
          // Update component's parent section ID
          final movedComponent = componentToMove.copyWith(
            parentSectionId: targetSectionId,
            order: targetIndex,
          );
          
          // Insert at target position
          if (targetIndex >= section.children.length) {
            section.children.add(movedComponent);
          } else {
            section.children.insert(targetIndex, movedComponent);
          }
          
          // Update order values in section
          for (int i = 0; i < section.children.length; i++) {
            section.children[i] = section.children[i].copyWith(order: i);
          }
          
          added = true;
          break;
        }
      }
    }
    
    if (added) {
      session.value = session.value!.copyWith(
        components: updatedComponents,
        hasUnsavedChanges: true,
        lastModified: DateTime.now(),
      );
    }
  }
  
  /// Update component property
  void updateComponentProperty(String componentId, String key, dynamic value) {
    if (session.value == null) return;
    
    // First try to find in main components list
    final componentIndex = session.value!.components
        .indexWhere((c) => c.id == componentId);
    
    if (componentIndex != -1) {
      // Found in main list
      final component = session.value!.components[componentIndex];
      final updatedProperties = Map<String, dynamic>.from(component.component.properties)
        ..[key] = value;
      
      UIComponent updatedUIComponent;
      
      // Handle special cases
      if (key == 'variableBinding') {
        updatedUIComponent = component.component.copyWith(
          variableBinding: value as String?,
        );
        
        // Auto-register variable if it doesn't exist
        if (value != null && value.toString().isNotEmpty) {
          _registerVariable(value.toString(), component.component.type);
        }
      } else {
        updatedUIComponent = component.component.copyWith(
          properties: updatedProperties,
        );
      }
      
      final updatedComponent = component.copyWith(
        component: updatedUIComponent,
      );
      
      final updatedComponents = List<EditableComponent>.from(session.value!.components);
      updatedComponents[componentIndex] = updatedComponent;
      
      session.value = session.value!.copyWith(
        components: updatedComponents,
        hasUnsavedChanges: true,
        lastModified: DateTime.now(),
      );
      return;
    }
    
    // Not found in main list, search in composite component sections
    for (int i = 0; i < session.value!.components.length; i++) {
      final comp = session.value!.components[i];
      if (comp.isComposite && comp.compositeComponent != null) {
        for (final section in comp.compositeComponent!.sections) {
          final childIndex = section.children.indexWhere((c) => c.id == componentId);
          if (childIndex != -1) {
            // Found in section
            final child = section.children[childIndex];
            final updatedProperties = Map<String, dynamic>.from(child.component.properties)
              ..[key] = value;
            
            UIComponent updatedUIComponent;
            
            // Handle special cases
            if (key == 'variableBinding') {
              updatedUIComponent = child.component.copyWith(
                variableBinding: value as String?,
              );
              
              // Auto-register variable if it doesn't exist
              if (value != null && value.toString().isNotEmpty) {
                _registerVariable(value.toString(), child.component.type);
              }
            } else {
              updatedUIComponent = child.component.copyWith(
                properties: updatedProperties,
              );
            }
            
            final updatedChild = child.copyWith(
              component: updatedUIComponent,
            );
            
            // Update the child in section
            section.children[childIndex] = updatedChild;
            
            // Force UI update by updating session
            session.value = session.value!.copyWith(
              hasUnsavedChanges: true,
              lastModified: DateTime.now(),
            );
            return;
          }
        }
      }
    }
  }
  
  /// Toggle component expansion
  void toggleComponentExpansion(String componentId) {
    if (session.value == null) return;
    
    final expandedComponents = Set<String>.from(session.value!.expandedComponents);
    
    if (expandedComponents.contains(componentId)) {
      expandedComponents.remove(componentId);
    } else {
      expandedComponents.add(componentId);
    }
    
    final componentIndex = session.value!.components
        .indexWhere((c) => c.id == componentId);
    
    if (componentIndex != -1) {
      final component = session.value!.components[componentIndex];
      final updatedComponent = component.copyWith(
        isExpanded: expandedComponents.contains(componentId),
      );
      
      final updatedComponents = List<EditableComponent>.from(session.value!.components);
      updatedComponents[componentIndex] = updatedComponent;
      
      session.value = session.value!.copyWith(
        components: updatedComponents,
        expandedComponents: expandedComponents,
      );
    }
  }
  
  /// Reorder components
  void reorderComponents(int oldIndex, int newIndex) {
    if (session.value == null) return;
    
    final components = List<EditableComponent>.from(session.value!.components);
    
    // Don't allow moving FinalPromptBuilder
    if (oldIndex < components.length && 
        components[oldIndex].component.type == ComponentType.finalPromptBuilder) {
      return;
    }
    
    // Don't allow moving to/past FinalPromptBuilder position
    final finalPromptIndex = components.indexWhere(
      (c) => c.component.type == ComponentType.finalPromptBuilder
    );
    if (finalPromptIndex != -1 && newIndex >= finalPromptIndex) {
      newIndex = finalPromptIndex - 1;
    }
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = components.removeAt(oldIndex);
    components.insert(newIndex, item);
    
    // Update order values
    for (int i = 0; i < components.length; i++) {
      components[i] = components[i].copyWith(order: i);
    }
    
    session.value = session.value!.copyWith(
      components: components,
      hasUnsavedChanges: true,
      lastModified: DateTime.now(),
    );
  }
  
  /// Register a variable
  void _registerVariable(String name, ComponentType componentType) {
    if (session.value == null) return;
    
    // Skip if variable already exists
    if (session.value!.variables.containsKey(name)) return;
    
    // Determine variable type based on component type
    VariableType varType;
    dynamic defaultValue;
    
    switch (componentType) {
      case ComponentType.numberInput:
      case ComponentType.slider:
        varType = VariableType.number;
        defaultValue = 0;
        break;
      case ComponentType.switch_:
        varType = VariableType.boolean;
        defaultValue = false;
        break;
      case ComponentType.multiSelect:
      case ComponentType.tagInput:
        varType = VariableType.list;
        defaultValue = [];
        break;
      default:
        varType = VariableType.string;
        defaultValue = '';
    }
    
    final variable = VariableDefinition(
      name: name,
      type: varType,
      defaultValue: defaultValue,
    );
    
    final updatedVariables = Map<String, VariableDefinition>.from(session.value!.variables)
      ..[name] = variable;
    
    session.value = session.value!.copyWith(
      variables: updatedVariables,
      hasUnsavedChanges: true,
    );
  }
  
  /// Update shortcut metadata
  void updateMetadata({
    String? name,
    String? description,
    String? category,
    ShortcutIcon? icon,
  }) {
    if (session.value == null) return;
    
    session.value = session.value!.copyWith(
      shortcutName: name ?? session.value!.shortcutName,
      hasUnsavedChanges: true,
      lastModified: DateTime.now(),
    );
  }
  
  /// Update variables in the editor session
  void updateVariables(List<Variable> variables) {
    if (session.value == null) return;
    
    // Convert to Map<String, VariableDefinition>
    final variableDefinitions = <String, VariableDefinition>{};
    for (final variable in variables) {
      variableDefinitions[variable.name] = VariableDefinition(
        name: variable.name,
        type: _convertVariableType(variable.type),
        defaultValue: variable.value,
        description: variable.description,
      );
    }
    
    session.value = session.value!.copyWith(
      variables: variableDefinitions,
      hasUnsavedChanges: true,
    );
  }
  
  /// Convert between variable type enums
  VariableType _convertVariableType(dynamic type) {
    // Handle conversion between different VariableType enums if needed
    final typeName = type.toString().split('.').last;
    switch (typeName) {
      case 'string':
      case 'text':
        return VariableType.string;
      case 'number':
        return VariableType.number;
      case 'boolean':
        return VariableType.boolean;
      case 'date':
        return VariableType.date;
      case 'list':
        return VariableType.list;
      case 'map':
      case 'object':
        return VariableType.map;
      default:
        return VariableType.string;
    }
  }
  
  /// Save the shortcut
  Future<bool> saveShortcut({
    required String name,
    required String description,
    required String category,
    required ShortcutIcon icon,
    List<Variable>? variables,
  }) async {
    if (session.value == null || _storageService == null) return false;
    
    try {
      isSaving.value = true;
      errorMessage.value = '';
      
      // Create screen from components
      final screen = ScreenDefinition(
        id: 'main',
        title: name,
        components: _extractAllComponents(session.value!.components),
        actions: {
          'submit': ScreenAction(
            type: ActionType.submit,
            label: 'Generate',
            parameters: {},
          ),
        },
      );
      
      // Create prompt template from components
      final promptSections = <PromptSection>[];
      
      // Check if we have a FinalPromptBuilder
      final finalPromptBuilderComponent = session.value!.components.firstWhereOrNull(
        (c) => c.component.type == ComponentType.finalPromptBuilder
      );
      
      if (finalPromptBuilderComponent != null) {
        // Use FinalPromptBuilder content as the single prompt section
        promptSections.add(PromptSection(
          id: 'final_prompt',
          type: PromptSectionType.custom,
          content: finalPromptBuilderComponent.component.properties['promptTemplate'] ?? '',
          order: 0,
        ));
      } else {
        // Fallback to old approach for backward compatibility
        for (int i = 0; i < session.value!.components.length; i++) {
          final component = session.value!.components[i];
          if (component.component.type == ComponentType.roleDefinition) {
            promptSections.add(PromptSection(
              id: 'section_$i',
              type: PromptSectionType.role,
              content: component.component.properties['role'] ?? '',
              order: i,
            ));
          } else if (component.component.type == ComponentType.taskDescription) {
            promptSections.add(PromptSection(
              id: 'section_$i',
              type: PromptSectionType.task,
              content: component.component.properties['task'] ?? '',
              order: i,
            ));
          } else if (component.component.type == ComponentType.textTemplate) {
            promptSections.add(PromptSection(
              id: 'section_$i',
              type: PromptSectionType.custom,
              content: component.component.properties['content'] ?? '',
              order: i,
            ));
          }
        }
      }
      
      // Create the shortcut definition
      final shortcut = ShortcutDefinition(
        id: session.value!.shortcutId,
        name: name,
        description: description,
        category: category,
        icon: icon,
        version: '1.0.0',
        screens: [screen],
        startScreenId: 'main',
        transitions: {},
        variables: session.value!.variables,
        promptTemplate: PromptTemplate(
          sections: promptSections,
          assemblyLogic: 'sequential',
          assemblyMode: AssemblyMode.sequential,
        ),
        author: 'User',
        createdAt: _originalShortcut?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: false,
        usageCount: _originalShortcut?.usageCount ?? 0,
      );
      
      // Save to storage
      if (_originalShortcut != null) {
        await _storageService!.updateShortcut(shortcut);
      } else {
        await _storageService!.saveShortcut(shortcut);
      }
      
      session.value = session.value!.copyWith(hasUnsavedChanges: false);
      return true;
      
    } catch (e) {
      errorMessage.value = 'Failed to save: ${e.toString()}';
      return false;
    } finally {
      isSaving.value = false;
    }
  }
  
  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => session.value?.hasUnsavedChanges ?? false;
  
  /// Extract all components including those inside composite components
  List<UIComponent> _extractAllComponents(List<EditableComponent> editableComponents) {
    final components = <UIComponent>[];
    
    for (final editableComp in editableComponents) {
      if (editableComp.isComposite && editableComp.compositeComponent != null) {
        // Create a special UIComponent that represents the composite component
        final compositeComp = editableComp.compositeComponent!;
        
        // Create composite UI component with all necessary data
        final compositeUIComponent = UIComponent(
          id: compositeComp.id,
          type: ComponentType.groupContainer, // Use groupContainer as base type
          properties: {
            'isComposite': true,
            'compositeType': compositeComp.type.toString(),
            'compositeData': compositeComp.toJson(),
          },
        );
        
        components.add(compositeUIComponent);
      } else {
        // Regular component
        components.add(editableComp.component);
      }
    }
    
    return components;
  }
  
  @override
  void onClose() {
    session.value = null;
    super.onClose();
  }
}