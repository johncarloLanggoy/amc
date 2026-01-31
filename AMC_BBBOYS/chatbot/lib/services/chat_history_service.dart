import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chat_message.dart';

class ChatHistoryService {
  static const String _chatHistoryKey = 'chat_history_';

  // Save chat messages for a specific expert
  static Future<void> saveChat(String expertId, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert messages to JSON
    final messagesJson = messages.map((msg) => msg.toJson()).toList();

    // Convert to JSON string
    final jsonString = jsonEncode(messagesJson);

    await prefs.setString('$_chatHistoryKey$expertId', jsonString);
  }

  // Load chat messages for a specific expert
  static Future<List<ChatMessage>> loadChat(String expertId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_chatHistoryKey$expertId');

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> messagesJson = jsonDecode(jsonString);

      return messagesJson.map((json) {
        return ChatMessage.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      print('Error loading chat history for $expertId: $e');
      return [];
    }
  }

  // Clear chat history for a specific expert
  static Future<void> clearChat(String expertId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_chatHistoryKey$expertId');
  }

  // Clear all chat histories
  static Future<void> clearAllChats() async {
    final prefs = await SharedPreferences.getInstance();

    // Get all keys that start with our prefix
    final allKeys = prefs.getKeys();
    final chatKeys = allKeys.where((key) => key.startsWith(_chatHistoryKey));

    for (final key in chatKeys) {
      await prefs.remove(key);
    }
  }

  // Get list of all experts with saved chats
  static Future<List<String>> getExpertsWithChats() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    return allKeys
        .where((key) => key.startsWith(_chatHistoryKey))
        .map((key) => key.replaceFirst(_chatHistoryKey, ''))
        .toList();
  }
}