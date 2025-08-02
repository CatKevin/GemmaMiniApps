import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../core/theme/controllers/theme_controller.dart';

/// Custom embed type for variables
class VariableEmbed extends quill.CustomBlockEmbed {
  const VariableEmbed(String value) : super(variableType, value);
  
  static const String variableType = 'variable';
  
  static VariableEmbed fromVariable(String variableName) {
    return VariableEmbed(variableName);
  }
  
  String get variableName => data;
}

/// Builder for variable embeds
class VariableEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => VariableEmbed.variableType;
  
  @override
  Widget build(
    BuildContext context,
    quill.EmbedContext embedContext,
  ) {
    final variableName = embedContext.node.value.data as String;
    
    return InlineVariableChip(
      variableName: variableName,
      onTap: embedContext.readOnly ? null : () {
        // Handle tap if needed
      },
    );
  }
}

/// Inline variable chip widget
class InlineVariableChip extends StatelessWidget {
  final String variableName;
  final VoidCallback? onTap;
  
  const InlineVariableChip({
    super.key,
    required this.variableName,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.code,
              size: 14,
              color: theme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              variableName,
              style: TextStyle(
                color: theme.primary,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to register the variable embed
void registerVariableEmbed() {
  // Note: In flutter_quill 11.4.2, embed registration is handled
  // through the embedBuilders configuration when creating QuillEditor
  // This function is kept for backward compatibility but may not be needed
}

/// Extension to make working with variable embeds easier
extension VariableEmbedExtension on quill.QuillController {
  /// Insert a variable at the current cursor position
  void insertVariable(String variableName) {
    final index = selection.baseOffset;
    final embed = VariableEmbed.fromVariable(variableName);
    
    replaceText(
      index,
      0,
      quill.BlockEmbed.custom(embed),
      null,
    );
    
    // Move cursor after the embed
    updateSelection(
      TextSelection.collapsed(offset: index + 1),
      quill.ChangeSource.local,
    );
  }
  
  /// Get all variables in the document
  List<String> getAllVariables() {
    final variables = <String>[];
    
    for (final op in document.toDelta().toList()) {
      if (op.data is Map) {
        final data = op.data as Map;
        if (data['custom'] != null) {
          final custom = data['custom'];
          if (custom['type'] == VariableEmbed.variableType) {
            variables.add(custom['value'] as String);
          }
        }
      }
    }
    
    return variables;
  }
  
  /// Convert document to text with {{variable}} syntax
  String toPromptTemplate() {
    final buffer = StringBuffer();
    
    for (final op in document.toDelta().toList()) {
      if (op.data is String) {
        buffer.write(op.data);
      } else if (op.data is Map) {
        final data = op.data as Map;
        if (data['custom'] != null) {
          final custom = data['custom'];
          if (custom['type'] == VariableEmbed.variableType) {
            buffer.write('{{${custom['value']}}}');
          }
        }
      }
    }
    
    return buffer.toString();
  }
  
  /// Create document from text with {{variable}} syntax
  static quill.Document fromPromptTemplate(String template) {
    final doc = quill.Document();
    final regex = RegExp(r'\{\{(\w+)\}\}');
    
    int lastEnd = 0;
    for (final match in regex.allMatches(template)) {
      // Add text before the variable
      if (match.start > lastEnd) {
        doc.insert(doc.length - 1, template.substring(lastEnd, match.start));
      }
      
      // Add the variable as an embed
      final variableName = match.group(1)!;
      final embed = VariableEmbed.fromVariable(variableName);
      doc.insert(
        doc.length - 1,
        quill.BlockEmbed.custom(embed),
      );
      
      lastEnd = match.end;
    }
    
    // Add any remaining text
    if (lastEnd < template.length) {
      doc.insert(doc.length - 1, template.substring(lastEnd));
    }
    
    return doc;
  }
}