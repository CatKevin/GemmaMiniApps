import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import '../../core/theme/controllers/theme_controller.dart';
import '../../models/shortcuts/models.dart';
import '../../services/shortcuts/storage_service.dart';
import '../../services/shortcuts/step_generator.dart';
import '../../services/shortcuts/prompt_builder.dart';
import '../../services/shortcuts/mock_ai_service.dart';
import '../../widgets/shortcuts/runtime/advanced_ui_theme.dart';
import '../../widgets/shortcuts/runtime/transition_effects.dart';
import '../../widgets/shortcuts/runtime/optimized_component_renderer.dart';
import '../../widgets/shortcuts/runtime/step_progress_indicator.dart';

/// Enhanced runtime page with step-based rendering
class EnhancedRuntimePage extends HookWidget {
  const EnhancedRuntimePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    final theme = themeController.currentThemeConfig;
    
    // Get shortcut ID from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final shortcutId = args?['shortcutId'] as String?;
    
    // State management
    final shortcut = useState<ShortcutDefinition?>(null);
    final executionContext = useState<ExecutionContext?>(null);
    final steps = useState<List<RenderStep>>([]);
    final currentStepIndex = useState(0);
    final isLoading = useState(false);
    final isLoadingShortcut = useState(false);
    final generatedPrompt = useState<String?>(null);
    final menuLogicSelectionTrigger = useState(0); // Trigger UI update on selection
    
    // Controllers
    final pageController = usePageController();
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );
    
    // Initialize component variables helper
    void initializeComponentVariables(UIComponent component, ExecutionContext context) {
      // Initialize variable if it has binding AND doesn't already exist
      if (component.variableBinding != null) {
        // Check if variable already exists - if so, don't overwrite it
        if (context.hasVariable(component.variableBinding!)) {
          return; // Variable already exists, skip initialization
        }
        
        dynamic defaultValue;
        switch (component.type) {
          case ComponentType.textInput:
          case ComponentType.multilineTextInput:
            defaultValue = '';
            break;
          case ComponentType.numberInput:
            defaultValue = 0;
            break;
          case ComponentType.toggle:
            defaultValue = false;
            break;
          case ComponentType.multiSelect:
          case ComponentType.tagSelect:
            defaultValue = [];
            break;
          default:
            defaultValue = null;
        }
        context.setVariable(component.variableBinding!, defaultValue);
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
              initializeComponentVariables(childComponent, context);
            }
          }
        }
      }
    }
    
    // Initialize variables for all components
    void initializeVariables(ShortcutDefinition shortcut, ExecutionContext context) {
      for (final screen in shortcut.screens) {
        for (final component in screen.components) {
          initializeComponentVariables(component, context);
        }
      }
    }
    
    // Process template content helper
    String processTemplateContent(String content, ExecutionContext context) {
      return content.replaceAllMapped(
        RegExp(r'\{\{(\w+)\}\}'),
        (match) {
          final variableName = match.group(1)!;
          final value = context.getVariable(variableName);
          return value?.toString() ?? '{{$variableName}}';
        },
      );
    }
    
    // Process component helper
    void processComponent(UIComponent component, ExecutionContext context) {
      // Process Text components with output variables
      if (component.type == ComponentType.text && 
          component.properties['outputVariable'] != null &&
          component.properties['outputVariable'].toString().isNotEmpty) {
        final outputVar = component.properties['outputVariable'].toString();
        final content = component.properties['content'] ?? '';
        
        // Process content to replace variable references
        final processedContent = processTemplateContent(content, context);
        
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
              processComponent(childComponent, context);
            }
          }
        }
      }
    }
    
    // Process Text components to extract variables
    void processTextVariables(ShortcutDefinition shortcut, ExecutionContext context) {
      for (final screen in shortcut.screens) {
        for (final component in screen.components) {
          processComponent(component, context);
        }
      }
    }
    
    // Load shortcut data
    useEffect(() {
      if (shortcutId != null) {
        isLoadingShortcut.value = true;
        
        ShortcutsStorageService.initialize().then((storage) async {
          final loadedShortcut = await storage.getShortcut(shortcutId);
          if (loadedShortcut != null) {
            shortcut.value = loadedShortcut;
            
            // Initialize execution context
            executionContext.value = ExecutionContext(
              shortcutId: loadedShortcut.id,
              currentScreenId: loadedShortcut.startScreenId,
            );
            
            // Initialize all variables
            initializeVariables(loadedShortcut, executionContext.value!);
            
            // Process Text components
            processTextVariables(loadedShortcut, executionContext.value!);
            
            // Generate steps
            steps.value = StepGenerator.generateSteps(loadedShortcut);
            
            // Start animation
            animationController.forward();
          }
          isLoadingShortcut.value = false;
        });
      }
      return null;
    }, [shortcutId]);
    
    // Check if Menu Logic has selection
    bool isMenuLogicSelected() {
      if (currentStepIndex.value >= steps.value.length) return false;
      
      final currentStep = steps.value[currentStepIndex.value];
      if (currentStep.metadata?['compositeType'].toString() != 'CompositeComponentType.switchCase') return false;
      
      // Check if switch component has selected value
      if (currentStep.components.isNotEmpty) {
        final switchComponent = currentStep.components.first;
        final compositeData = switchComponent.properties['compositeData'] as Map<String, dynamic>?;
        
        if (compositeData != null) {
          // Try to get switchVariable from compositeData
          final switchVar = compositeData['switchVariable'] ?? '';
          
          if (switchVar.isNotEmpty) {
            final selectedOption = executionContext.value?.getVariable(switchVar)?.toString();
            
            return selectedOption != null && selectedOption.isNotEmpty;
          }
        }
      }
      
      return false;
    }
    
    // Validate current step
    bool validateCurrentStep() {
      if (currentStepIndex.value >= steps.value.length) return true;
      
      final currentStep = steps.value[currentStepIndex.value];
      
      // Check required fields
      for (final component in currentStep.components) {
        if (component.properties['required'] == true && 
            component.variableBinding != null) {
          final value = executionContext.value?.getVariable(component.variableBinding!);
          if (value == null || 
              (value is String && value.isEmpty) ||
              (value is List && value.isEmpty)) {
            Get.snackbar(
              'Required Field',
              'Please fill in all required fields',
              backgroundColor: theme.error.withValues(alpha: 0.9),
              colorText: theme.onError,
              snackPosition: SnackPosition.TOP,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
            return false;
          }
        }
      }
      
      return true;
    }
    
    // Generate prompt
    void generatePrompt() {
      isLoading.value = true;
      
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          String prompt;
          
          // Check for FinalPromptBuilder
          final screens = shortcut.value!.screens;
          UIComponent? finalPromptBuilder;
          
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
            final promptTemplate = finalPromptBuilder.properties['promptTemplate'] as String? ?? '';
            prompt = PromptBuilder.buildPromptFromTemplate(
              template: promptTemplate,
              context: executionContext.value!,
            );
          } else {
            prompt = PromptBuilder.buildPrompt(
              definition: shortcut.value!,
              context: executionContext.value!,
            );
          }
          
          generatedPrompt.value = prompt;
          isLoading.value = false;
        } catch (e) {
          isLoading.value = false;
          Get.snackbar(
            'Error',
            'Failed to generate prompt: ${e.toString()}',
            backgroundColor: theme.error,
            colorText: theme.onError,
          );
        }
      });
    }
    
    // Navigation functions
    void navigateToNext() {
      if (!validateCurrentStep()) return;
      
      // Check if current step is a switch-case that requires dynamic steps
      final currentStep = steps.value[currentStepIndex.value];
      
      if (currentStep.metadata?['requiresDynamicSteps'] == true) {
        // Get the switch component
        final switchComponent = currentStep.components.first;
        final compositeData = switchComponent.properties['compositeData'] as Map<String, dynamic>?;
        
        if (compositeData != null) {
          final switchVar = compositeData['switchVariable'] ?? '';
          final selectedOption = executionContext.value?.getVariable(switchVar)?.toString();
          
          
          if (selectedOption != null && selectedOption.isNotEmpty) {
            // Generate steps for the selected branch
            final branchSteps = StepGenerator.generateSwitchCaseBranchSteps(
              switchComponent,
              selectedOption,
            );
            
            
            if (branchSteps.isNotEmpty) {
              // Insert the branch steps after the current step
              final newSteps = List<RenderStep>.from(steps.value);
              
              // Remove any previously inserted branch steps from the same switch
              newSteps.removeWhere((step) => 
                step.metadata?['fromSwitchCase'] == true &&
                step.metadata?['parentComponentId'] == switchComponent.id
              );
              
              // Insert new branch steps
              newSteps.insertAll(currentStepIndex.value + 1, branchSteps);
              steps.value = newSteps;
              
              
              // Update page controller to handle new page count
              // Force rebuild of PageView by jumping to current page
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (pageController.hasClients) {
                  pageController.jumpToPage(currentStepIndex.value);
                }
              });
            }
          }
        }
      }
      
      if (currentStepIndex.value < steps.value.length - 1) {
        HapticFeedback.lightImpact();
        currentStepIndex.value++;
        pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
        animationController.forward(from: 0);
      } else {
        // Last step - generate prompt
        generatePrompt();
      }
    }
    
    void navigateToPrevious() {
      if (currentStepIndex.value > 0) {
        HapticFeedback.lightImpact();
        
        // Check if we're navigating back from a switch-case branch
        final currentStep = steps.value[currentStepIndex.value];
        if (currentStep.metadata?['fromSwitchCase'] == true) {
          // Check if the previous step is the switch-case selection
          final prevStep = steps.value[currentStepIndex.value - 1];
          if (prevStep.metadata?['requiresDynamicSteps'] == true) {
            // We're going back to the switch selection, remove all branch steps
            final parentId = currentStep.metadata?['parentComponentId'];
            final newSteps = List<RenderStep>.from(steps.value);
            newSteps.removeWhere((step) => 
              step.metadata?['fromSwitchCase'] == true &&
              step.metadata?['parentComponentId'] == parentId
            );
            steps.value = newSteps;
            
            // Navigate back to Menu Logic step
            currentStepIndex.value = currentStepIndex.value - 1;
            // Use jumpToPage for immediate navigation after removing steps
            pageController.jumpToPage(currentStepIndex.value);
            animationController.forward(from: 0);
            return; // Important: Exit early to avoid double navigation
          }
        }
        
        // Normal navigation for non-branch steps or within branch steps
        currentStepIndex.value--;
        pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
        animationController.forward(from: 0);
      }
    }
    
    // Loading screen
    if (isLoadingShortcut.value) {
      return Scaffold(
        backgroundColor: theme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularStepProgress(
                progress: 0.3,
                size: 80,
                progressColor: theme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading...',
                style: TextStyle(
                  color: theme.onBackground.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Error screen
    if (shortcut.value == null) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: const Text('ERROR'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load shortcut',
                style: TextStyle(
                  color: theme.onBackground,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Result screen
    if (generatedPrompt.value != null) {
      return _ResultView(
        shortcut: shortcut.value!,
        prompt: generatedPrompt.value!,
        executionContext: executionContext.value!,
        onReset: () {
          generatedPrompt.value = null;
          currentStepIndex.value = 0;
          executionContext.value = ExecutionContext(
            shortcutId: shortcut.value!.id,
            currentScreenId: shortcut.value!.startScreenId,
          );
          initializeVariables(shortcut.value!, executionContext.value!);
          processTextVariables(shortcut.value!, executionContext.value!);
          pageController.jumpToPage(0);
        },
      );
    }
    
    // Main runtime screen
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            _buildHeader(
              shortcut: shortcut.value!,
              currentStep: currentStepIndex.value,
              totalSteps: steps.value.length,
              currentStepTitle: steps.value.isNotEmpty 
                  ? steps.value[currentStepIndex.value].title
                  : null,
            ),
            
            // Content
            Expanded(
              child: PageView.builder(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.value.length,
                itemBuilder: (context, index) {
                  return TransitionEffects.slideUpTransition(
                    animation: animationController,
                    child: _buildStepContent(
                      step: steps.value[index],
                      context: executionContext.value!,
                      animationController: animationController,
                      navigateToNext: navigateToNext,
                      menuLogicSelectionTrigger: menuLogicSelectionTrigger,
                    ),
                  );
                },
              ),
            ),
            
            // Navigation - rebuild on menu logic selection
            if (steps.value.isNotEmpty)
              ValueListenableBuilder<int>(
                valueListenable: menuLogicSelectionTrigger,
                builder: (context, triggerValue, __) {
                  final isMenuLogic = steps.value[currentStepIndex.value].metadata?['compositeType'].toString() == 'CompositeComponentType.switchCase';
                  final hasSelection = isMenuLogicSelected();
                  
                  
                  return _buildNavigationBar(
                    currentStep: currentStepIndex.value,
                    totalSteps: steps.value.length,
                    onPrevious: navigateToPrevious,
                    onNext: navigateToNext,
                    isLoading: isLoading.value,
                    theme: theme,
                    isMenuLogicStep: isMenuLogic,
                    hasMenuLogicSelection: hasSelection,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader({
    required ShortcutDefinition shortcut,
    required int currentStep,
    required int totalSteps,
    String? currentStepTitle,
  }) {
    final theme = ThemeController.to.currentThemeConfig;
    
    return Column(
      children: [
        // App bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: theme.onBackground),
                onPressed: () => Get.back(),
              ),
              Expanded(
                child: Text(
                  shortcut.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.onBackground,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance the close button
            ],
          ),
        ),
        
        // Progress indicator
        StepProgressIndicator(
          currentStep: currentStep,
          totalSteps: totalSteps,
          currentStepTitle: currentStepTitle,
          showStepLabels: true,
        ),
      ],
    );
  }
  
  Widget _buildStepContent({
    required RenderStep step,
    required ExecutionContext context,
    required animationController,
    required VoidCallback navigateToNext,
    required ValueNotifier<int> menuLogicSelectionTrigger,
  }) {
    final theme = ThemeController.to.currentThemeConfig;
    // Welcome step
    if (step.type == StepType.welcome) {
      return _buildWelcomeStep(step, theme);
    }
    
    // Confirmation step
    if (step.type == StepType.confirmation) {
      return _buildConfirmationStep(context, theme);
    }
    
    // Check if this is a Menu Logic step
    final isMenuLogicStep = step.metadata?['compositeType'].toString() == 'CompositeComponentType.switchCase';
    
    // Regular step
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title
          if (step.title.isNotEmpty) ...[
            Text(
              step.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.onBackground,
              ),
            ),
            if (step.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                step.subtitle!,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.onBackground.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
          
          // Components
          ...step.components.asMap().entries.map((entry) {
            final index = entry.key;
            final component = entry.value;
            
            // Create unique key based on step ID, component ID, and index
            final componentKey = ValueKey('${step.id}_${component.id}_${index}');
            
            return KeyedSubtree(
              key: componentKey,
              child: TransitionEffects.staggeredAnimation(
                index: index,
                controller: animationController,
                child: OptimizedComponentRenderer.render(
                  component,
                  context,
                  (variable, value) {
                    context.setVariable(variable, value);
                    // Trigger UI update for Menu Logic selection
                    if (isMenuLogicStep) {
                      menuLogicSelectionTrigger.value++;
                      // Force a rebuild of the entire widget
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // This will trigger a rebuild
                        menuLogicSelectionTrigger.value++;
                      });
                    }
                  },
                  theme,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeStep(RenderStep step, theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon animation
            AdvancedUITheme.pulsingAnimation(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primary,
                      theme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: theme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 48),
            
            // Title
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.onBackground,
              ),
            ),
            
            if (step.subtitle != null) ...[
              const SizedBox(height: 16),
              Text(
                step.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: theme.onBackground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfirmationStep(ExecutionContext context, theme) {
    final variables = context.variables.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Information',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please confirm your inputs before generating',
            style: TextStyle(
              fontSize: 16,
              color: theme.onBackground.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          
          // Variable summary cards
          ...variables.map((entry) {
            return AdvancedUITheme.floatingCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatVariableName(entry.key),
                          style: TextStyle(
                            color: theme.onSurface.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatVariableValue(entry.value),
                          style: TextStyle(
                            color: theme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildNavigationBar({
    required int currentStep,
    required int totalSteps,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
    required bool isLoading,
    required theme,
    bool isMenuLogicStep = false,
    bool hasMenuLogicSelection = false,
  }) {
    final isFirstStep = currentStep == 0;
    final isLastStep = currentStep == totalSteps - 1;
    
    // For Menu Logic steps, only show next button if selection is made
    final showNextButton = !isMenuLogicStep || hasMenuLogicSelection;
    
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: theme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back),
                label: const Text('BACK'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.onSurface,
                  side: BorderSide(color: theme.onSurface.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          
          if (!isFirstStep) const SizedBox(width: 16),
          
          // Next/Generate button - only show if allowed
          if (showNextButton)
            Expanded(
              flex: isFirstStep ? 1 : 2,
              child: AdvancedUITheme.gradientButton(
                text: (isLastStep && !isMenuLogicStep) ? 'GENERATE' : 'CONTINUE',
                icon: (isLastStep && !isMenuLogicStep) ? Icons.auto_awesome : Icons.arrow_forward,
                onPressed: onNext,
                isLoading: isLoading,
              ),
            )
          else if (isMenuLogicStep)
            // Show placeholder message for Menu Logic without selection
            Expanded(
              flex: isFirstStep ? 1 : 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.onSurface.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Please select an option to continue',
                    style: TextStyle(
                      color: theme.onSurface.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatVariableName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1)
            : '')
        .join(' ');
  }
  
  String _formatVariableValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    }
    return value.toString();
  }
}

/// Result view widget
class _ResultView extends HookWidget {
  final ShortcutDefinition shortcut;
  final String prompt;
  final ExecutionContext executionContext;
  final VoidCallback onReset;
  
  const _ResultView({
    required this.shortcut,
    required this.prompt,
    required this.executionContext,
    required this.onReset,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to.currentThemeConfig;
    final aiResponse = useState<String?>(null);
    final isLoadingAI = useState(false);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );
    
    useEffect(() {
      animationController.forward();
      return null;
    }, []);
    
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(shortcut.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: TransitionEffects.slideUpTransition(
        animation: animationController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generated Prompt',
                    style: TextStyle(
                      color: theme.onBackground,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Prompt card
              AdvancedUITheme.glassmorphicContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.content_copy,
                          size: 20,
                          color: theme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PROMPT',
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: theme.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: prompt));
                            HapticFeedback.lightImpact();
                            Get.snackbar(
                              'Copied',
                              'Prompt copied to clipboard',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: theme.primary,
                              colorText: theme.onPrimary,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 12,
                              duration: const Duration(seconds: 2),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      prompt,
                      style: TextStyle(
                        color: theme.onSurface,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('RUN AGAIN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primary,
                        side: BorderSide(color: theme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AdvancedUITheme.gradientButton(
                      text: 'SEND TO AI',
                      icon: Icons.send,
                      onPressed: () async {
                        isLoadingAI.value = true;
                        try {
                          final response = await MockAIService.sendPrompt(prompt);
                          aiResponse.value = response;
                        } catch (e) {
                          aiResponse.value = 'Error: ${e.toString()}';
                        } finally {
                          isLoadingAI.value = false;
                        }
                      },
                      isLoading: isLoadingAI.value,
                    ),
                  ),
                ],
              ),
              
              // AI Response
              if (aiResponse.value != null) ...[
                const SizedBox(height: 32),
                TransitionEffects.slideUpTransition(
                  animation: animationController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: theme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'AI Response',
                            style: TextStyle(
                              color: theme.onBackground,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AdvancedUITheme.glassmorphicContainer(
                        padding: const EdgeInsets.all(20),
                        child: SelectableText(
                          aiResponse.value!,
                          style: TextStyle(
                            color: theme.onSurface,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}