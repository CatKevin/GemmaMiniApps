import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../core/theme/controllers/theme_controller.dart';
import '../../../models/shortcuts/models.dart';
import 'variable_embed.dart';

class RichTextField extends HookWidget {
  final String initialContent;
  final Function(String) onContentChanged;
  final Map<String, VariableDefinition> availableVariables;
  final String label;
  
  const RichTextField({
    super.key,
    required this.initialContent,
    required this.onContentChanged,
    required this.availableVariables,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    // Register variable embed on first build
    useEffect(() {
      registerVariableEmbed();
      return null;
    }, const []);
    
    final controller = useMemoized(() {
      if (initialContent.isEmpty) {
        return quill.QuillController.basic();
      }
      
      // Convert plain text with {{variables}} to Quill document
      final doc = VariableEmbedExtension.fromPromptTemplate(initialContent);
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    });
    
    final focusNode = useFocusNode();
    final showVariableMenu = useState(false);
    final variableMenuOffset = useState(Offset.zero);
    
    // Listen for @ character to show variable menu
    useEffect(() {
      void listener() {
        final text = controller.document.toPlainText();
        final selection = controller.selection;
        
        if (selection.isCollapsed && selection.baseOffset > 0) {
          final charBefore = text.substring(selection.baseOffset - 1, selection.baseOffset);
          if (charBefore == '@') {
            // Show variable menu
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final position = renderBox.localToGlobal(Offset.zero);
              variableMenuOffset.value = Offset(
                position.dx + 50,
                position.dy + 100,
              );
              showVariableMenu.value = true;
            }
          } else {
            showVariableMenu.value = false;
          }
        }
        
        // Update content using the extension method
        onContentChanged(controller.toPromptTemplate());
      }
      
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.onSurface.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Toolbar
              Container(
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: quill.QuillSimpleToolbar(
                  controller: controller,
                  config: quill.QuillSimpleToolbarConfig(
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: false,
                    showInlineCode: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showClearFormat: true,
                    showAlignmentButtons: false,
                    showLeftAlignment: false,
                    showCenterAlignment: false,
                    showRightAlignment: false,
                    showJustifyAlignment: false,
                    showHeaderStyle: false,
                    showListNumbers: true,
                    showListBullets: true,
                    showListCheck: false,
                    showCodeBlock: false,
                    showQuote: false,
                    showIndent: false,
                    showLink: false,
                    showUndo: true,
                    showRedo: true,
                    showDirection: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    customButtons: [
                      quill.QuillToolbarCustomButtonOptions(
                        icon: const Icon(Icons.code, size: 18),
                        tooltip: 'Insert Variable',
                        onPressed: () => _showVariableDialog(context, controller),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Editor
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                child: quill.QuillEditor.basic(
                  controller: controller,
                  focusNode: focusNode,
                  config: quill.QuillEditorConfig(
                    placeholder: 'Enter content with variables...',
                    padding: EdgeInsets.zero,
                    embedBuilders: [
                      VariableEmbedBuilder(),
                    ],
                    customStyles: quill.DefaultStyles(
                      placeHolder: quill.DefaultTextBlockStyle(
                        TextStyle(
                          color: theme.onSurface.withValues(alpha: 0.3),
                          fontSize: 14,
                        ),
                        const quill.HorizontalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Variable chips
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: availableVariables.entries.map((entry) {
            return ActionChip(
              label: Text(
                '{{${entry.key}}}',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              onPressed: () => _insertVariable(controller, entry.key),
              backgroundColor: theme.primary.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: theme.primary,
              ),
            );
          }).toList(),
        ),
        
        // Variable menu overlay
        if (showVariableMenu.value)
          Positioned(
            left: variableMenuOffset.value.dx,
            top: variableMenuOffset.value.dy,
            child: _VariableMenu(
              variables: availableVariables,
              onSelected: (variable) {
                // Remove the @ character and insert variable
                final selection = controller.selection;
                controller.replaceText(
                  selection.baseOffset - 1,
                  1,
                  '',
                  null,
                );
                controller.insertVariable(variable);
                showVariableMenu.value = false;
              },
              onDismiss: () => showVariableMenu.value = false,
            ),
          ),
      ],
    );
  }
  
  void _insertVariable(quill.QuillController controller, String variable) {
    controller.insertVariable(variable);
  }
  
  void _showVariableDialog(BuildContext context, quill.QuillController controller) {
    final theme = ThemeController.to.currentThemeConfig;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Insert Variable',
          style: TextStyle(color: theme.onSurface),
        ),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: availableVariables.length,
            itemBuilder: (context, index) {
              final entry = availableVariables.entries.elementAt(index);
              return ListTile(
                leading: Icon(
                  Icons.code,
                  color: theme.primary,
                  size: 20,
                ),
                title: Text(
                  entry.key,
                  style: TextStyle(
                    color: theme.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
                subtitle: Text(
                  'Type: ${entry.value.type.toString().split('.').last}',
                  style: TextStyle(
                    color: theme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  _insertVariable(controller, entry.key);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(color: theme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariableMenu extends StatelessWidget {
  final Map<String, VariableDefinition> variables;
  final Function(String) onSelected;
  final VoidCallback onDismiss;
  
  const _VariableMenu({
    required this.variables,
    required this.onSelected,
    required this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: variables.length,
          itemBuilder: (context, index) {
            final entry = variables.entries.elementAt(index);
            return InkWell(
              onTap: () => onSelected(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.code,
                      size: 16,
                      color: theme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}