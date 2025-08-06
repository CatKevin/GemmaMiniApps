import 'dart:typed_data';
import 'package:get/get.dart';
import '../../services/gemma/gemma_service.dart';
import '../../services/gemma/model_manager_service.dart';
import '../../models/gemma/models.dart';

class GemmaChatController extends GetxController {
  final GemmaService _gemmaService = GemmaService();
  final ModelManagerService _modelManager = ModelManagerService();
  
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
    if (!isModelReady.value || isGenerating.value) return;
    
    // Add user message
    final userMessage = ChatMessage(
      text: text,
      images: List<Uint8List>.from(selectedImages),
      isUser: true,
    );
    messages.add(userMessage);
    
    // Clear selected images
    selectedImages.clear();
    
    // Add placeholder for AI response
    final aiMessage = ChatMessage(
      text: '',
      isUser: false,
    );
    messages.add(aiMessage);
    
    isGenerating.value = true;
    
    try {
      // Generate response stream
      _gemmaService.generateResponse(
        text,
        images: userMessage.images,
      ).listen(
        (response) {
          // Update the last message with accumulated text
          if (messages.isNotEmpty && !messages.last.isUser) {
            messages.last = ChatMessage(
              text: response.text,
              isUser: false,
            );
          }
          
          if (response.isDone) {
            isGenerating.value = false;
          }
        },
        onError: (error) {
          isGenerating.value = false;
          // Update the last message with error
          if (messages.isNotEmpty && !messages.last.isUser) {
            messages.last = ChatMessage(
              text: 'Error: $error',
              isUser: false,
              isError: true,
            );
          }
        },
      );
    } catch (e) {
      isGenerating.value = false;
      // Update the last message with error
      if (messages.isNotEmpty && !messages.last.isUser) {
        messages.last = ChatMessage(
          text: 'Error: $e',
          isUser: false,
          isError: true,
        );
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
    if (selectedImages.length < 5) { // Limit to 5 images
      selectedImages.add(image);
    }
  }
  
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }
  
  void clearImages() {
    selectedImages.clear();
  }
  
  @override
  void onClose() {
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