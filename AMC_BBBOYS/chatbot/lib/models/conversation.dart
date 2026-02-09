// lib/models/conversation.dart
import 'dart:convert';

class Conversation {
  final String id;
  final String expertId;
  final String title;
  final DateTime lastMessageTime;
  final String lastMessagePreview;
  final int messageCount;

  Conversation({
    required this.id,
    required this.expertId,
    required this.title,
    required this.lastMessageTime,
    required this.lastMessagePreview,
    required this.messageCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expertId': expertId,
      'title': title,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessagePreview': lastMessagePreview,
      'messageCount': messageCount,
    };
  }

  static Conversation fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      expertId: json['expertId'] ?? '',
      title: json['title'] ?? 'Untitled Conversation',
      lastMessageTime: DateTime.parse(json['lastMessageTime'] ?? DateTime.now().toIso8601String()),
      lastMessagePreview: json['lastMessagePreview'] ?? '',
      messageCount: json['messageCount'] ?? 0,
    );
  }
}