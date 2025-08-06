import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../services/gemma/model_manager_service.dart';
import '../../models/gemma/models.dart';
import '../../widgets/model_import_dialog.dart';

class ModelManagerPage extends HookWidget {
  const ModelManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    final modelManager = ModelManagerService();
    final selectedTab = useState(0);
    
    // Initialize model manager
    useEffect(() {
      modelManager.initialize();
      return null;
    }, []);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Obx(() {
              final theme = themeController.currentThemeConfig;
              return AppBar(
                title: const Text(
                  'MODEL MANAGER',
                  style: TextStyle(
                    letterSpacing: 3,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.onBackground.withValues(alpha: 0.8),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.back();
                  },
                ),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.background.withValues(alpha: 0.95),
                        theme.background.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      body: Obx(() {
        final theme = themeController.currentThemeConfig;
        return Container(
          color: theme.background,
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              
              // Tab Bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.onBackground.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'OFFICIAL',
                        isSelected: selectedTab.value == 0,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          selectedTab.value = 0;
                        },
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        label: 'IMPORTED',
                        isSelected: selectedTab.value == 1,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          selectedTab.value = 1;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Model List
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: selectedTab.value == 0
                      ? _OfficialModelsList(modelManager: modelManager)
                      : _ImportedModelsList(modelManager: modelManager),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: selectedTab.value == 1
          ? Obx(() {
              final theme = themeController.currentThemeConfig;
              return FloatingActionButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _importModel(context, modelManager);
                },
                backgroundColor: theme.primary,
                child: Icon(
                  Icons.add,
                  color: theme.onPrimary,
                ),
              );
            })
          : null,
    );
  }
  
  Future<void> _importModel(BuildContext context, ModelManagerService modelManager) async {
    try {
      // Show immediate loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Small delay to ensure dialog is shown
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Pick a model file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Show import configuration dialog
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => ModelImportDialog(
              modelFile: file,
              onImport: (model) {
                // Model imported successfully, refresh the list
                modelManager.initialize();
              },
            ),
          );
        }
      }
    } catch (e) {
      // Make sure to close loading indicator on error
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _TabButton extends HookWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    return Obx(() {
      final theme = themeController.currentThemeConfig;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? theme.primary
                    : theme.onBackground.withValues(alpha: 0.5),
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _OfficialModelsList extends StatelessWidget {
  final ModelManagerService modelManager;
  
  const _OfficialModelsList({required this.modelManager});
  
  Future<void> _selectModel(BuildContext context, GemmaModel model, ModelManagerService modelManager) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Initializing ${model.name}...'),
            ),
          ],
        ),
      ),
    );
    
    final success = await modelManager.selectModel(model.id);
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} selected successfully'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize ${model.name}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  Future<void> _showDeleteConfirmation(BuildContext context, GemmaModel model, ModelManagerService modelManager) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete ${model.name}?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await modelManager.deleteModel(model.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    return ListenableBuilder(
      listenable: modelManager,
      builder: (context, _) {
        final models = ModelRegistry.officialModels;
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: models.length,
          itemBuilder: (context, index) {
            final model = models[index];
            final status = modelManager.getModelStatus(model.id);
            final isDownloaded = modelManager.isModelDownloaded(model.id);
            final isDownloading = modelManager.isModelDownloading(model.id);
            final isSelected = modelManager.selectedModelId == model.id;
            
            return Obx(() {
              final theme = themeController.currentThemeConfig;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? theme.primary.withValues(alpha: 0.5)
                        : theme.onBackground.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      model.name,
                                      style: TextStyle(
                                        color: theme.onBackground,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      model.description,
                                      style: TextStyle(
                                        color: theme.onBackground.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: theme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _InfoChip(
                                icon: Icons.storage,
                                label: model.formattedSize,
                              ),
                              const SizedBox(width: 8),
                              _InfoChip(
                                icon: Icons.memory,
                                label: model.formattedMemory,
                              ),
                              if (model.supportsImage) ...[
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: Icons.image,
                                  label: 'Image',
                                ),
                              ],
                              if (model.supportsAudio) ...[
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: Icons.audiotrack,
                                  label: 'Audio',
                                ),
                              ],
                            ],
                          ),
                          if (isDownloading) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: status?.downloadProgress ?? 0,
                              backgroundColor: theme.onBackground.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${((status?.downloadProgress ?? 0) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: theme.onBackground.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isDownloaded && !isDownloading)
                                _ActionButton(
                                  label: 'DOWNLOAD',
                                  icon: Icons.download,
                                  onTap: () => modelManager.downloadModel(model.id),
                                ),
                              if (isDownloading)
                                _ActionButton(
                                  label: 'CANCEL',
                                  icon: Icons.cancel,
                                  onTap: () => modelManager.cancelDownload(model.id),
                                ),
                              if (isDownloaded && !isSelected)
                                _ActionButton(
                                  label: 'USE',
                                  icon: Icons.play_arrow,
                                  onTap: () => _selectModel(context, model, modelManager),
                                ),
                              if (isDownloaded)
                                const SizedBox(width: 8),
                              if (isDownloaded)
                                _ActionButton(
                                  label: 'DELETE',
                                  icon: Icons.delete,
                                  isDestructive: true,
                                  onTap: () => _showDeleteConfirmation(context, model, modelManager),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }
}

class _ImportedModelsList extends StatelessWidget {
  final ModelManagerService modelManager;
  
  const _ImportedModelsList({required this.modelManager});
  
  Future<void> _selectModel(BuildContext context, GemmaModel model, ModelManagerService modelManager) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Initializing ${model.name}...'),
            ),
          ],
        ),
      ),
    );
    
    final success = await modelManager.selectModel(model.id);
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} selected successfully'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize ${model.name}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  Future<void> _showDeleteConfirmation(BuildContext context, GemmaModel model, ModelManagerService modelManager) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete ${model.name}?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await modelManager.deleteModel(model.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    return ListenableBuilder(
      listenable: modelManager,
      builder: (context, _) {
        final models = ModelRegistry.getImportedModels();
        
        if (models.isEmpty) {
          return Center(
            child: Obx(() {
              final theme = themeController.currentThemeConfig;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: theme.onBackground.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No imported models',
                    style: TextStyle(
                      color: theme.onBackground.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to import a model file',
                    style: TextStyle(
                      color: theme.onBackground.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: models.length,
          itemBuilder: (context, index) {
            final model = models[index];
            final isSelected = modelManager.selectedModelId == model.id;
            
            return Obx(() {
              final theme = themeController.currentThemeConfig;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? theme.primary.withValues(alpha: 0.5)
                        : theme.onBackground.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      model.name,
                                      style: TextStyle(
                                        color: theme.onBackground,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      model.modelFile,
                                      style: TextStyle(
                                        color: theme.onBackground.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: theme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _InfoChip(
                                icon: Icons.storage,
                                label: model.formattedSize,
                              ),
                              if (model.supportsImage) ...[
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: Icons.image,
                                  label: 'Image',
                                ),
                              ],
                              if (model.supportsAudio) ...[
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: Icons.audiotrack,
                                  label: 'Audio',
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isSelected)
                                _ActionButton(
                                  label: 'USE',
                                  icon: Icons.play_arrow,
                                  onTap: () => _selectModel(context, model, modelManager),
                                ),
                              const SizedBox(width: 8),
                              _ActionButton(
                                label: 'DELETE',
                                icon: Icons.delete,
                                isDestructive: true,
                                onTap: () => _showDeleteConfirmation(context, model, modelManager),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _InfoChip({
    required this.icon,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    return Obx(() {
      final theme = themeController.currentThemeConfig;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.onBackground.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: theme.onBackground.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.onBackground.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ActionButton extends HookWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
  
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    return Obx(() {
      final theme = themeController.currentThemeConfig;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDestructive
                    ? theme.error.withValues(alpha: 0.3)
                    : theme.onBackground.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isDestructive
                      ? theme.error
                      : theme.onBackground.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isDestructive
                        ? theme.error
                        : theme.onBackground.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}