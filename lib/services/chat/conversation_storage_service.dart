import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat/conversation.dart';

/// Service for persisting conversation data locally
class ConversationStorageService {
  static const String _conversationsKey = 'chat_conversations';
  static const String _activeConversationKey = 'active_conversation_id';
  static const int _pageSize = 20;
  
  final SharedPreferences _prefs;
  
  ConversationStorageService(this._prefs);
  
  /// Initialize the storage service
  static Future<ConversationStorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return ConversationStorageService(prefs);
  }
  
  /// Save a conversation
  Future<bool> saveConversation(Conversation conversation) async {
    try {
      final conversations = await getAllConversations();
      final index = conversations.indexWhere((c) => c.id == conversation.id);
      
      if (index >= 0) {
        conversations[index] = conversation;
      } else {
        conversations.add(conversation);
      }
      
      return await _saveAllConversations(conversations);
    } catch (e) {
      print('Error saving conversation: $e');
      return false;
    }
  }
  
  /// Update an existing conversation
  Future<bool> updateConversation(Conversation conversation) async {
    return saveConversation(conversation);
  }
  
  /// Get all conversations
  Future<List<Conversation>> getAllConversations() async {
    try {
      final jsonString = _prefs.getString(_conversationsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      final conversations = jsonList
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Sort by updatedAt (most recent first)
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return conversations;
    } catch (e) {
      print('Error loading conversations: $e');
      return [];
    }
  }
  
  /// Get paginated conversations
  Future<List<Conversation>> getConversations({
    int page = 0,
    int pageSize = _pageSize,
  }) async {
    final allConversations = await getAllConversations();
    
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, allConversations.length);
    
    if (startIndex >= allConversations.length) {
      return [];
    }
    
    return allConversations.sublist(startIndex, endIndex);
  }
  
  /// Get conversation by ID
  Future<Conversation?> getConversation(String id) async {
    final conversations = await getAllConversations();
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Delete a conversation
  Future<bool> deleteConversation(String id) async {
    try {
      final conversations = await getAllConversations();
      conversations.removeWhere((c) => c.id == id);
      
      // If deleted conversation was active, clear active ID
      final activeId = await getActiveConversationId();
      if (activeId == id) {
        await clearActiveConversationId();
      }
      
      return await _saveAllConversations(conversations);
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }
  
  /// Delete all conversations
  Future<bool> deleteAllConversations() async {
    try {
      await _prefs.remove(_conversationsKey);
      await _prefs.remove(_activeConversationKey);
      return true;
    } catch (e) {
      print('Error deleting all conversations: $e');
      return false;
    }
  }
  
  /// Search conversations by content
  Future<List<Conversation>> searchConversations(String query) async {
    if (query.isEmpty) {
      return getAllConversations();
    }
    
    final conversations = await getAllConversations();
    final lowerQuery = query.toLowerCase();
    
    return conversations.where((conversation) {
      // Search in title
      if (conversation.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Search in messages
      return conversation.messages.any((message) => 
        message.text.toLowerCase().contains(lowerQuery)
      );
    }).toList();
  }
  
  /// Get active conversation ID
  Future<String?> getActiveConversationId() async {
    return _prefs.getString(_activeConversationKey);
  }
  
  /// Set active conversation ID
  Future<bool> setActiveConversationId(String id) async {
    try {
      // Clear previous active status
      final conversations = await getAllConversations();
      for (final conversation in conversations) {
        conversation.isActive = conversation.id == id;
      }
      await _saveAllConversations(conversations);
      
      // Save active ID
      return await _prefs.setString(_activeConversationKey, id);
    } catch (e) {
      print('Error setting active conversation: $e');
      return false;
    }
  }
  
  /// Clear active conversation ID
  Future<bool> clearActiveConversationId() async {
    try {
      // Clear all active status
      final conversations = await getAllConversations();
      for (final conversation in conversations) {
        conversation.isActive = false;
      }
      await _saveAllConversations(conversations);
      
      // Remove active ID
      return await _prefs.remove(_activeConversationKey);
    } catch (e) {
      print('Error clearing active conversation: $e');
      return false;
    }
  }
  
  /// Get or create default conversation
  Future<Conversation> getOrCreateDefaultConversation() async {
    // Try to get active conversation
    final activeId = await getActiveConversationId();
    if (activeId != null) {
      final conversation = await getConversation(activeId);
      if (conversation != null) {
        return conversation;
      }
    }
    
    // Try to get most recent conversation
    final conversations = await getAllConversations();
    if (conversations.isNotEmpty) {
      final recent = conversations.first;
      await setActiveConversationId(recent.id);
      return recent;
    }
    
    // Create new conversation
    final newConversation = Conversation(isActive: true);
    await saveConversation(newConversation);
    await setActiveConversationId(newConversation.id);
    return newConversation;
  }
  
  /// Get conversation statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final conversations = await getAllConversations();
    
    int totalMessages = 0;
    for (final conversation in conversations) {
      totalMessages += conversation.messages.length;
    }
    
    return {
      'totalConversations': conversations.length,
      'totalMessages': totalMessages,
      'averageMessagesPerConversation': 
          conversations.isEmpty ? 0 : totalMessages ~/ conversations.length,
    };
  }
  
  /// Private helper to save all conversations
  Future<bool> _saveAllConversations(List<Conversation> conversations) async {
    try {
      final jsonList = conversations.map((c) => c.toJson()).toList();
      final jsonString = json.encode(jsonList);
      return await _prefs.setString(_conversationsKey, jsonString);
    } catch (e) {
      print('Error saving conversations: $e');
      return false;
    }
  }
}