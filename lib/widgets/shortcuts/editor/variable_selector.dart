import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/variable.dart';
import '../../../models/shortcuts/shortcut_definition.dart' show VariableType;

class VariableSelector extends HookWidget {
  final List<Variable> variables;
  final String? selectedVariableId;
  final Function(String?) onVariableSelected;
  final bool allowClear;
  final String? hint;

  const VariableSelector({
    super.key,
    required this.variables,
    this.selectedVariableId,
    required this.onVariableSelected,
    this.allowClear = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final isDropdownOpen = useState(false);
    final searchQuery = useState('');
    final layerLink = useMemoized(() => LayerLink());

    // Get selected variable
    final selectedVariable = variables.firstWhereOrNull(
      (v) => v.id == selectedVariableId,
    );

    // Filter variables based on search
    final filteredVariables = useMemoized(() {
      if (searchQuery.value.isEmpty) return variables;

      final query = searchQuery.value.toLowerCase();
      return variables
          .where((v) =>
              v.name.toLowerCase().contains(query) ||
              (v.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }, [variables, searchQuery.value]);

    // Group variables by source
    final groupedVariables = useMemoized(() {
      final groups = <VariableSource, List<Variable>>{};
      for (final variable in filteredVariables) {
        groups.putIfAbsent(variable.source, () => []).add(variable);
      }
      return groups;
    }, [filteredVariables]);

    return CompositedTransformTarget(
      link: layerLink,
      child: InkWell(
        onTap: () {
          isDropdownOpen.value = !isDropdownOpen.value;
          if (isDropdownOpen.value) {
            _showDropdown(
              context: context,
              layerLink: layerLink,
              theme: theme,
              searchQuery: searchQuery,
              groupedVariables: groupedVariables,
              selectedVariableId: selectedVariableId,
              onVariableSelected: (variableId) {
                onVariableSelected(variableId);
                isDropdownOpen.value = false;
                searchQuery.value = '';
              },
              onClose: () {
                isDropdownOpen.value = false;
                searchQuery.value = '';
              },
              allowClear: allowClear,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDropdownOpen.value
                  ? theme.primary
                  : theme.onSurface.withValues(alpha: 0.1),
              width: isDropdownOpen.value ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selectedVariable != null) ...[
                // Selected variable
                Icon(
                  _getTypeIcon(selectedVariable.type),
                  size: 18,
                  color: theme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedVariable.name,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selectedVariable.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          selectedVariable.description!,
                          style: TextStyle(
                            color: theme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Placeholder
                Icon(
                  Icons.code,
                  size: 18,
                  color: theme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hint ?? 'Select a variable',
                    style: TextStyle(
                      color: theme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
              Icon(
                isDropdownOpen.value
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
                color: theme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDropdown({
    required BuildContext context,
    required LayerLink layerLink,
    required dynamic theme,
    required ValueNotifier<String> searchQuery,
    required Map<VariableSource, List<Variable>> groupedVariables,
    required String? selectedVariableId,
    required Function(String?) onVariableSelected,
    required VoidCallback onClose,
    required bool allowClear,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop to detect outside clicks
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry.remove();
                onClose();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown
          CompositedTransformFollower(
            link: layerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 8),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: theme.surface,
              child: Container(
                width: 300,
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: TextField(
                        autofocus: true,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search variables...',
                          hintStyle: TextStyle(
                            color: theme.onSurface.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: theme.onSurface.withValues(alpha: 0.4),
                          ),
                          filled: true,
                          fillColor: theme.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) => searchQuery.value = value,
                      ),
                    ),

                    // Variables list
                    Flexible(
                      child: groupedVariables.isEmpty
                          ? _buildEmptyState(theme)
                          : ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                if (allowClear &&
                                    selectedVariableId != null) ...[
                                  _buildClearOption(
                                    theme: theme,
                                    onTap: () {
                                      overlayEntry.remove();
                                      onVariableSelected(null);
                                    },
                                  ),
                                  const Divider(height: 1),
                                ],
                                ...groupedVariables.entries.map((entry) {
                                  return _buildVariableGroup(
                                    source: entry.key,
                                    variables: entry.value,
                                    theme: theme,
                                    selectedVariableId: selectedVariableId,
                                    onSelect: (variable) {
                                      overlayEntry.remove();
                                      onVariableSelected(variable.id);
                                    },
                                  );
                                }),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(overlayEntry);
  }

  Widget _buildEmptyState(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 32,
            color: theme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            'No variables found',
            style: TextStyle(
              color: theme.onSurface.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearOption({
    required dynamic theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.clear,
              size: 18,
              color: theme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Text(
              'Clear selection',
              style: TextStyle(
                color: theme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableGroup({
    required VariableSource source,
    required List<Variable> variables,
    required dynamic theme,
    required String? selectedVariableId,
    required Function(Variable) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Group header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                _getSourceIcon(source),
                size: 14,
                color: theme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                source.displayName,
                style: TextStyle(
                  color: theme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Variables
        ...variables.map((variable) => _buildVariableItem(
              variable: variable,
              theme: theme,
              isSelected: variable.id == selectedVariableId,
              onTap: () => onSelect(variable),
            )),
      ],
    );
  }

  Widget _buildVariableItem({
    required Variable variable,
    required dynamic theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected ? theme.primary.withValues(alpha: 0.1) : null,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (isSelected ? theme.primary : theme.onSurface)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTypeIcon(variable.type),
                size: 16,
                color: isSelected ? theme.primary : theme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        variable.name,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          variable.type.displayName,
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (variable.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      variable.description!,
                      style: TextStyle(
                        color: theme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 18,
                color: theme.primary,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(VariableType type) {
    switch (type) {
      case VariableType.string:
        return Icons.text_fields;
      case VariableType.number:
        return Icons.numbers;
      case VariableType.boolean:
        return Icons.toggle_on;
      case VariableType.date:
        return Icons.calendar_today;
      case VariableType.list:
        return Icons.list;
      case VariableType.map:
        return Icons.data_object;
      case VariableType.imageList:
        return Icons.image;
    }
  }

  IconData _getSourceIcon(VariableSource source) {
    switch (source) {
      case VariableSource.userInput:
        return Icons.keyboard;
      case VariableSource.system:
        return Icons.settings;
      case VariableSource.calculated:
        return Icons.calculate;
      case VariableSource.constant:
        return Icons.lock;
    }
  }
}
