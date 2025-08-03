import 'package:get/get.dart';
import '../../models/shortcuts/models.dart';
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
      session.value = EditorSession(
        shortcutId: DateTime.now().millisecondsSinceEpoch.toString(),
        shortcutName: '',
        components: [],
        variables: {},
        expandedComponents: {},
        selectedComponentId: null,
        hasUnsavedChanges: false,
        lastModified: DateTime.now(),
      );
    }
  }
  
  /// Convert screens to editable components
  List<EditableComponent> _convertToEditableComponents(List<ScreenDefinition> screens) {
    final components = <EditableComponent>[];
    int order = 0;
    
    for (final screen in screens) {
      for (final component in screen.components) {
        components.add(EditableComponent(
          id: '${screen.id}_${component.id}',
          component: component,
          order: order++,
        ));
      }
    }
    
    return components;
  }
  
  /// Add a new component
  void addComponent(ComponentTemplate template) {
    if (session.value == null) return;
    
    final newComponent = UIComponent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: template.type,
      properties: Map.from(template.defaultProperties),
    );
    
    final editableComponent = EditableComponent(
      id: newComponent.id,
      component: newComponent,
      order: session.value!.components.length,
    );
    
    final updatedComponents = List<EditableComponent>.from(session.value!.components)
      ..add(editableComponent);
    
    session.value = session.value!.copyWith(
      components: updatedComponents,
      hasUnsavedChanges: true,
      lastModified: DateTime.now(),
    );
  }
  
  /// Remove a component
  void removeComponent(String componentId) {
    if (session.value == null) return;
    
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
  }
  
  /// Update component property
  void updateComponentProperty(String componentId, String key, dynamic value) {
    if (session.value == null) return;
    
    final componentIndex = session.value!.components
        .indexWhere((c) => c.id == componentId);
    
    if (componentIndex == -1) return;
    
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
        components: session.value!.components
            .map((e) => e.component)
            .toList(),
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
  
  @override
  void onClose() {
    session.value = null;
    super.onClose();
  }
}