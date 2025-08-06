/// Message model for chat conversations
class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    text: json['text'] as String,
    isUser: json['isUser'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Conversation model for managing chat sessions
class Conversation {
  final String id;
  String title;
  final List<Message> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isActive;

  Conversation({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       title = title ?? 'New Conversation',
       messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Generate title from first message (max 30 characters)
  void generateTitle() {
    if (messages.isNotEmpty) {
      final firstUserMessage = messages.firstWhere(
        (msg) => msg.isUser,
        orElse: () => messages.first,
      );
      
      String text = firstUserMessage.text;
      // Remove excessive whitespace and newlines
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      // Limit to 30 characters
      if (text.length > 30) {
        text = '${text.substring(0, 27)}...';
      }
      
      title = text.isEmpty ? 'New Conversation' : text;
    }
  }

  /// Add a message to the conversation
  void addMessage(Message message) {
    messages.add(message);
    updatedAt = DateTime.now();
    
    // Auto-generate title from first user message
    if (messages.length == 1 && message.isUser) {
      generateTitle();
    }
  }

  /// Clear all messages
  void clearMessages() {
    messages.clear();
    title = 'New Conversation';
    updatedAt = DateTime.now();
  }

  /// Get formatted time string for display
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
  };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    title: json['title'] as String,
    messages: (json['messages'] as List)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isActive: json['isActive'] as bool? ?? false,
  );

  /// Create a copy with updated fields
  Conversation copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? List.from(this.messages),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}