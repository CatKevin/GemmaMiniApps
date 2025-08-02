import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../models/shortcuts/models.dart';
import '../../controllers/shortcuts/editor_controller.dart';
import '../../widgets/shortcuts/editor/widgets.dart';

class EditorPage extends HookWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    final existingShortcut = Get.arguments as ShortcutDefinition?;

    // Initialize controller
    final controller = Get.put(EditorController());

    // State management
    final shortcutName = useState(existingShortcut?.name ?? '');
    final shortcutDescription = useState(existingShortcut?.description ?? '');
    final selectedCategory = useState<ShortcutCategory>(existingShortcut != null
        ? ShortcutCategory.fromString(existingShortcut.category)
        : ShortcutCategory.other);
    final selectedIcon = useState<ShortcutIcon>(
        existingShortcut?.icon ?? ShortcutIcon.defaultIcon);

    // Create text controllers at the top level
    final nameController = useTextEditingController(text: shortcutName.value);
    final descriptionController =
        useTextEditingController(text: shortcutDescription.value);

    // Initialize editor on first build
    useEffect(() {
      controller.initializeEditor(existingShortcut);
      return null;
    }, []);

    // Sync text controllers with state
    useEffect(() {
      nameController.text = shortcutName.value;
      return null;
    }, [shortcutName.value]);

    useEffect(() {
      descriptionController.text = shortcutDescription.value;
      return null;
    }, [shortcutDescription.value]);

    void handleSave() async {
      if (shortcutName.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter a shortcut name',
          backgroundColor: themeController.currentThemeConfig.error,
          colorText: themeController.currentThemeConfig.onError,
        );
        return;
      }

      if (shortcutDescription.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter a description',
          backgroundColor: themeController.currentThemeConfig.error,
          colorText: themeController.currentThemeConfig.onError,
        );
        return;
      }

      final success = await controller.saveShortcut(
        name: shortcutName.value,
        description: shortcutDescription.value,
        category: selectedCategory.value.name,
        icon: selectedIcon.value,
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
          title:
              Text(existingShortcut != null ? 'EDIT SHORTCUT' : 'NEW SHORTCUT'),
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
              // Basic info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      onChanged: (value) {
                        shortcutName.value = value;
                        controller.updateMetadata(name: value);
                      },
                      style: TextStyle(
                        color: theme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Shortcut Name',
                        labelStyle: TextStyle(
                          color: theme.onSurface.withValues(alpha: 0.5),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      onChanged: (value) {
                        shortcutDescription.value = value;
                        controller.updateMetadata(description: value);
                      },
                      style: TextStyle(
                        color: theme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(
                          color: theme.onSurface.withValues(alpha: 0.5),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ShortcutCategory>(
                      value: selectedCategory.value,
                      onChanged: (value) {
                        if (value != null) {
                          selectedCategory.value = value;
                          controller.updateMetadata(category: value.name);
                        }
                      },
                      style: TextStyle(
                        color: theme.onSurface,
                      ),
                      dropdownColor: theme.surface,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(
                          color: theme.onSurface.withValues(alpha: 0.5),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.primary,
                          ),
                        ),
                      ),
                      items: ShortcutCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                category.icon,
                                size: 20,
                                color: theme.onSurface,
                              ),
                              const SizedBox(width: 12),
                              Text(category.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Components list
              Expanded(
                child: session.components.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.widgets_outlined,
                              size: 64,
                              color: theme.onBackground.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No components yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: theme.onBackground
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add components to build your shortcut',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: theme.onBackground
                                        .withValues(alpha: 0.3),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
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
                                onExpand: () {
                                  controller
                                      .toggleComponentExpansion(component.id);
                                },
                                onDelete: () {
                                  controller.removeComponent(component.id);
                                },
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
              ),

              // Add component button
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
  final VoidCallback onExpand;
  final VoidCallback onDelete;

  const _ComponentListItem({
    required this.component,
    required this.onExpand,
    required this.onDelete,
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
      child: ListTile(
        leading: Icon(
          _getComponentIcon(component.component.type),
          color: theme.primary,
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
