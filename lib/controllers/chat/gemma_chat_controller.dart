import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/gemma/gemma_service.dart';
import '../../services/gemma/model_manager_service.dart';
import '../../models/gemma/models.dart';

class GemmaChatController extends GetxController {
  final GemmaService _gemmaService = GemmaService();
  final ModelManagerService _modelManager = ModelManagerService();
  StreamSubscription<GemmaResponse>? _responseSubscription;
  
  // Observable states
  final isModelReady = false.obs;
  final isGenerating = false.obs;
  final currentModel = Rx<GemmaModel?>(null);
  final messages = <ChatMessage>[].obs;
  final selectedImages = <Uint8List>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeModelManager();
  }
  
  Future<void> _initializeModelManager() async {
    await _modelManager.initialize();
    _modelManager.addListener(_onModelManagerUpdate);
    _checkSelectedModel();
  }
  
  void _onModelManagerUpdate() {
    _checkSelectedModel();
  }
  
  void _checkSelectedModel() {
    final selectedModel = _modelManager.getSelectedModel();
    if (selectedModel != null && selectedModel.id != currentModel.value?.id) {
      currentModel.value = selectedModel;
      isModelReady.value = true;
      
      // Add system message about model being ready
      messages.add(ChatMessage(
        text: 'Model ${selectedModel.name} is ready!',
        isUser: false,
        isSystem: true,
      ));
    } else if (selectedModel == null) {
      currentModel.value = null;
      isModelReady.value = false;
    }
  }
  
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty && selectedImages.isEmpty) return;
    
    // Check if model is available and loaded before proceeding
    final modelManager = ModelManagerService();
    
    // First check if any model is available
    if (!modelManager.hasAnyModelAvailable()) {
      // Show model initialization dialog
      Get.snackbar(
        'Model Not Initialized',
        'Please download or import a model first to use chat features.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            Get.toNamed('/model-management');
          },
          child: const Text('Manage Models'),
        ),
      );
      return;
    }
    
    // Then check if model is loaded/running
    if (!modelManager.isModelLoaded() || !isModelReady.value) {
      // Show model load prompt
      Get.snackbar(
        'Model Not Running',
        'Please select and load a model first to use chat features.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            Get.toNamed('/model-management');
          },
          child: const Text('Select Model', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }
    
    if (isGenerating.value) return;
    
    print('DEBUG: Starting sendMessage with text: "$text" and ${selectedImages.length} images');
    
    // Add user message
    final userMessage = ChatMessage(
      text: text,
      images: List<Uint8List>.from(selectedImages),
      isUser: true,
    );
    messages.add(userMessage);
    print('DEBUG: Added user message with ${userMessage.images?.length ?? 0} images');
    
    // Clear selected images
    selectedImages.clear();
    print('DEBUG: Cleared selected images');
    
    // Add placeholder for AI response
    final aiMessage = ChatMessage(
      text: '',
      isUser: false,
    );
    messages.add(aiMessage);
    final aiMessageIndex = messages.length - 1; // Store index for proper updates
    
    isGenerating.value = true;
    
    try {
      // Cancel any previous subscription
      await _responseSubscription?.cancel();
      
      // Generate response stream
      _responseSubscription = _gemmaService.generateResponse(
        text,
        images: userMessage.images,
      ).listen(
        (response) {
          // Update the AI message using index to ensure reactive updates
          if (aiMessageIndex < messages.length && !messages[aiMessageIndex].isUser) {
            final updatedMessage = ChatMessage(
              text: response.text,
              isUser: false,
            );
            messages[aiMessageIndex] = updatedMessage;
            messages.refresh(); // Explicitly trigger refresh
          }
          
          if (response.isDone) {
            // Don't set isGenerating to false here, wait for onDone
            print('DEBUG: Response marked as done, waiting for stream completion');
          }
        },
        onError: (error) {
          isGenerating.value = false;
          print('DEBUG: AI response error: $error');
          // Update the AI message with error using index
          if (aiMessageIndex < messages.length && !messages[aiMessageIndex].isUser) {
            final errorMessage = ChatMessage(
              text: 'Error: $error',
              isUser: false,
              isError: true,
            );
            messages[aiMessageIndex] = errorMessage;
            messages.refresh(); // Explicitly trigger refresh
          }
        },
        onDone: () {
          // Stream has completed, now stop the loading animation
          isGenerating.value = false;
          print('DEBUG: Stream completed, loading animation stopped');
        },
      );
    } catch (e) {
      isGenerating.value = false;
      print('DEBUG: sendMessage catch error: $e');
      // Update the AI message with error using index
      if (aiMessageIndex < messages.length && !messages[aiMessageIndex].isUser) {
        final errorMessage = ChatMessage(
          text: 'Error: $e',
          isUser: false,
          isError: true,
        );
        messages[aiMessageIndex] = errorMessage;
        messages.refresh(); // Explicitly trigger refresh
      }
    }
  }
  
  Future<void> resetSession() async {
    if (!isModelReady.value) return;
    
    try {
      await _gemmaService.resetSession();
      messages.clear();
      messages.add(ChatMessage(
        text: 'Session reset successfully!',
        isUser: false,
        isSystem: true,
      ));
    } catch (e) {
      messages.add(ChatMessage(
        text: 'Error resetting session: $e',
        isUser: false,
        isError: true,
      ));
    }
  }
  
  void addImage(Uint8List image) {
    print('DEBUG GemmaChatController.addImage: Called with image size ${image.length} bytes');
    print('DEBUG GemmaChatController.addImage: Current selectedImages length: ${selectedImages.length}');
    
    if (selectedImages.length < 5) { // Limit to 5 images
      selectedImages.add(image);
      print('DEBUG GemmaChatController.addImage: Image added successfully. Total images: ${selectedImages.length}');
      
      // Force reactive update
      selectedImages.refresh();
      print('DEBUG GemmaChatController.addImage: Triggered refresh()');
    } else {
      print('DEBUG GemmaChatController.addImage: Cannot add image. Already at limit of 5 images');
    }
  }
  
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      print('DEBUG: Image removed at index $index. Total images: ${selectedImages.length}');
    } else {
      print('DEBUG: Cannot remove image at index $index. Invalid index');
    }
  }
  
  void clearImages() {
    selectedImages.clear();
  }
  
  Future<void> stopGeneration() async {
    if (!isGenerating.value) return;
    
    await _responseSubscription?.cancel();
    _responseSubscription = null;
    await _gemmaService.stopGeneration();
    
    isGenerating.value = false;
    print('DEBUG: Generation stopped by user');
  }
  
  @override
  void onClose() {
    _responseSubscription?.cancel();
    _modelManager.removeListener(_onModelManagerUpdate);
    _gemmaService.cleanup();
    super.onClose();
  }
}

class ChatMessage {
  final String text;
  final List<Uint8List>? images;
  final bool isUser;
  final bool isSystem;
  final bool isError;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    this.images,
    required this.isUser,
    this.isSystem = false,
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  bool get hasText => text.isNotEmpty;
  bool get hasImages => images != null && images!.isNotEmpty;
}