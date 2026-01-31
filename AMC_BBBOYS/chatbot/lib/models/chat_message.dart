class ChatMessage {
  final String text;
  final String role; // "user" or "model"
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.role,
    required this.timestamp,
  });

  // Helper: Is this a user message?
  bool get isUserMessage => role == "user";

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from JSON
  static ChatMessage fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      role: json['role'] ?? 'user',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}