import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../models/shortcuts/models.dart';
import '../../services/shortcuts/storage_service.dart';
import '../routes.dart';

class BasicInfoPage extends HookWidget {
  const BasicInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;

    // Get route arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final shortcutId = args?['shortcutId'] as String?;

    // Loading and data states
    final isLoading = useState(false);
    final existingShortcut = useState<ShortcutDefinition?>(null);

    // Form controllers (initialized with empty values)
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();

    // State
    final selectedIcon = useState<IconData?>(null);
    final selectedColor = useState<Color?>(null);
    final selectedTags = useState<Set<String>>({});
    final showIconPicker = useState(false);
    final nameError = useState<String?>(null);
    final hasInitialized = useState(false);

    // Load existing shortcut if editing
    useEffect(() {
      if (shortcutId != null && !hasInitialized.value) {
        isLoading.value = true;
        ShortcutsStorageService.initialize().then((storage) async {
          final shortcut = await storage.getShortcut(shortcutId);
          if (shortcut != null) {
            existingShortcut.value = shortcut;
            // Update form fields
            nameController.text = shortcut.name;
            descriptionController.text = shortcut.description;
            selectedIcon.value = shortcut.icon.iconData;
            selectedColor.value = shortcut.icon.color ?? theme.primary;
            selectedTags.value = {shortcut.category};
          } else {
            Get.snackbar(
              'Error',
              'Shortcut not found',
              backgroundColor: theme.error,
              colorText: theme.onError,
            );
            Get.back();
          }
          isLoading.value = false;
          hasInitialized.value = true;
        }).catchError((error) {
          Get.snackbar(
            'Error',
            'Failed to load shortcut: $error',
            backgroundColor: theme.error,
            colorText: theme.onError,
          );
          isLoading.value = false;
          Get.back();
        });
      } else {
        hasInitialized.value = true;
      }
      return null;
    }, []);

    // Available icons
    final availableIcons = [
      Icons.flash_on,
      Icons.star,
      Icons.favorite,
      Icons.bolt,
      Icons.auto_awesome,
      Icons.psychology,
      Icons.lightbulb,
      Icons.rocket_launch,
      Icons.code,
      Icons.brush,
      Icons.edit_note,
      Icons.calculate,
      Icons.analytics,
      Icons.insights,
      Icons.school,
      Icons.work,
      Icons.business,
      Icons.home,
      Icons.folder,
      Icons.description,
      Icons.email,
      Icons.chat,
      Icons.forum,
      Icons.person,
      Icons.group,
      Icons.public,
      Icons.language,
      Icons.translate,
      Icons.schedule,
      Icons.alarm,
      Icons.event,
      Icons.today,
      Icons.camera,
      Icons.image,
      Icons.music_note,
      Icons.movie,
      Icons.games,
      Icons.sports_esports,
      Icons.fitness_center,
      Icons.restaurant,
      Icons.local_cafe,
      Icons.shopping_cart,
      Icons.attach_money,
      Icons.credit_card,
      Icons.account_balance,
      Icons.trending_up,
      Icons.bar_chart,
      Icons.pie_chart,
      Icons.timeline,
      Icons.cloud,
      Icons.cloud_upload,
      Icons.cloud_download,
      Icons.save,
      Icons.folder_open,
      Icons.settings,
      Icons.build,
      Icons.extension,
      Icons.widgets,
      Icons.dashboard,
      Icons.view_module,
      Icons.list,
      Icons.grid_view,
      Icons.table_chart,
      Icons.assignment,
      Icons.fact_check,
      Icons.task_alt,
      Icons.checklist,
      Icons.rule,
      Icons.policy,
      Icons.gavel,
      Icons.balance,
      Icons.handshake,
      Icons.support_agent,
      Icons.contact_support,
      Icons.help,
      Icons.info,
      Icons.warning,
      Icons.error,
      Icons.check_circle,
      Icons.cancel,
      Icons.block,
      Icons.report,
      Icons.flag,
      Icons.bookmark,
      Icons.label,
      Icons.loyalty,
      Icons.local_offer,
      Icons.sell,
      Icons.discount,
      Icons.redeem,
      Icons.card_giftcard,
      Icons.celebration,
      Icons.emoji_events,
      Icons.military_tech,
      Icons.workspace_premium,
      Icons.verified,
      Icons.security,
      Icons.lock,
      Icons.key,
      Icons.fingerprint,
    ];

    // Available colors - High-tech vibrant palette sorted by color type
    final availableColors = [
      // Blue Series - Tech & Innovation
      const Color(0xFF0EA5E9), // Sky Blue
      const Color(0xFF3B82F6), // Electric Blue
      const Color(0xFF6366F1), // Indigo Blue
      const Color(0xFF06B6D4), // Cyan

      // Purple Series - Creativity & Future
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFA855F7), // Purple
      const Color(0xFFD946EF), // Magenta
      const Color(0xFFE879F9), // Orchid

      // Pink & Red Series - Energy & Passion
      const Color(0xFFEC4899), // Hot Pink
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFEF4444), // Red
      const Color(0xFFDC2626), // Crimson Red

      // Orange & Yellow Series - Warmth & Optimism
      const Color(0xFFF97316), // Orange
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEAB308), // Yellow
      const Color(0xFF84CC16), // Lime

      // Green Series - Growth & Balance
      const Color(0xFF22C55E), // Green
      const Color(0xFF10B981), // Emerald
      const Color(0xFF14B8A6), // Teal
      const Color(0xFF059669), // Deep Green
    ];

    // Available tags
    final availableTags = [
      'Productivity',
      'Creative',
      'Business',
      'Education',
      'Health',
      'Finance',
      'Social',
      'Entertainment',
      'Utility',
      'Development',
      'Research',
      'Writing',
      'Analysis',
      'Communication',
      'Organization',
    ];

    // Initialize random color and icon if not set
    useEffect(() {
      if (shortcutId == null) {
        final random = math.Random();
        
        // Select random color if not set
        if (selectedColor.value == null) {
          selectedColor.value =
              availableColors[random.nextInt(availableColors.length)];
        }
        
        // Select random icon if not set
        if (selectedIcon.value == null) {
          selectedIcon.value =
              availableIcons[random.nextInt(availableIcons.length)];
        }
      }
      return null;
    }, [availableColors, availableIcons]);

    void validateAndProceed() {
      // Validate name
      if (nameController.text.trim().isEmpty) {
        nameError.value = 'Name is required';
        return;
      }

      if (nameController.text.trim().length < 3) {
        nameError.value = 'Name must be at least 3 characters';
        return;
      }

      nameError.value = null;

      // Create initial shortcut data
      final basicInfo = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'icon': selectedIcon.value ?? Icons.flash_on,
        'color': selectedColor.value ?? theme.primary,
        'tags': selectedTags.value.toList(),
        'category': selectedTags.value.isNotEmpty
            ? selectedTags.value.first
            : 'utility',
      };

      // Navigate to editor with basic info
      if (existingShortcut.value != null) {
        Routes.toShortcutsEditor(
          shortcutId: existingShortcut.value!.id,
          basicInfo: basicInfo,
        );
      } else {
        Routes.toShortcutsEditor(basicInfo: basicInfo);
      }
    }

    // Show loading state while fetching data
    if (isLoading.value) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading shortcut...',
                style: TextStyle(
                  color: theme.onBackground.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border(
            top: BorderSide(
              color: theme.onBackground.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                foregroundColor: theme.onSurface.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: validateAndProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 0,
              ),
              child: Row(
                children: [
                  const Text(
                    'Next: Build Editor',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: theme.onPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primary.withValues(alpha: 0.05),
                  theme.background,
                  theme.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back),
                        color: theme.onBackground,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              existingShortcut.value != null
                                  ? 'Edit Shortcut Info'
                                  : 'Create New Shortcut',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: theme.onBackground,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Step 1 of 2: Basic Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: theme.onBackground
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon and color selection
                            Center(
                              child: Column(
                                children: [
                                  // Icon preview
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      showIconPicker.value = true;
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: selectedColor.value ??
                                            theme.primary,
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: theme.onBackground
                                              .withValues(alpha: 0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            selectedIcon.value ?? Icons.flash_on,
                                            size: 56,
                                            color: Colors.white,
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: theme.background,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: theme.onBackground
                                                      .withValues(alpha: 0.1),
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: theme.onBackground
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap to change icon',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: theme.onBackground
                                              .withValues(alpha: 0.4),
                                        ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Color selection
                                  Text(
                                    'Choose Color',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: theme.onBackground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: availableColors.map((color) {
                                      final isSelected =
                                          selectedColor.value != null &&
                                              selectedColor.value == color;
                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          selectedColor.value = color;
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? theme.onBackground
                                                  : color.withValues(
                                                      alpha: 0.3),
                                              width: isSelected ? 3 : 1,
                                            ),
                                            boxShadow: [
                                              if (isSelected)
                                                BoxShadow(
                                                  color: color.withValues(
                                                      alpha: 0.4),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                            ],
                                          ),
                                          child: isSelected
                                              ? Icon(
                                                  Icons.check,
                                                  size: 20,
                                                  color:
                                                      color.computeLuminance() >
                                                              0.5
                                                          ? Colors.black
                                                          : Colors.white,
                                                )
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Name field
                            _buildLabel('Name', theme, context),
                            const SizedBox(height: 12),
                            TextField(
                              controller: nameController,
                              style: TextStyle(color: theme.onBackground),
                              decoration: InputDecoration(
                                hintText: 'Give your shortcut a memorable name',
                                hintStyle: TextStyle(
                                  color:
                                      theme.onBackground.withValues(alpha: 0.4),
                                ),
                                filled: true,
                                fillColor: theme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.onBackground
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.primary,
                                    width: 2,
                                  ),
                                ),
                                errorText: nameError.value,
                                prefixIcon: Icon(
                                  Icons.label_outline,
                                  color:
                                      theme.onBackground.withValues(alpha: 0.6),
                                ),
                              ),
                              onChanged: (_) => nameError.value = null,
                            ),

                            const SizedBox(height: 24),

                            // Description field
                            _buildLabel('Description', theme, context),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descriptionController,
                              style: TextStyle(color: theme.onBackground),
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'What does this shortcut do?',
                                hintStyle: TextStyle(
                                  color:
                                      theme.onBackground.withValues(alpha: 0.4),
                                ),
                                filled: true,
                                fillColor: theme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.onBackground
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.primary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 12,
                                    bottom: 60,
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: theme.onBackground
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Tags
                            _buildLabel(
                                'Tags (Choose up to 3)', theme, context),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableTags.map((tag) {
                                final isSelected = selectedTags.value
                                    .contains(tag.toLowerCase());
                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    final tags =
                                        Set<String>.from(selectedTags.value);
                                    if (isSelected) {
                                      tags.remove(tag.toLowerCase());
                                    } else if (tags.length < 3) {
                                      tags.add(tag.toLowerCase());
                                    } else {
                                      Get.snackbar(
                                        'Tag Limit',
                                        'You can select up to 3 tags',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: theme.surface,
                                        colorText: theme.onSurface,
                                        margin: const EdgeInsets.all(16),
                                        borderRadius: 12,
                                      );
                                    }
                                    selectedTags.value = tags;
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? selectedColor.value!
                                              .withValues(alpha: 0.1)
                                          : theme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? selectedColor.value!
                                            : theme.onBackground
                                                .withValues(alpha: 0.2),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected)
                                          Icon(
                                            Icons.check,
                                            size: 16,
                                            color: selectedColor.value!,
                                          ),
                                        if (isSelected)
                                          const SizedBox(width: 4),
                                        Text(
                                          tag,
                                          style: TextStyle(
                                            color: isSelected
                                                ? selectedColor.value!
                                                : theme.onBackground,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Icon picker overlay
          if (showIconPicker.value)
            _buildIconPicker(
              context: context,
              theme: theme,
              availableIcons: availableIcons,
              selectedIcon: selectedIcon,
              onClose: () => showIconPicker.value = false,
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, dynamic theme, BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: theme.onBackground,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildIconPicker({
    required BuildContext context,
    required dynamic theme,
    required List<IconData> availableIcons,
    required ValueNotifier<IconData?> selectedIcon,
    required VoidCallback onClose,
  }) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent close on dialog tap
            child: Container(
              width: 400,
              height: 500,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
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
                        Text(
                          'Choose Icon',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: theme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close),
                          color: theme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),

                  // Icons grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = selectedIcon.value == icon;

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            selectedIcon.value = icon;
                            onClose();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primary.withValues(alpha: 0.1)
                                  : theme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primary
                                    : theme.onSurface.withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color:
                                  isSelected ? theme.primary : theme.onSurface,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to add firstWhereOrNull
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
