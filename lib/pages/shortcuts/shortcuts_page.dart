import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../routes.dart';
import '../../models/shortcuts/models.dart';
import '../../services/shortcuts/storage_service.dart';

class ShortcutsPage extends HookWidget {
  const ShortcutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    // State management
    final selectedCategory = useState<ShortcutCategory?>(null);
    final searchQuery = useState('');
    final shortcuts = useState<List<ShortcutDefinition>>([]);
    final filteredShortcuts = useState<List<ShortcutDefinition>>([]);
    final isLoading = useState(false);
    final storageService = useState<ShortcutsStorageService?>(null);
    final lastLoadTime = useState<DateTime?>(null);
    
    // Load shortcuts function
    Future<void> loadShortcuts() async {
      if (isLoading.value) return; // Prevent duplicate loading
      
      isLoading.value = true;
      try {
        // Initialize storage service if not already initialized
        if (storageService.value == null) {
          final service = await ShortcutsStorageService.initialize();
          storageService.value = service;
          
          // Create default shortcuts if none exist
          await service.createDefaultShortcuts();
        }
        
        // Load all shortcuts
        final allShortcuts = await storageService.value!.getAllShortcuts();
        shortcuts.value = allShortcuts;
        filteredShortcuts.value = allShortcuts;
        lastLoadTime.value = DateTime.now();
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to load shortcuts: ${e.toString()}',
          backgroundColor: themeController.currentThemeConfig.error,
          colorText: themeController.currentThemeConfig.onError,
        );
      } finally {
        isLoading.value = false;
      }
    }
    
    // Initialize and load shortcuts on first build
    useEffect(() {
      loadShortcuts();
      return null;
    }, []);
    
    // Refresh shortcuts when navigating back to this page
    useEffect(() {
      // Check if we need to refresh when the widget rebuilds
      if (lastLoadTime.value != null) {
        final now = DateTime.now();
        final timeSinceLastLoad = now.difference(lastLoadTime.value!);
        
        // Refresh if more than 2 seconds have passed (likely navigated back)
        if (timeSinceLastLoad.inSeconds > 2) {
          loadShortcuts();
        }
      }
      
      return null;
    });
    
    // Filter shortcuts when category or search changes
    useEffect(() {
      List<ShortcutDefinition> filtered = shortcuts.value;
      
      // Apply category filter
      if (selectedCategory.value != null) {
        filtered = filtered.where((s) => 
          s.category == selectedCategory.value!.name
        ).toList();
      }
      
      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        filtered = filtered.where((s) => 
          s.name.toLowerCase().contains(query) ||
          s.description.toLowerCase().contains(query)
        ).toList();
      }
      
      filteredShortcuts.value = filtered;
      return null;
    }, [selectedCategory.value, searchQuery.value, shortcuts.value]);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHORTCUTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading.value ? null : () => loadShortcuts(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ShortcutSearchDelegate(
                  shortcuts: shortcuts.value,
                  onSelected: (shortcut) async {
                    // Update usage statistics
                    if (storageService.value != null) {
                      await storageService.value!.updateUsageStats(shortcut.id);
                    }
                    
                    // Navigate to runtime
                    Routes.toShortcutsRuntime(shortcutId: shortcut.id);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        final theme = themeController.currentThemeConfig;
        
        return Column(
          children: [
            // Category filter chips
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('ALL'),
                      selected: selectedCategory.value == null,
                      onSelected: (selected) {
                        selectedCategory.value = null;
                      },
                      backgroundColor: theme.surface,
                      selectedColor: theme.primary,
                      labelStyle: TextStyle(
                        color: selectedCategory.value == null
                            ? theme.onPrimary
                            : theme.onSurface,
                      ),
                    ),
                  ),
                  ...ShortcutCategory.values.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category.displayName.toUpperCase()),
                        selected: selectedCategory.value == category,
                        onSelected: (selected) {
                          selectedCategory.value = selected ? category : null;
                        },
                        backgroundColor: theme.surface,
                        selectedColor: theme.primary,
                        labelStyle: TextStyle(
                          color: selectedCategory.value == category
                              ? theme.onPrimary
                              : theme.onSurface,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            // Shortcuts grid
            Expanded(
              child: isLoading.value
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primary,
                      ),
                    )
                  : filteredShortcuts.value.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dashboard_customize,
                                size: 64,
                                color: theme.onBackground.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No shortcuts yet',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: theme.onBackground.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first shortcut',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: theme.onBackground.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadShortcuts,
                          backgroundColor: theme.surface,
                          color: theme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredShortcuts.value.length,
                            itemBuilder: (context, index) {
                              final shortcut = filteredShortcuts.value[index];
                              return _ShortcutCard(
                                shortcut: shortcut,
                                onTap: () async {
                                  // Update usage statistics
                                  if (storageService.value != null) {
                                    await storageService.value!.updateUsageStats(shortcut.id);
                                  }
                                  
                                  // Navigate to runtime
                                  Routes.toShortcutsRuntime(shortcutId: shortcut.id);
                                },
                                onLongPress: () => _showContextMenu(
                                  context: context,
                                  shortcut: shortcut,
                                  onEdit: () {
                                    Navigator.of(context).pop();
                                    Routes.toShortcutsBasicInfo(shortcutId: shortcut.id);
                                  },
                                  onDelete: () async {
                                  Navigator.of(context).pop();
                                  
                                  // Show delete confirmation
                                  final confirmed = await Get.dialog<bool>(
                                    AlertDialog(
                                      title: const Text('Delete Shortcut'),
                                      content: Text('Are you sure you want to delete "${shortcut.name}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(result: false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Get.back(result: true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: theme.error,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                  
                                  if (confirmed && storageService.value != null) {
                                    final success = await storageService.value!.deleteShortcut(shortcut.id);
                                    if (success) {
                                      // Reload shortcuts
                                      final allShortcuts = await storageService.value!.getAllShortcuts();
                                      shortcuts.value = allShortcuts;
                                      
                                      Get.snackbar(
                                        'Success',
                                        'Shortcut deleted successfully',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    }
                                  }
                                },
                                onDuplicate: () async {
                                  Navigator.of(context).pop();
                                  
                                  // Create a duplicate
                                  final duplicate = shortcut.copyWith(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    name: '${shortcut.name} (Copy)',
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    usageCount: 0,
                                  );
                                  
                                  if (storageService.value != null) {
                                    final success = await storageService.value!.saveShortcut(duplicate);
                                    if (success) {
                                      // Reload shortcuts
                                      final allShortcuts = await storageService.value!.getAllShortcuts();
                                      shortcuts.value = allShortcuts;
                                      
                                      Get.snackbar(
                                        'Success',
                                        'Shortcut duplicated successfully',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Routes.toShortcutsBasicInfo();
        },
        backgroundColor: themeController.currentThemeConfig.primary,
        child: Icon(
          Icons.add,
          color: themeController.currentThemeConfig.onPrimary,
        ),
      ),
    );
  }
  
  void _showContextMenu({
    required BuildContext context,
    required ShortcutDefinition shortcut,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onDuplicate,
  }) {
    final theme = ThemeController.to.currentThemeConfig;
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with shortcut info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: shortcut.icon.color ?? theme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          shortcut.icon.iconData,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shortcut.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: theme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shortcut.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: theme.onSurface.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu options
                _ContextMenuItem(
                  icon: Icons.play_circle_outline,
                  label: 'Run Shortcut',
                  onTap: () {
                    Navigator.of(context).pop();
                    Routes.toShortcutsRuntime(shortcutId: shortcut.id);
                  },
                ),
                _ContextMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: onEdit,
                ),
                _ContextMenuItem(
                  icon: Icons.content_copy_rounded,
                  label: 'Duplicate',
                  onTap: onDuplicate,
                ),
                _ContextMenuItem(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Implement share functionality
                    Get.snackbar(
                      'Coming Soon',
                      'Share functionality will be available soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: theme.onSurface.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 8),
                _ContextMenuItem(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: theme.error,
                  onTap: onDelete,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final ShortcutDefinition shortcut;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  
  const _ShortcutCard({
    required this.shortcut,
    required this.onTap,
    this.onLongPress,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: shortcut.icon.color ?? theme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  shortcut.icon.iconData,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and category
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shortcut.name,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: theme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ShortcutCategory.fromString(shortcut.category).displayName,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: theme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      shortcut.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: theme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Stats row
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: theme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${shortcut.usageCount} uses',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: theme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.update,
                          size: 14,
                          color: theme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(shortcut.updatedAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: theme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: theme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}

class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  
  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final effectiveColor = color ?? theme.onSurface;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: effectiveColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutSearchDelegate extends SearchDelegate<ShortcutDefinition?> {
  final List<ShortcutDefinition> shortcuts;
  final Function(ShortcutDefinition) onSelected;
  
  _ShortcutSearchDelegate({
    required this.shortcuts,
    required this.onSelected,
  });
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }
  
  Widget _buildSearchResults(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    final results = shortcuts.where((shortcut) {
      final queryLower = query.toLowerCase();
      return shortcut.name.toLowerCase().contains(queryLower) ||
             shortcut.description.toLowerCase().contains(queryLower) ||
             shortcut.category.toLowerCase().contains(queryLower);
    }).toList();
    
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.onBackground.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No shortcuts found',
              style: TextStyle(
                color: theme.onBackground.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                color: theme.onBackground.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final shortcut = results[index];
        final category = ShortcutCategory.fromString(shortcut.category);
        
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: shortcut.icon.color ?? theme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              shortcut.icon.iconData,
              color: Colors.white,
            ),
          ),
          title: Text(
            shortcut.name,
            style: TextStyle(
              color: theme.onBackground,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shortcut.description,
                style: TextStyle(
                  color: theme.onBackground.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    category.icon,
                    size: 12,
                    color: theme.onBackground.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.displayName,
                    style: TextStyle(
                      color: theme.onBackground.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            close(context, shortcut);
            onSelected(shortcut);
          },
        );
      },
    );
  }
  
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final isDark = theme.background == const Color(0xFF000000);
    
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: theme.background,
      scaffoldBackgroundColor: theme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: theme.background,
        iconTheme: IconThemeData(color: theme.onBackground),
        titleTextStyle: TextStyle(
          color: theme.onBackground,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: theme.onBackground.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
      ),
    );
  }
}