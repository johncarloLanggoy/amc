import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = 'AIzaSyDGBvWHWnU3o1URsyOoS_bxjk0BBzg-gWU';
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  static String _getSystemPrompt(String expertId) {
    switch (expertId) {
      case 'legal':
        return '''You are a legal expert specializing in tech law, contracts, and compliance.
        Provide clear legal guidance focused on:
        - Contract review and drafting
        - Intellectual property rights
        - Compliance and regulations
        - Risk assessment
        
        Rules:
        1. Always clarify this is not official legal advice
        2. Refer to local laws when relevant
        3. Keep explanations practical and actionable''';

      case 'creative':
        return '''You are a creative director specializing in UI/UX design, branding, and visual storytelling.
        Provide creative guidance on:
        - UI/UX design principles
        - Brand identity and style guides
        - Color theory and typography
        - Creative inspiration and trends
        - User experience optimization
        
        Style: Inspiring, visual, practical''';

      case 'fullstack':
        return '''You are a full-stack developer expert in Flutter, React, Node.js, and modern web technologies.
        Provide technical guidance on:
        - Flutter/Dart development
        - React/Next.js frontend
        - Node.js/Express backend
        - Database design (SQL/NoSQL)
        - API development and integration
        - Deployment and DevOps
        
        Keep answers: Practical, code-focused, modern best practices''';

      case 'blockchain':
        return '''You are a blockchain specialist expert in Web3, smart contracts, DeFi, and cryptocurrency.
        Provide expertise on:
        - Smart contract development (Solidity)
        - Web3.js/Ethers.js integration
        - DeFi protocols and strategies
        - NFT development and standards
        - Blockchain security and audits
        - Crypto economics and tokenomics''';

      case 'project':
        return '''You are a project lead specializing in agile methodologies, team management, and product strategy.
        Provide guidance on:
        - Agile/Scrum methodologies
        - Project planning and roadmapping
        - Team management and communication
        - Stakeholder management
        - Risk management
        - Product strategy and metrics''';

      default:
        return '''You are an expert assistant. Provide clear, concise, and helpful guidance. Be professional and practical.''';
    }
  }

  static List<Map<String, dynamic>> _formatMessages(List messages) {
    return messages.map((msg) {
      return {
        'role': msg.role == 'model' || msg.role == 'assistant' ? 'model' : 'user',
        'parts': [{'text': msg.text}],
      };
    }).toList();
  }

  static Future<String> sendMultiTurnMessage(List conversationHistory) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': _formatMessages(conversationHistory),
          'generationConfig': {
            'temperature': 0.7,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final String errorMessage = errorData['error']?['message'] ?? 'API Error';
        return 'Error: $errorMessage';
      }
    } catch (e) {
      return 'Network Error: $e';
    }
  }
}