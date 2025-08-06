import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../models/shortcuts/models.dart';
import '../../widgets/shortcuts/runtime/component_renderer.dart';
import '../../services/shortcuts/prompt_builder.dart';
import '../../services/shortcuts/mock_ai_service.dart';
import '../../services/shortcuts/storage_service.dart';
import '../../controllers/chat/gemma_chat_controller.dart';

class RuntimePage extends HookWidget {
  const RuntimePage({super.key});
  
  // Process Text components to extract their content into output variables
  void _processTextVariables(ShortcutDefinition shortcut, ExecutionContext context) {
    // Process all screens
    for (final screen in shortcut.screens) {
      for (final component in screen.components) {
        _processComponent(component, context);
      }
    }
  }
  
  // Recursively process components including those in composite components
  void _processComponent(UIComponent component, ExecutionContext context) {
    // Check if it's a Text component with output variable
    if (component.type == ComponentType.text && 
        component.properties['outputVariable'] != null &&
        component.properties['outputVariable'].toString().isNotEmpty) {
      final outputVar = component.properties['outputVariable'].toString();
      final content = component.properties['content'] ?? '';
      
      // Process the content to replace variable references
      final processedContent = _processTemplateContent(content, context);
      
      // Set the variable
      context.setVariable(outputVar, processedContent);
    }
    
    // Process composite components recursively
    if (component.properties['isComposite'] == true && 
        component.properties['sections'] != null) {
      final sections = component.properties['sections'] as List;
      for (final section in sections) {
        if (section['children'] != null) {
          final children = section['children'] as List;
          for (final childJson in children) {
            final childComponent = UIComponent.fromJson(childJson);
            _processComponent(childComponent, context);
          }
        }
      }
    }
  }
  
  // Process template content to replace variable references
  String _processTemplateContent(String content, ExecutionContext context) {
    // Replace {{variable}} patterns with actual values
    return content.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) {
        final variableName = match.group(1)!;
        final value = context.getVariable(variableName);
        return value?.toString() ?? '{{$variableName}}';
      },
    );
  }

  // Send prompt and images to chat system
  void _sendToChat(PromptBuildResult result) {
    try {
      // Get or create GemmaChatController
      GemmaChatController? gemmaController;
      try {
        gemmaController = Get.find<GemmaChatController>();
      } catch (e) {
        // Initialize if not found
        Get.put(GemmaChatController());
        gemmaController = Get.find<GemmaChatController>();
      }
      
      // Clear any existing selected images
      gemmaController.selectedImages.clear();
      
      // Add images from the shortcut execution
      for (final image in result.images) {
        gemmaController.addImage(image);
      }
      
      // Send the message with images
      gemmaController.sendMessage(result.text);
      
      // Navigate back to chat to show the message
      Get.back(); // Close the runtime page
      
    } catch (e) {
      print('Error sending to chat: $e');
      Get.snackbar(
        'Error',
        'Failed to send to chat: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    
    // Get shortcut ID from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final shortcutId = args?['shortcutId'] as String?;
    
    // State management
    final shortcut = useState<ShortcutDefinition?>(null);
    final executionContext = useState<ExecutionContext?>(null);
    final currentScreen = useState<ScreenDefinition?>(null);
    final isLoading = useState(false);
    final generatedPrompt = useState<String?>(null);
    final isLoadingShortcut = useState(false);
    
    // Load shortcut data
    useEffect(() {
      if (shortcutId != null) {
        isLoadingShortcut.value = true;
        
        // Load shortcut from storage
        ShortcutsStorageService.initialize().then((storage) async {
          final loadedShortcut = await storage.getShortcut(shortcutId);
          if (loadedShortcut != null) {
            shortcut.value = loadedShortcut;
            
            // Initialize execution context
            executionContext.value = ExecutionContext(
              shortcutId: loadedShortcut.id,
              currentScreenId: loadedShortcut.startScreenId,
            );
            
            // Load first screen
            currentScreen.value = loadedShortcut.screens.firstWhere(
              (s) => s.id == loadedShortcut.startScreenId,
            );
            
            // Process Text components and set their output variables
            _processTextVariables(loadedShortcut, executionContext.value!);
          }
          isLoadingShortcut.value = false;
        });
      }
      return null;
    }, [shortcutId]);
    
    void handleAction(ScreenAction action) {
      if (action.type == ActionType.submit) {
        // Generate prompt and show result
        isLoading.value = true;
        
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            PromptBuildResult result;
            
            // Check if we have a FinalPromptBuilder component
            final screens = shortcut.value!.screens;
            UIComponent? finalPromptBuilder;
            
            // Find FinalPromptBuilder in screens
            for (final screen in screens) {
              final fpb = screen.components.firstWhereOrNull(
                (c) => c.type == ComponentType.finalPromptBuilder
              );
              if (fpb != null) {
                finalPromptBuilder = fpb;
                break;
              }
            }
            
            if (finalPromptBuilder != null) {
              // Use the new approach - get prompt from FinalPromptBuilder
              final promptTemplate = finalPromptBuilder.properties['promptTemplate'] as String? ?? '';
              result = PromptBuilder.buildPromptWithImages(
                template: promptTemplate,
                context: executionContext.value!,
              );
            } else {
              // Fallback to old approach for backward compatibility
              result = PromptBuilder.buildPromptWithImagesFromDefinition(
                definition: shortcut.value!,
                context: executionContext.value!,
              );
            }
            
            // Send to chat system instead of just displaying
            _sendToChat(result);
            
            generatedPrompt.value = result.text;
            isLoading.value = false;
          } catch (e) {
            // Handle error
            isLoading.value = false;
            Get.snackbar(
              'Error',
              'Failed to generate prompt: ${e.toString()}',
              backgroundColor: themeController.currentThemeConfig.error,
              colorText: themeController.currentThemeConfig.onError,
            );
          }
        });
      } else if (action.type == ActionType.navigate) {
        // Handle navigation to another screen
        final targetScreenId = action.parameters['targetScreenId'] as String?;
        if (targetScreenId != null) {
          final targetScreen = shortcut.value!.screens.firstWhere(
            (s) => s.id == targetScreenId,
            orElse: () => currentScreen.value!,
          );
          
          executionContext.value!.navigateToScreen(targetScreenId);
          currentScreen.value = targetScreen;
        }
      }
    }
    
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
    
    if (shortcut.value == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ERROR'),
        ),
        body: const Center(
          child: Text('No shortcut provided'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(shortcut.value!.name.toUpperCase()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final theme = themeController.currentThemeConfig;
        
        if (isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: theme.primary,
            ),
          );
        }
        
        if (generatedPrompt.value != null) {
          return _ResultView(
            prompt: generatedPrompt.value!,
            onReset: () {
              generatedPrompt.value = null;
              // Reset execution context
              executionContext.value = ExecutionContext(
                shortcutId: shortcut.value!.id,
                currentScreenId: shortcut.value!.startScreenId,
              );
              currentScreen.value = shortcut.value!.screens.firstWhere(
                (s) => s.id == shortcut.value!.startScreenId,
              );
            },
          );
        }
        
        if (currentScreen.value == null) {
          return const Center(
            child: Text('No screen to display'),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentScreen.value!.title,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: theme.onBackground,
                ),
              ),
              const SizedBox(height: 24),
              
              // Render components
              ...currentScreen.value!.components.where((component) {
                // Hide FinalPromptBuilder in runtime
                if (component.type == ComponentType.finalPromptBuilder) {
                  return false;
                }
                // Only show components that pass conditional display
                return ComponentRenderer.shouldDisplay(component, executionContext.value!);
              }).map((component) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ComponentRenderer.render(
                    component: component,
                    context: executionContext.value!,
                    onValueChanged: (variable, value) {
                      executionContext.value!.setVariable(variable, value);
                      // Force UI update
                      executionContext.value = executionContext.value!.clone();
                    },
                    theme: theme,
                  ),
                );
              }),
              
              const SizedBox(height: 32),
              
              // Action buttons
              ...currentScreen.value!.actions.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => handleAction(entry.value),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        entry.value.label.toUpperCase(),
                        style: const TextStyle(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}

class _ResultView extends HookWidget {
  final String prompt;
  final VoidCallback onReset;
  
  const _ResultView({
    required this.prompt,
    required this.onReset,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final aiResponse = useState<String?>(null);
    final isLoadingAI = useState(false);
    final showResponse = useState(false);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GENERATED PROMPT',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: theme.onBackground,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: SelectableText(
              prompt,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: theme.onSurface,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary,
                    side: BorderSide(color: theme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('RUN AGAIN'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoadingAI.value ? null : () async {
                    isLoadingAI.value = true;
                    showResponse.value = true;
                    
                    try {
                      final response = await MockAIService.sendPrompt(prompt);
                      aiResponse.value = response;
                    } catch (e) {
                      aiResponse.value = 'Error: ${e.toString()}';
                    } finally {
                      isLoadingAI.value = false;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoadingAI.value
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.onPrimary),
                          ),
                        )
                      : const Text('SEND TO AI'),
                ),
              ),
            ],
          ),
          
          // AI Response Section
          if (showResponse.value) ...[
            const SizedBox(height: 32),
            Text(
              'AI RESPONSE',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: theme.onBackground,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: isLoadingAI.value
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: theme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Generating response...',
                            style: TextStyle(
                              color: theme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SelectableText(
                      aiResponse.value ?? 'No response yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: theme.onSurface,
                        height: 1.6,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}