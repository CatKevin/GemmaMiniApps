import 'package:get/get.dart';
import '../../models/chat/conversation.dart';
import '../../services/chat/conversation_storage_service.dart';
import '../shortcuts_navigation_controller.dart';

/// Controller for managing chat conversations
class ConversationController extends GetxController {
  late ConversationStorageService _storageService;
  
  // Observable states
  final Rx<Conversation?> currentConversation = Rx<Conversation?>(null);
  final RxList<Conversation> conversations = RxList<Conversation>([]);
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 0.obs;
  final RxBool hasMorePages = true.obs;
  
  // Constants
  static const int pageSize = 20;
  
  /// Get singleton instance
  static ConversationController get to => Get.find();
  
  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }
  
  /// Initialize storage service and load conversations
  Future<void> _initializeService() async {
    try {
      isLoading.value = true;
      _storageService = await ConversationStorageService.initialize();
      await loadConversations();
      await loadOrCreateCurrentConversation();
    } catch (e) {
      print('Error initializing conversation controller: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Load all conversations
  Future<void> loadConversations() async {
    try {
      isLoading.value = true;
      final loadedConversations = await _storageService.getAllConversations();
      conversations.value = loadedConversations;
    } catch (e) {
      print('Error loading conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Load paginated conversations
  Future<void> loadConversationsPage({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 0;
      conversations.clear();
      hasMorePages.value = true;
    }
    
    if (!hasMorePages.value) return;
    
    try {
      isLoading.value = true;
      final page = await _storageService.getConversations(
        page: currentPage.value,
        pageSize: pageSize,
      );
      
      if (page.isEmpty) {
        hasMorePages.value = false;
      } else {
        conversations.addAll(page);
        currentPage.value++;
      }
    } catch (e) {
      print('Error loading conversations page: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Load or create current conversation
  Future<void> loadOrCreateCurrentConversation() async {
    try {
      // Try to get active conversation first
      final activeId = await _storageService.getActiveConversationId();
      if (activeId != null) {
        final conversation = await _storageService.getConversation(activeId);
        if (conversation != null) {
          currentConversation.value = conversation;
          return;
        }
      }
      
      // If no active conversation, check if there are any conversations
      final existingConversations = await _storageService.getConversations(page: 0, pageSize: 1);
      if (existingConversations.isNotEmpty) {
        currentConversation.value = existingConversations.first;
        await _storageService.setActiveConversationId(existingConversations.first.id);
      } else {
        // No conversations exist, set to null
        // Let the UI handle the empty state
        currentConversation.value = null;
      }
    } catch (e) {
      print('Error loading current conversation: $e');
      // Don't create a new conversation on error
      currentConversation.value = null;
    }
  }
  
  /// Create a new conversation
  Future<Conversation> createNewConversation() async {
    try {
      // Save current conversation if it exists and has messages
      if (currentConversation.value != null && 
          currentConversation.value!.messages.isNotEmpty) {
        await saveCurrentConversation();
      }
      
      // Reset shortcuts navigation to ensure clean state
      // This prevents showing runtime page when user expects list
      try {
        final shortcutsNavController = Get.find<ShortcutsNavigationController>();
        shortcutsNavController.resetState();
        print('DEBUG: Reset shortcuts state when creating new conversation');
      } catch (e) {
        // Shortcuts controller may not be initialized, which is fine
      }
      
      // Create new conversation with welcome message
      final newConversation = Conversation(isActive: true);
      newConversation.addMessage(Message(
        text: "Welcome to the future of AI interaction. I'm Gemma, your advanced local assistant.",
        isUser: false,
      ));
      
      // Save it
      await _storageService.saveConversation(newConversation);
      await _storageService.setActiveConversationId(newConversation.id);
      
      // Set as current
      currentConversation.value = newConversation;
      
      // Add to list if not already there
      if (!conversations.any((c) => c.id == newConversation.id)) {
        conversations.insert(0, newConversation);
      }
      
      return newConversation;
    } catch (e) {
      print('Error creating new conversation: $e');
      final fallback = Conversation(isActive: true);
      fallback.addMessage(Message(
        text: "Welcome to the future of AI interaction. I'm Gemma, your advanced local assistant.",
        isUser: false,
      ));
      currentConversation.value = fallback;
      conversations.insert(0, fallback);
      return fallback;
    }
  }
  
  /// Switch to a different conversation
  Future<void> switchConversation(Conversation conversation) async {
    try {
      // Save current conversation
      await saveCurrentConversation();
      
      // Load the selected conversation
      final loaded = await _storageService.getConversation(conversation.id);
      if (loaded != null) {
        currentConversation.value = loaded;
        await _storageService.setActiveConversationId(loaded.id);
        
        // Update the conversation in the list
        final index = conversations.indexWhere((c) => c.id == loaded.id);
        if (index >= 0) {
          conversations[index] = loaded;
        }
      }
    } catch (e) {
      print('Error switching conversation: $e');
    }
  }
  
  /// Save current conversation
  Future<void> saveCurrentConversation() async {
    if (currentConversation.value == null) return;
    
    try {
      await _storageService.saveConversation(currentConversation.value!);
      
      // Update in list
      final index = conversations.indexWhere(
        (c) => c.id == currentConversation.value!.id
      );
      if (index >= 0) {
        conversations[index] = currentConversation.value!;
      } else {
        conversations.insert(0, currentConversation.value!);
      }
      
      // Resort list by update time
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      print('Error saving current conversation: $e');
    }
  }
  
  /// Add a message to current conversation
  Future<void> addMessage(String text, bool isUser) async {
    if (currentConversation.value == null) {
      await createNewConversation();
    }
    
    final message = Message(text: text, isUser: isUser);
    currentConversation.value!.addMessage(message);
    
    // Trigger UI update
    currentConversation.refresh();
    
    // Save after adding message
    await saveCurrentConversation();
  }
  
  /// Delete a conversation
  Future<bool> deleteConversation(String id) async {
    try {
      final success = await _storageService.deleteConversation(id);
      
      if (success) {
        // Remove from list
        conversations.removeWhere((c) => c.id == id);
        
        // If deleted conversation was current
        if (currentConversation.value?.id == id) {
          // Check if there are other conversations
          if (conversations.isNotEmpty) {
            // Switch to the first available conversation
            await switchConversation(conversations.first);
          } else {
            // Only create new if no conversations left
            currentConversation.value = null;
            // Don't automatically create a new conversation
            // Let the UI handle empty state
          }
        }
      }
      
      return success;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }
  
  /// Delete all conversations
  Future<bool> deleteAllConversations() async {
    try {
      final success = await _storageService.deleteAllConversations();
      
      if (success) {
        conversations.clear();
        currentConversation.value = null;
        // Don't automatically create a new conversation
        // Let the UI handle empty state
      }
      
      return success;
    } catch (e) {
      print('Error deleting all conversations: $e');
      return false;
    }
  }
  
  /// Search conversations
  Future<void> searchConversations(String query) async {
    searchQuery.value = query;
    
    try {
      isLoading.value = true;
      final results = await _storageService.searchConversations(query);
      conversations.value = results;
    } catch (e) {
      print('Error searching conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Clear search and reload all conversations
  Future<void> clearSearch() async {
    searchQuery.value = '';
    await loadConversations();
  }
  
  /// Get conversation statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await _storageService.getStatistics();
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalConversations': 0,
        'totalMessages': 0,
        'averageMessagesPerConversation': 0,
      };
    }
  }
  
  /// Clear current conversation messages
  void clearCurrentConversation() {
    currentConversation.value?.clearMessages();
    currentConversation.refresh();
  }
  
  /// Check if current conversation has unsaved messages
  bool hasUnsavedMessages() {
    return currentConversation.value != null && 
           currentConversation.value!.messages.isNotEmpty;
  }
  
  @override
  void onClose() {
    // Save current conversation before closing
    saveCurrentConversation();
    super.onClose();
  }
}