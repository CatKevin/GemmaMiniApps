import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/shortcuts/models.dart';

/// Service for persisting shortcuts data
class ShortcutsStorageService {
  static const String _shortcutsKey = 'shortcuts_data';
  static const String _lastUsedKey = 'shortcuts_last_used';
  static const String _usageCountKey = 'shortcuts_usage_count';
  
  final SharedPreferences _prefs;
  
  ShortcutsStorageService(this._prefs);
  
  /// Initialize the storage service
  static Future<ShortcutsStorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return ShortcutsStorageService(prefs);
  }
  
  /// Save a shortcut
  Future<bool> saveShortcut(ShortcutDefinition shortcut) async {
    try {
      final shortcuts = await getAllShortcuts();
      final index = shortcuts.indexWhere((s) => s.id == shortcut.id);
      
      if (index >= 0) {
        shortcuts[index] = shortcut;
      } else {
        shortcuts.add(shortcut);
      }
      
      return await _saveAllShortcuts(shortcuts);
    } catch (e) {
      print('Error saving shortcut: $e');
      return false;
    }
  }
  
  /// Update an existing shortcut
  Future<bool> updateShortcut(ShortcutDefinition shortcut) async {
    return saveShortcut(shortcut);
  }
  
  /// Get all shortcuts
  Future<List<ShortcutDefinition>> getAllShortcuts() async {
    try {
      final jsonString = _prefs.getString(_shortcutsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ShortcutDefinition.fromJson(json)).toList();
    } catch (e) {
      print('Error loading shortcuts: $e');
      return [];
    }
  }
  
  /// Get shortcut by ID
  Future<ShortcutDefinition?> getShortcut(String id) async {
    final shortcuts = await getAllShortcuts();
    return shortcuts.firstWhere(
      (s) => s.id == id,
      orElse: () => null as dynamic,
    );
  }
  
  /// Delete a shortcut
  Future<bool> deleteShortcut(String id) async {
    try {
      final shortcuts = await getAllShortcuts();
      shortcuts.removeWhere((s) => s.id == id);
      return await _saveAllShortcuts(shortcuts);
    } catch (e) {
      print('Error deleting shortcut: $e');
      return false;
    }
  }
  
  /// Get shortcuts by category
  Future<List<ShortcutDefinition>> getShortcutsByCategory(String category) async {
    final shortcuts = await getAllShortcuts();
    return shortcuts.where((s) => s.category == category).toList();
  }
  
  /// Search shortcuts
  Future<List<ShortcutDefinition>> searchShortcuts(String query) async {
    final shortcuts = await getAllShortcuts();
    final lowerQuery = query.toLowerCase();
    
    return shortcuts.where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
             s.description.toLowerCase().contains(lowerQuery) ||
             s.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
  
  /// Update usage statistics
  Future<void> updateUsageStats(String shortcutId) async {
    // Update usage count
    final countKey = '$_usageCountKey.$shortcutId';
    final currentCount = _prefs.getInt(countKey) ?? 0;
    await _prefs.setInt(countKey, currentCount + 1);
    
    // Update last used time
    final lastUsedKey = '$_lastUsedKey.$shortcutId';
    await _prefs.setString(lastUsedKey, DateTime.now().toIso8601String());
    
    // Update the shortcut's usage count
    final shortcut = await getShortcut(shortcutId);
    if (shortcut != null) {
      final updated = shortcut.copyWith(
        usageCount: currentCount + 1,
        updatedAt: DateTime.now(),
      );
      await saveShortcut(updated);
    }
  }
  
  /// Get usage statistics for a shortcut
  Future<Map<String, dynamic>> getUsageStats(String shortcutId) async {
    final countKey = '$_usageCountKey.$shortcutId';
    final lastUsedKey = '$_lastUsedKey.$shortcutId';
    
    final count = _prefs.getInt(countKey) ?? 0;
    final lastUsedString = _prefs.getString(lastUsedKey);
    final lastUsed = lastUsedString != null 
        ? DateTime.parse(lastUsedString) 
        : null;
    
    return {
      'usageCount': count,
      'lastUsed': lastUsed,
    };
  }
  
  /// Get most used shortcuts
  Future<List<ShortcutDefinition>> getMostUsedShortcuts({int limit = 5}) async {
    final shortcuts = await getAllShortcuts();
    shortcuts.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return shortcuts.take(limit).toList();
  }
  
  /// Get recently used shortcuts
  Future<List<ShortcutDefinition>> getRecentlyUsedShortcuts({int limit = 5}) async {
    final shortcuts = await getAllShortcuts();
    final List<MapEntry<ShortcutDefinition, DateTime?>> shortcutsWithLastUsed = [];
    
    for (final shortcut in shortcuts) {
      final stats = await getUsageStats(shortcut.id);
      shortcutsWithLastUsed.add(MapEntry(shortcut, stats['lastUsed']));
    }
    
    shortcutsWithLastUsed.sort((a, b) {
      if (a.value == null && b.value == null) return 0;
      if (a.value == null) return 1;
      if (b.value == null) return -1;
      return b.value!.compareTo(a.value!);
    });
    
    return shortcutsWithLastUsed
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Export shortcuts to JSON
  Future<String> exportShortcuts(List<String> shortcutIds) async {
    final shortcuts = await getAllShortcuts();
    final toExport = shortcuts.where((s) => shortcutIds.contains(s.id)).toList();
    
    return json.encode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'shortcuts': toExport.map((s) => s.toJson()).toList(),
    });
  }
  
  /// Import shortcuts from JSON
  Future<ImportResult> importShortcuts(String jsonString) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> shortcutsJson = data['shortcuts'] ?? [];
      
      int imported = 0;
      int skipped = 0;
      final List<String> errors = [];
      
      for (final json in shortcutsJson) {
        try {
          final shortcut = ShortcutDefinition.fromJson(json);
          final existing = await getShortcut(shortcut.id);
          
          if (existing != null) {
            skipped++;
          } else {
            await saveShortcut(shortcut);
            imported++;
          }
        } catch (e) {
          errors.add('Failed to import shortcut: $e');
        }
      }
      
      return ImportResult(
        imported: imported,
        skipped: skipped,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        imported: 0,
        skipped: 0,
        errors: ['Invalid import file: $e'],
      );
    }
  }
  
  /// Clear all shortcuts
  Future<bool> clearAllShortcuts() async {
    try {
      await _prefs.remove(_shortcutsKey);
      // Clear all usage stats
      final keys = _prefs.getKeys().where((key) => 
        key.startsWith(_usageCountKey) || key.startsWith(_lastUsedKey)
      );
      for (final key in keys) {
        await _prefs.remove(key);
      }
      return true;
    } catch (e) {
      print('Error clearing shortcuts: $e');
      return false;
    }
  }
  
  /// Save all shortcuts (private helper)
  Future<bool> _saveAllShortcuts(List<ShortcutDefinition> shortcuts) async {
    try {
      final jsonString = json.encode(
        shortcuts.map((s) => s.toJson()).toList()
      );
      return await _prefs.setString(_shortcutsKey, jsonString);
    } catch (e) {
      print('Error saving all shortcuts: $e');
      return false;
    }
  }
  
  /// Create default shortcuts for first-time users
  Future<void> createDefaultShortcuts() async {
    final existingShortcuts = await getAllShortcuts();
    if (existingShortcuts.isNotEmpty) return;
    
    // Create a sample article writing shortcut
    final articleWriter = ShortcutDefinition(
      id: 'default_article_writer',
      name: 'Article Writer',
      description: 'Write professional articles on any topic',
      category: ShortcutCategory.creative.name,
      icon: ShortcutIcon(iconData: Icons.article),
      version: '1.0.0',
      author: 'System',
      isBuiltIn: true,
      screens: [
        ScreenDefinition(
          id: 'main_screen',
          title: 'Article Configuration',
          components: [
            UIComponent(
              id: 'article_type',
              type: ComponentType.singleSelect,
              properties: {
                'label': 'Article Type',
                'options': ['News Report', 'Tech Blog', 'Academic Paper', 'Creative Story'],
              },
              variableBinding: 'articleType',
              validation: ValidationRule(
                type: ValidationType.required,
                parameters: {},
                errorMessage: 'Please select an article type',
              ),
            ),
            UIComponent(
              id: 'topic_input',
              type: ComponentType.textInput,
              properties: {
                'label': 'Article Topic',
                'placeholder': 'Enter your article topic...',
                'maxLength': 100,
              },
              variableBinding: 'topic',
              validation: ValidationRule(
                type: ValidationType.required,
                parameters: {},
                errorMessage: 'Topic is required',
              ),
            ),
            UIComponent(
              id: 'style_select',
              type: ComponentType.multiSelect,
              properties: {
                'label': 'Writing Style',
                'options': ['Professional', 'Easy to understand', 'Humorous', 'Data-driven'],
              },
              variableBinding: 'styles',
            ),
          ],
          actions: {
            'generate': ScreenAction(
              label: 'Generate Article',
              type: ActionType.submit,
              parameters: {},
            ),
          },
        ),
      ],
      startScreenId: 'main_screen',
      transitions: {},
      variables: {
        'articleType': VariableDefinition(
          name: 'articleType',
          type: VariableType.string,
          description: 'Type of article to write',
        ),
        'topic': VariableDefinition(
          name: 'topic',
          type: VariableType.string,
          description: 'Main topic of the article',
        ),
        'styles': VariableDefinition(
          name: 'styles',
          type: VariableType.list,
          defaultValue: [],
          description: 'Selected writing styles',
        ),
      },
      promptTemplate: PromptTemplate(
        sections: [
          PromptSection(
            id: 'role',
            type: PromptSectionType.role,
            content: 'You are a professional {{articleType}} writer with years of experience.',
            order: 1,
          ),
          PromptSection(
            id: 'task',
            type: PromptSectionType.task,
            content: 'Write a comprehensive article about "{{topic}}".',
            order: 2,
          ),
          PromptSection(
            id: 'style',
            type: PromptSectionType.constraints,
            content: 'Writing style requirements: {{styles}}',
            condition: 'styles isNotEmpty',
            order: 3,
          ),
        ],
        assemblyLogic: 'sequential',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      usageCount: 0,
    );
    
    await saveShortcut(articleWriter);
  }
}

/// Result of import operation
class ImportResult {
  final int imported;
  final int skipped;
  final List<String> errors;
  
  ImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get success => imported > 0 && !hasErrors;
}