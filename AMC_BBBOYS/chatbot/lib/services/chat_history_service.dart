// lib/services/chat_history_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import 'dart:math';

class ChatHistoryService {
  static const String _chatHistoryKey = 'chat_history_';
  static const String _conversationsKey = 'conversations';
  static const int _maxConversations = 50;

  static String _generateConversationId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  static String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  static Future<Conversation> saveChat(
      String expertId,
      List<ChatMessage> messages,
      {String? conversationId}
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Generate new conversation ID if none provided
      final convId = conversationId ?? _generateConversationId();

      // Ensure all messages have IDs
      final messagesWithIds = messages.map((msg) {
        if (msg.id == null || msg.id!.isEmpty) {
          return msg.copyWith(id: _generateMessageId());
        }
        return msg;
      }).toList();

      // Convert to JSON and save
      final messagesJson = messagesWithIds.map((msg) => msg.toJson()).toList();
      final jsonString = jsonEncode(messagesJson);

      // Save chat messages
      await prefs.setString('${_chatHistoryKey}${expertId}_$convId', jsonString);
      print('✅ Saved chat: ${expertId}_$convId with ${messages.length} messages');

      // Create conversation title from first user message
      String conversationTitle = _generateConversationTitle(messages);

      // Get last message preview
      String lastMessagePreview = _generateLastMessagePreview(messages);

      // Create conversation object
      final conversation = Conversation(
        id: convId,
        expertId: expertId,
        title: conversationTitle,
        lastMessageTime: messages.isNotEmpty ? messages.last.timestamp : DateTime.now(),
        lastMessagePreview: lastMessagePreview,
        messageCount: messages.length,
      );

      // Save conversation to list
      await _saveConversation(conversation);

      return conversation;
    } catch (e) {
      print('❌ Error saving chat: $e');
      rethrow;
    }
  }

  static String _generateConversationTitle(List<ChatMessage> messages) {
    if (messages.isEmpty) return 'Empty Conversation';

    // Try to find first user message for title
    for (final msg in messages) {
      if (msg.isUserMessage && msg.text.trim().isNotEmpty) {
        final text = msg.text.trim();
        return text.length > 30 ? '${text.substring(0, 30)}...' : text;
      }
    }

    // If no user messages, use first AI message
    for (final msg in messages) {
      if (msg.text.trim().isNotEmpty) {
        final text = msg.text.trim();
        return 'AI: ${text.length > 25 ? '${text.substring(0, 25)}...' : text}';
      }
    }

    return 'New Conversation';
  }

  static String _generateLastMessagePreview(List<ChatMessage> messages) {
    if (messages.isEmpty) return 'No messages';

    final lastMessage = messages.last;
    final text = lastMessage.text.trim();

    if (text.isEmpty) return 'Empty message';

    // Add sender indicator
    final sender = lastMessage.isUserMessage ? 'You: ' : 'AI: ';
    final preview = text.length > 45 ? '${text.substring(0, 45)}...' : text;

    return '$sender$preview';
  }

  static Future<List<ChatMessage>> loadChat(String expertId, String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_chatHistoryKey}${expertId}_$conversationId';
      final jsonString = prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        print('⚠️ No chat found for key: $key');
        return [];
      }

      final List<dynamic> messagesJson = jsonDecode(jsonString);

      final messages = messagesJson.map((json) {
        return ChatMessage.fromJson(Map<String, dynamic>.from(json));
      }).toList();

      print('✅ Loaded ${messages.length} messages from $key');
      return messages;
    } catch (e) {
      print('❌ Error loading chat for $expertId/$conversationId: $e');
      return [];
    }
  }

  static Future<void> _saveConversation(Conversation conversation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Conversation> conversations = await getConversations();

      // Remove existing conversation with same ID
      conversations.removeWhere((c) => c.id == conversation.id);

      // Add the updated conversation at the beginning (most recent first)
      conversations.insert(0, conversation);

      // Limit to prevent storage issues
      final limitedConversations = conversations.take(_maxConversations).toList();

      final conversationsJson = limitedConversations.map((c) => c.toJson()).toList();
      await prefs.setString(_conversationsKey, jsonEncode(conversationsJson));

      print('✅ Saved conversation: ${conversation.title}');
    } catch (e) {
      print('❌ Error saving conversation: $e');
      rethrow;
    }
  }

  static Future<List<Conversation>> getConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_conversationsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> conversationsJson = jsonDecode(jsonString);

      final List<Conversation> conversations = conversationsJson.map((json) {
        return Conversation.fromJson(Map<String, dynamic>.from(json));
      }).toList();

      // Sort by lastMessageTime descending (newest first)
      conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return conversations;
    } catch (e) {
      print('❌ Error loading conversations: $e');
      return [];
    }
  }

  static Future<List<Conversation>> getConversationsByExpert(String expertId) async {
    try {
      final allConversations = await getConversations();
      return allConversations.where((c) => c.expertId == expertId).toList();
    } catch (e) {
      print('❌ Error getting conversations by expert $expertId: $e');
      return [];
    }
  }

  static Future<void> deleteConversation(String expertId, String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_chatHistoryKey}${expertId}_$conversationId';

      // Delete the actual chat messages
      final removed = await prefs.remove(key);
      print('${removed ? '✅' : '⚠️'} Removed chat data for key: $key');

      // Remove from conversations list
      final conversations = await getConversations();
      final initialLength = conversations.length;
      conversations.removeWhere((c) => c.id == conversationId);

      if (conversations.length < initialLength) {
        final conversationsJson = conversations.map((c) => c.toJson()).toList();
        await prefs.setString(_conversationsKey, jsonEncode(conversationsJson));
        print('✅ Removed conversation $conversationId from list');
      } else {
        print('⚠️ Conversation $conversationId not found in list');
      }
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      rethrow;
    }
  }

  static Future<void> renameConversation(String conversationId, String newTitle) async {
    try {
      final conversations = await getConversations();
      final index = conversations.indexWhere((c) => c.id == conversationId);

      if (index != -1) {
        final oldConversation = conversations[index];
        final updatedConversation = Conversation(
          id: oldConversation.id,
          expertId: oldConversation.expertId,
          title: newTitle,
          lastMessageTime: oldConversation.lastMessageTime,
          lastMessagePreview: oldConversation.lastMessagePreview,
          messageCount: oldConversation.messageCount,
        );

        conversations[index] = updatedConversation;

        final prefs = await SharedPreferences.getInstance();
        final conversationsJson = conversations.map((c) => c.toJson()).toList();
        await prefs.setString(_conversationsKey, jsonEncode(conversationsJson));

        print('✅ Renamed conversation $conversationId to: $newTitle');
      } else {
        print('⚠️ Conversation $conversationId not found for renaming');
      }
    } catch (e) {
      print('❌ Error renaming conversation: $e');
      rethrow;
    }
  }

  // Update a single message in a conversation
  static Future<bool> updateMessage(
      String expertId,
      String conversationId,
      String messageId,
      String newText,
      bool isEdited,
      ) async {
    try {
      final messages = await loadChat(expertId, conversationId);
      final messageIndex = messages.indexWhere((msg) => msg.id == messageId);

      if (messageIndex != -1) {
        messages[messageIndex] = messages[messageIndex].copyWith(
          text: newText,
          isEdited: isEdited,
          timestamp: DateTime.now(),
        );

        // Save the updated messages
        await saveChat(expertId, messages, conversationId: conversationId);
        print('✅ Updated message $messageId in conversation $conversationId');
        return true;
      } else {
        print('⚠️ Message $messageId not found in conversation $conversationId');
        return false;
      }
    } catch (e) {
      print('❌ Error updating message: $e');
      return false;
    }
  }

  // Delete a single message from a conversation
  static Future<bool> deleteSingleMessage(
      String expertId,
      String conversationId,
      String messageId,
      ) async {
    try {
      final messages = await loadChat(expertId, conversationId);
      final initialLength = messages.length;

      messages.removeWhere((msg) => msg.id == messageId);

      if (messages.length < initialLength) {
        // Save the updated messages
        await saveChat(expertId, messages, conversationId: conversationId);
        print('✅ Deleted message $messageId from conversation $conversationId');
        return true;
      } else {
        print('⚠️ Message $messageId not found in conversation $conversationId');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
      return false;
    }
  }

  // Clear all messages from a conversation (keep the conversation)
  static Future<bool> clearConversation(String expertId, String conversationId) async {
    try {
      // Save an empty list to clear messages but keep conversation
      await saveChat(expertId, [], conversationId: conversationId);
      print('✅ Cleared all messages from conversation $conversationId');
      return true;
    } catch (e) {
      print('❌ Error clearing conversation: $e');
      return false;
    }
  }

  // Get conversation by ID
  static Future<Conversation?> getConversation(String conversationId) async {
    try {
      final conversations = await getConversations();
      return conversations.firstWhere(
              (c) => c.id == conversationId,
          orElse: () {
            print('⚠️ Conversation $conversationId not found');
            return Conversation(
              id: '',
              expertId: '',
              title: '',
              lastMessageTime: DateTime.now(),
              lastMessagePreview: '',
              messageCount: 0,
            );
          }
      );
    } catch (e) {
      print('❌ Error getting conversation: $e');
      return null;
    }
  }

  // Get total message count across all conversations
  static Future<int> getTotalMessageCount() async {
    try {
      final conversations = await getConversations();
      int total = 0;
      for (final conversation in conversations) {
        total += conversation.messageCount;
      }
      return total;
    } catch (e) {
      print('❌ Error getting total message count: $e');
      return 0;
    }
  }

  // Get all messages across all conversations (for search functionality)
  static Future<List<ChatMessage>> getAllMessages() async {
    try {
      final conversations = await getConversations();
      final allMessages = <ChatMessage>[];

      for (final conversation in conversations) {
        final messages = await loadChat(conversation.expertId, conversation.id);
        allMessages.addAll(messages);
      }

      return allMessages;
    } catch (e) {
      print('❌ Error getting all messages: $e');
      return [];
    }
  }

  // Search messages across all conversations
  static Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    try {
      final allMessages = await getAllMessages();
      final results = <Map<String, dynamic>>[];
      final lowercaseQuery = query.toLowerCase();

      for (final message in allMessages) {
        if (message.text.toLowerCase().contains(lowercaseQuery)) {
          // Find which conversation this message belongs to
          final conversations = await getConversations();
          Conversation? foundConversation;

          for (final conversation in conversations) {
            final convMessages = await loadChat(conversation.expertId, conversation.id);
            if (convMessages.any((msg) => msg.id == message.id)) {
              foundConversation = conversation;
              break;
            }
          }

          if (foundConversation != null) {
            results.add({
              'message': message,
              'conversation': foundConversation,
              'excerpt': _getSearchExcerpt(message.text, lowercaseQuery),
            });
          }
        }
      }

      return results;
    } catch (e) {
      print('❌ Error searching messages: $e');
      return [];
    }
  }

  static String _getSearchExcerpt(String text, String query) {
    final index = text.toLowerCase().indexOf(query);
    if (index == -1) return text.length > 60 ? '${text.substring(0, 60)}...' : text;

    final start = max(0, index - 20);
    final end = min(text.length, index + query.length + 40);
    final excerpt = text.substring(start, end);

    return '${start > 0 ? '...' : ''}$excerpt${end < text.length ? '...' : ''}';
  }

  // Export conversation as JSON
  static Future<String> exportConversation(String expertId, String conversationId) async {
    try {
      final messages = await loadChat(expertId, conversationId);
      final conversation = await getConversation(conversationId);

      final exportData = {
        'conversation': conversation?.toJson(),
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'expertId': expertId,
      };

      return jsonEncode(exportData);
    } catch (e) {
      print('❌ Error exporting conversation: $e');
      return '';
    }
  }

  // Import conversation from JSON
  static Future<bool> importConversation(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      final conversationJson = data['conversation'] as Map<String, dynamic>;
      final messagesJson = data['messages'] as List<dynamic>;

      final conversation = Conversation.fromJson(conversationJson);
      final messages = messagesJson.map((json) =>
          ChatMessage.fromJson(Map<String, dynamic>.from(json))
      ).toList();

      // Save the conversation
      await saveChat(conversation.expertId, messages, conversationId: conversation.id);

      print('✅ Imported conversation: ${conversation.title}');
      return true;
    } catch (e) {
      print('❌ Error importing conversation: $e');
      return false;
    }
  }

  // Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = await getConversations();

      int totalMessages = 0;
      int totalSize = 0;

      for (final conversation in conversations) {
        final jsonString = prefs.getString('${_chatHistoryKey}${conversation.expertId}_${conversation.id}');
        if (jsonString != null) {
          totalSize += jsonString.length * 2; // Approximate bytes (UTF-16)
        }
        totalMessages += conversation.messageCount;
      }

      return {
        'totalConversations': conversations.length,
        'totalMessages': totalMessages,
        'estimatedSizeKB': (totalSize / 1024).toStringAsFixed(2),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting storage stats: $e');
      return {
        'totalConversations': 0,
        'totalMessages': 0,
        'estimatedSizeKB': '0.00',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get recent conversations (last N)
  static Future<List<Conversation>> getRecentConversations(int count) async {
    try {
      final conversations = await getConversations();
      return conversations.take(count).toList();
    } catch (e) {
      print('❌ Error getting recent conversations: $e');
      return [];
    }
  }

  // Backup all data
  static Future<String> backupAllData() async {
    try {
      final conversations = await getConversations();
      final List<Map<String, dynamic>> chatsData = [];

      // Add all chat messages
      for (final conversation in conversations) {
        final messages = await loadChat(conversation.expertId, conversation.id);
        chatsData.add({
          'expertId': conversation.expertId,
          'conversationId': conversation.id,
          'messages': messages.map((m) => m.toJson()).toList(),
        });
      }

      final backupData = {
        'conversations': conversations.map((c) => c.toJson()).toList(),
        'chats': chatsData,
        'backupCreated': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
      };

      return jsonEncode(backupData);
    } catch (e) {
      print('❌ Error creating backup: $e');
      return '';
    }
  }

  // Restore from backup
  static Future<bool> restoreFromBackup(String backupJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonDecode(backupJson);

      // Clear existing data
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_chatHistoryKey) || key == _conversationsKey) {
          await prefs.remove(key);
        }
      }

      // Restore conversations
      final conversationsJson = data['conversations'] as List<dynamic>;
      final conversations = conversationsJson.map((json) =>
          Conversation.fromJson(Map<String, dynamic>.from(json))
      ).toList();

      final conversationsJsonString = jsonEncode(conversations.map((c) => c.toJson()).toList());
      await prefs.setString(_conversationsKey, conversationsJsonString);

      // Restore chat messages
      final chats = data['chats'] as List<dynamic>;
      for (final chat in chats) {
        final expertId = chat['expertId'] as String;
        final conversationId = chat['conversationId'] as String;
        final messagesJson = chat['messages'] as List<dynamic>;

        final messages = messagesJson.map((json) =>
            ChatMessage.fromJson(Map<String, dynamic>.from(json))
        ).toList();

        final messagesJsonString = jsonEncode(messages.map((m) => m.toJson()).toList());
        await prefs.setString('${_chatHistoryKey}${expertId}_$conversationId', messagesJsonString);
      }

      print('✅ Restored backup with ${conversations.length} conversations');
      return true;
    } catch (e) {
      print('❌ Error restoring backup: $e');
      return false;
    }
  }

  // Clean up old conversations (keep only recent ones)
  static Future<void> cleanupOldConversations(int keepLastN) async {
    try {
      final conversations = await getConversations();
      if (conversations.length <= keepLastN) return;

      final toRemove = conversations.sublist(keepLastN);
      final prefs = await SharedPreferences.getInstance();

      for (final conversation in toRemove) {
        await prefs.remove('${_chatHistoryKey}${conversation.expertId}_${conversation.id}');
      }

      // Keep only recent conversations
      final recentConversations = conversations.take(keepLastN).toList();
      final conversationsJson = recentConversations.map((c) => c.toJson()).toList();
      await prefs.setString(_conversationsKey, jsonEncode(conversationsJson));

      print('✅ Cleaned up ${toRemove.length} old conversations');
    } catch (e) {
      print('❌ Error cleaning up conversations: $e');
    }
  }
}