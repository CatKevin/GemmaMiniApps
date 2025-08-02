import 'package:flutter/material.dart';
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
    
    // Initialize storage and load shortcuts
    useEffect(() {
      Future<void> loadShortcuts() async {
        isLoading.value = true;
        try {
          // Initialize storage service
          final service = await ShortcutsStorageService.initialize();
          storageService.value = service;
          
          // Create default shortcuts if none exist
          await service.createDefaultShortcuts();
          
          // Load all shortcuts
          final allShortcuts = await service.getAllShortcuts();
          shortcuts.value = allShortcuts;
          filteredShortcuts.value = allShortcuts;
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
      
      loadShortcuts();
      return null;
    }, []);
    
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
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
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
                            );
                          },
                        ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Routes.toShortcutsEditor();
        },
        backgroundColor: themeController.currentThemeConfig.primary,
        child: Icon(
          Icons.add,
          color: themeController.currentThemeConfig.onPrimary,
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final ShortcutDefinition shortcut;
  final VoidCallback onTap;
  
  const _ShortcutCard({
    required this.shortcut,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              shortcut.icon.iconData,
              size: 32,
              color: theme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              shortcut.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: theme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              shortcut.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: theme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${shortcut.usageCount} uses',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
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
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              shortcut.icon.iconData,
              color: theme.primary,
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