import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../models/shortcuts/models.dart';
import '../../controllers/shortcuts/editor_controller.dart';
import '../../widgets/shortcuts/editor/widgets.dart';
import '../../widgets/shortcuts/editor/variable_definition_section.dart';
import '../../widgets/shortcuts/editor/draggable_component_card.dart';
import '../../widgets/shortcuts/editor/composite_component_widget.dart';
import '../../widgets/shortcuts/editor/composite_component_panel.dart';
import '../../widgets/shortcuts/editor/cross_container_draggable.dart';
import '../../services/shortcuts/storage_service.dart';
import '../routes.dart';

class EditorPage extends HookWidget {
  const EditorPage({super.key});

  // Helper function to convert VariableDefinition to Variable
  static List<Variable> _convertVariableDefinitionsToVariables(
    Map<String, VariableDefinition> definitions,
    List<Variable>? existingVariables,
  ) {
    final convertedVariables = <Variable>[];
    definitions.forEach((name, definition) {
      // Try to preserve existing variable values
      final existingVar = existingVariables?.firstWhereOrNull((v) => v.name == name);
      convertedVariables.add(Variable(
        id: existingVar?.id ?? name,
        name: name,
        type: definition.type,
        value: existingVar?.value ?? definition.defaultValue,
        description: definition.description,
        source: VariableSource.userInput,
        lastUpdated: DateTime.now(),
      ));
    });
    return convertedVariables;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    // Get arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final shortcutId = args?['shortcutId'] as String?;
    final basicInfo = args?['basicInfo'] as Map<String, dynamic>?;
    
    // State management
    final existingShortcut = useState<ShortcutDefinition?>(null);
    final isLoadingShortcut = useState(false);
    final shortcutName = useState(basicInfo?['name'] ?? '');
    final shortcutDescription = useState(basicInfo?['description'] ?? '');
    final selectedCategory = useState<ShortcutCategory>(
      basicInfo?['category'] != null 
          ? ShortcutCategory.fromString(basicInfo!['category'])
          : ShortcutCategory.other
    );
    final selectedIcon = useState<ShortcutIcon>(
      basicInfo != null && basicInfo['icon'] != null
          ? ShortcutIcon(
              iconData: basicInfo['icon'] as IconData,
              color: basicInfo['color'] as Color?,
            )
          : ShortcutIcon.defaultIcon
    );
    final variables = useState<List<Variable>>([]);

    // Initialize controller
    final controller = Get.put(EditorController());

    // Check if we have basic info
    useEffect(() {
      if (shortcutId == null && basicInfo == null) {
        // Redirect to basic info page if no info provided
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offNamed(Routes.shortcutsBasicInfo);
        });
      }
      return null;
    }, []);

    // Load shortcut if editing
    useEffect(() {
      if (shortcutId != null) {
        isLoadingShortcut.value = true;
        ShortcutsStorageService.initialize().then((storage) async {
          try {
            final shortcut = await storage.getShortcut(shortcutId);
            if (shortcut != null) {
              existingShortcut.value = shortcut;
              shortcutName.value = shortcut.name;
              shortcutDescription.value = shortcut.description;
              selectedCategory.value = ShortcutCategory.fromString(shortcut.category);
              selectedIcon.value = shortcut.icon;
              controller.initializeEditor(shortcut);
              
              // Convert and sync variables from controller to UI
              // Wait for controller to initialize
              await Future.delayed(const Duration(milliseconds: 100));
              if (controller.session.value != null && controller.session.value!.variables.isNotEmpty) {
                variables.value = _convertVariableDefinitionsToVariables(
                  controller.session.value!.variables,
                  null, // No existing variables on initial load
                );
                
                // Show success feedback
                Get.snackbar(
                  'Variables Loaded',
                  '${variables.value.length} variables loaded successfully',
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 2),
                  backgroundColor: themeController.currentThemeConfig.primary.withValues(alpha: 0.9),
                  colorText: themeController.currentThemeConfig.onPrimary,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }
            } else {
              Get.snackbar(
                'Error',
                'Shortcut not found',
                snackPosition: SnackPosition.TOP,
                backgroundColor: themeController.currentThemeConfig.error,
                colorText: themeController.currentThemeConfig.onError,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
              Get.back();
            }
          } catch (e) {
            Get.snackbar(
              'Error Loading Variables',
              'Failed to load variables: ${e.toString()}',
              snackPosition: SnackPosition.TOP,
              backgroundColor: themeController.currentThemeConfig.error,
              colorText: themeController.currentThemeConfig.onError,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          } finally {
            isLoadingShortcut.value = false;
          }
        }).catchError((error) {
          isLoadingShortcut.value = false;
          Get.snackbar(
            'Error',
            'Failed to load shortcut: ${error.toString()}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: themeController.currentThemeConfig.error,
            colorText: themeController.currentThemeConfig.onError,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        });
      } else {
        controller.initializeEditor(null);
      }
      return null;
    }, [shortcutId]);

    // Listen to controller session changes and sync variables
    useEffect(() {
      if (controller.session.value != null) {
        // Create a listener for session changes
        ever(controller.session, (session) {
          try {
            if (session != null && session.variables.isNotEmpty) {
              // Only sync if variables from controller are different
              final currentVarNames = variables.value.map((v) => v.name).toSet();
              final sessionVarNames = session.variables.keys.toSet();
              
              // Check if we need to sync (different variable sets)
              if (!const SetEquality().equals(currentVarNames, sessionVarNames)) {
                variables.value = _convertVariableDefinitionsToVariables(
                  session.variables,
                  variables.value,
                );
              }
            }
          } catch (e) {
            // Log error but don't show to user to avoid spamming
            debugPrint('Error syncing variables: $e');
          }
        });
      }
      return null;
    }, [controller]);

    // Handle variable updates
    void handleAddVariable(Variable variable) {
      final updatedVars = List<Variable>.from(variables.value);
      updatedVars.add(variable);
      variables.value = updatedVars;
      controller.updateVariables(updatedVars);
    }
    
    void handleUpdateVariable(Variable variable) {
      final updatedVars = variables.value.map((v) {
        return v.id == variable.id ? variable : v;
      }).toList();
      variables.value = updatedVars;
      controller.updateVariables(updatedVars);
    }
    
    void handleDeleteVariable(String variableId) {
      final updatedVars = variables.value
          .where((v) => v.id != variableId)
          .toList();
      variables.value = updatedVars;
      controller.updateVariables(updatedVars);
    }

    void handleSave() async {
      final success = await controller.saveShortcut(
        name: shortcutName.value,
        description: shortcutDescription.value,
        category: selectedCategory.value.name,
        icon: selectedIcon.value,
        variables: variables.value,
      );

      if (success) {
        // Navigate back to shortcuts list page
        Get.until((route) => route.settings.name == Routes.shortcuts);
        
        Get.snackbar(
          'Success',
          'Shortcut "${shortcutName.value}" created successfully',
          backgroundColor: themeController.currentThemeConfig.primary,
          colorText: themeController.currentThemeConfig.onPrimary,
          duration: const Duration(seconds: 3),
          mainButton: TextButton(
            onPressed: () {
              Get.closeCurrentSnackbar();
              // Navigate to the newly created shortcut's runtime
              final newShortcutId = controller.session.value?.shortcutId;
              if (newShortcutId != null) {
                Routes.toShortcutsRuntime(shortcutId: newShortcutId);
              }
            },
            child: Text(
              'USE NOW',
              style: TextStyle(
                color: themeController.currentThemeConfig.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    }

    void handleAddComponent() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => ComponentPanel(
            onComponentSelected: (template) {
              controller.addComponent(template);
            },
          ),
        ),
      );
    }
    
    void handleAddLogicComponent() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) => CompositeComponentPanel(
            onComponentSelected: (type, config) {
              controller.addCompositeComponent(type, config: config);
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }

    // Show loading indicator while loading shortcut
    if (isLoadingShortcut.value) {
      return Scaffold(
        backgroundColor: themeController.currentThemeConfig.background,
        body: Center(
          child: CircularProgressIndicator(
            color: themeController.currentThemeConfig.primary,
          ),
        ),
      );
    }

    return PopScope(
      canPop: !controller.hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final result = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('Do you want to discard your changes?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('DISCARD'),
              ),
            ],
          ),
        );

        if (result == true) {
          Get.back();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shortcutName.value.isNotEmpty 
                    ? shortcutName.value 
                    : (existingShortcut.value != null ? 'EDIT SHORTCUT' : 'NEW SHORTCUT'),
                style: const TextStyle(fontSize: 18),
              ),
              if (shortcutDescription.value.isNotEmpty)
                Text(
                  shortcutDescription.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeController.currentThemeConfig.onBackground
                        .withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (existingShortcut.value != null) {
                Get.back();
              } else {
                Routes.toShortcutsBasicInfo();
              }
            },
          ),
          actions: [
            Obx(() => TextButton(
                  onPressed: controller.hasUnsavedChanges ? handleSave : null,
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      color: controller.hasUnsavedChanges
                          ? themeController.currentThemeConfig.primary
                          : themeController.currentThemeConfig.onBackground
                              .withValues(alpha: 0.3),
                    ),
                  ),
                )),
          ],
        ),
        body: Obx(() {
          final theme = themeController.currentThemeConfig;
          final session = controller.session.value;

          if (session == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Components list
              Expanded(
                child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          children: [
                            // Variable definition section (always first)
                            VariableDefinitionSection(
                              variables: variables.value,
                              onAddVariable: handleAddVariable,
                              onUpdateVariable: handleUpdateVariable,
                              onDeleteVariable: handleDeleteVariable,
                              onVariableSelected: (variableId) {
                                Get.snackbar(
                                  'Variable Selected',
                                  'Use {{$variableId}} to reference this variable',
                                  snackPosition: SnackPosition.TOP,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                            ),
                            
                            // Components list
                            session.components.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(vertical: 60),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: 64,
                                        color: theme.onBackground.withValues(alpha: 0.2),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No workflow components yet',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: theme.onBackground.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Click the button below to add components',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: theme.onBackground.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: session.components.length + 1, // +1 for the drop zone at the end
                                  itemBuilder: (context, index) {
                                    // Drop zone at the end
                                    if (index == session.components.length) {
                                      return ComponentDropTarget(
                                        targetIndex: index,
                                        targetSectionId: null,
                                        showDropIndicator: false,
                                        onAccept: (dragData, targetIndex) {
                                          // Handle drop from section to main list
                                          if (dragData.sourceSectionId != null) {
                                            controller.moveComponentToMainList(
                                              dragData.component.id,
                                              targetIndex,
                                            );
                                          } else {
                                            // Regular reorder within main list
                                            controller.reorderComponents(
                                              dragData.sourceIndex,
                                              targetIndex,
                                            );
                                          }
                                        },
                                        child: Container(
                                          height: 80,
                                          margin: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: theme.onBackground.withValues(alpha: 0.1),
                                                  style: BorderStyle.solid,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Drop components here',
                                                style: TextStyle(
                                                  color: theme.onBackground.withValues(alpha: 0.3),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    
                                    final component = session.components[index];
                                    
                                    // Wrap components with drop target
                                    return ComponentDropTarget(
                                      targetIndex: index,
                                      targetSectionId: null,
                                      onAccept: (dragData, targetIndex) {
                                        // Handle drop from section to main list
                                        if (dragData.sourceSectionId != null) {
                                          controller.moveComponentToMainList(
                                            dragData.component.id,
                                            targetIndex,
                                          );
                                        } else {
                                          // Regular reorder within main list
                                          int sourceIndex = dragData.sourceIndex;
                                          if (sourceIndex > targetIndex) {
                                            // Moving up
                                            controller.reorderComponents(sourceIndex, targetIndex);
                                          } else {
                                            // Moving down
                                            controller.reorderComponents(sourceIndex, targetIndex - 1);
                                          }
                                        }
                                      },
                                      child: Builder(
                                        builder: (context) {
                                          // Check if it's a composite component
                                          if (component.isComposite && component.compositeComponent != null) {
                                            return CrossContainerDraggable(
                                              component: component,
                                              index: index,
                                              sectionId: null,
                                              child: CompositeComponentWidget(
                                                key: ValueKey(component.id),
                                                component: component.compositeComponent!,
                                                isExpanded: component.isExpanded,
                                                onToggleExpand: () {
                                                  controller.toggleComponentExpansion(component.id);
                                                },
                                                onDelete: () {
                                                  controller.removeComponent(component.id);
                                                },
                                                onAddComponent: (sectionId, newComponent) {
                                                  controller.addComponentToSection(sectionId, newComponent);
                                                },
                                                onRemoveComponent: (componentId) {
                                                  controller.removeComponent(componentId);
                                                },
                                                onReorderInSection: (oldIndex, newIndex, sectionId) {
                                                  controller.reorderComponentsInSection(
                                                    oldIndex,
                                                    newIndex,
                                                    sectionId,
                                                  );
                                                },
                                                onPropertyChanged: (componentId, key, value) {
                                                  controller.updateComponentProperty(
                                                    componentId,
                                                    key,
                                                    value,
                                                  );
                                                },
                                                availableVariables: variables.value,
                                                onAddVariable: handleAddVariable,
                                              ),
                                            );
                                          } else {
                                            // Regular component
                                            final template = ComponentTemplateLibrary.getTemplate(
                                              component.component.type,
                                            );

                                            return CrossContainerDraggable(
                                              component: component,
                                              index: index,
                                              sectionId: null,
                                              child: DraggableComponentCard(
                                                key: ValueKey(component.id),
                                                component: component,
                                                template: template,
                                                index: index,
                                                totalCount: session.components.length,
                                                theme: theme,
                                                onExpand: () {
                                                  controller.toggleComponentExpansion(component.id);
                                                },
                                                onDelete: () {
                                                  controller.removeComponent(component.id);
                                                },
                                                onMoveUp: index > 0 ? () {
                                                  HapticFeedback.lightImpact();
                                                  controller.reorderComponents(index, index - 1);
                                                } : null,
                                                onMoveDown: index < session.components.length - 1 ? () {
                                                  HapticFeedback.lightImpact();
                                                  controller.reorderComponents(index, index + 1);
                                                } : null,
                                                onPropertyChanged: (key, value) {
                                                  controller.updateComponentProperty(
                                                    component.id,
                                                    key,
                                                    value,
                                                  );
                                                },
                                                availableVariables: variables.value,
                                                onAddVariable: handleAddVariable,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                              ),
                          ],
                        ),
                      ),
              ),
              
              // Add component buttons at the bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.background,
                  border: Border(
                    top: BorderSide(
                      color: theme.onBackground.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: handleAddComponent,
                        icon: const Icon(Icons.add),
                        label: const Text('COMPONENT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: theme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: handleAddLogicComponent,
                        icon: const Icon(Icons.account_tree),
                        label: const Text('LOGIC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

