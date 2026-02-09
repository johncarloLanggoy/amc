// lib/models/chat_message.dart
import 'dart:convert';

class ChatMessage {
  final String text;
  final String role; // "user" or "model"
  final DateTime timestamp;
  final String? id;
  final bool isEdited;

  ChatMessage({
    required this.text,
    required this.role,
    required this.timestamp,
    this.id,
    this.isEdited = false,
  });

  // Helper: Is this a user message?
  bool get isUserMessage => role == "user";

  // Create a copy with edited changes
  ChatMessage copyWith({
    String? text,
    String? role,
    DateTime? timestamp,
    String? id,
    bool? isEdited,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
      'isEdited': isEdited,
    };
  }

  // Create from JSON
  static ChatMessage fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      role: json['role'] ?? 'user',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      id: json['id'],
      isEdited: json['isEdited'] ?? false,
    );
  }
}