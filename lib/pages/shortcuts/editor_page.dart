import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../models/shortcuts/models.dart';
import '../../controllers/shortcuts/editor_controller.dart';
import '../../widgets/shortcuts/editor/widgets.dart';
import '../../widgets/shortcuts/editor/variable_definition_section.dart';
import '../../services/shortcuts/storage_service.dart';
import '../routes.dart';

class EditorPage extends HookWidget {
  const EditorPage({super.key});

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
          final shortcut = await storage.getShortcut(shortcutId);
          if (shortcut != null) {
            existingShortcut.value = shortcut;
            shortcutName.value = shortcut.name;
            shortcutDescription.value = shortcut.description;
            selectedCategory.value = ShortcutCategory.fromString(shortcut.category);
            selectedIcon.value = shortcut.icon;
            controller.initializeEditor(shortcut);
          }
          isLoadingShortcut.value = false;
        });
      } else {
        controller.initializeEditor(null);
      }
      return null;
    }, [shortcutId]);

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
        Get.back(result: true);
        Get.snackbar(
          'Success',
          'Shortcut saved successfully',
          backgroundColor: themeController.currentThemeConfig.primary,
          colorText: themeController.currentThemeConfig.onPrimary,
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
                              : ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: session.components.length,
                                  onReorder: controller.reorderComponents,
                                  itemBuilder: (context, index) {
                          final component = session.components[index];
                          final template = ComponentTemplateLibrary.getTemplate(
                            component.component.type,
                          );

                          return Column(
                            key: ValueKey(component.id),
                            children: [
                              _ComponentListItem(
                                component: component,
                                index: index,
                                totalCount: session.components.length,
                                onExpand: () {
                                  controller
                                      .toggleComponentExpansion(component.id);
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
                              ),
                              if (component.isExpanded && template != null)
                                ComponentPropertyEditor(
                                  component: component.component,
                                  template: template,
                                  onPropertyChanged: (key, value) {
                                    controller.updateComponentProperty(
                                      component.id,
                                      key,
                                      value,
                                    );
                                  },
                                  availableVariables: session.variables,
                                ),
                            ],
                          );
                        },
                              ),
                          ],
                        ),
                      ),
              ),
              
              // Add component button at the bottom
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: handleAddComponent,
                    icon: const Icon(Icons.add),
                    label: const Text('ADD COMPONENT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: theme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ComponentListItem extends StatelessWidget {
  final EditableComponent component;
  final int index;
  final int totalCount;
  final VoidCallback onExpand;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _ComponentListItem({
    required this.component,
    required this.index,
    required this.totalCount,
    required this.onExpand,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.drag_handle,
                  color: theme.onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Icon(
                  _getComponentIcon(component.component.type),
                  color: theme.primary,
                ),
              ],
            ),
            title: Text(
              _getComponentTitle(component.component),
              style: TextStyle(
                color: theme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _getComponentSubtitle(component.component),
              style: TextStyle(
                color: theme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick move buttons
                if (onMoveUp != null || onMoveDown != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: theme.background,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: onMoveUp,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.arrow_upward,
                              size: 16,
                              color: onMoveUp != null 
                                  ? theme.onSurface.withValues(alpha: 0.6)
                                  : theme.onSurface.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 16,
                          color: theme.onSurface.withValues(alpha: 0.1),
                        ),
                        InkWell(
                          onTap: onMoveDown,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: onMoveDown != null 
                                  ? theme.onSurface.withValues(alpha: 0.6)
                                  : theme.onSurface.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: Icon(
                    component.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: onExpand,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.error,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          // Position indicator
          if (index == 0 || index == totalCount - 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      index == 0 ? 'First' : 'Last',
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getComponentIcon(ComponentType type) {
    switch (type) {
      case ComponentType.textInput:
      case ComponentType.multilineTextInput:
        return Icons.text_fields;
      case ComponentType.numberInput:
        return Icons.numbers;
      case ComponentType.singleSelect:
        return Icons.radio_button_checked;
      case ComponentType.multiSelect:
        return Icons.check_box;
      case ComponentType.conditional:
        return Icons.alt_route;
      case ComponentType.textTemplate:
        return Icons.text_snippet;
      case ComponentType.roleDefinition:
        return Icons.person;
      case ComponentType.taskDescription:
        return Icons.task_alt;
      default:
        return Icons.widgets;
    }
  }

  String _getComponentTitle(UIComponent component) {
    return component.properties['label'] ??
        component.properties['title'] ??
        component.type.toString().split('.').last;
  }

  String _getComponentSubtitle(UIComponent component) {
    if (component.variableBinding != null) {
      return 'Variable: ${component.variableBinding}';
    }
    return component.type.toString().split('.').last;
  }
}
