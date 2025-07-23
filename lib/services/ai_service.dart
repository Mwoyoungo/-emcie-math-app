import 'dart:convert';
import 'package:http/http.dart' as http;

class AIResponse {
  final String text;
  final String question;
  final String chatId;
  final String chatMessageId;
  final String executionId;
  final String sessionId;

  AIResponse({
    required this.text,
    required this.question,
    required this.chatId,
    required this.chatMessageId,
    required this.executionId,
    required this.sessionId,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      text: json['text'] ?? '',
      question: json['question'] ?? '',
      chatId: json['chatId'] ?? '',
      chatMessageId: json['chatMessageId'] ?? '',
      executionId: json['executionId'] ?? '',
      sessionId: json['sessionId'] ?? '',
    );
  }
}

class AIService {
  static const String _baseUrl = 'https://cloud.flowiseai.com/api/v1/prediction/e07906e0-cbb2-47a9-afc9-cebc4a830321';
  
  static Future<AIResponse> getAssessmentResponse(String message, {String? chatId}) async {
    try {
      final requestBody = <String, dynamic>{
        'question': message,
      };
      
      // Include chatId if provided for session continuity
      if (chatId != null && chatId.isNotEmpty) {
        requestBody['chatId'] = chatId;
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map<String, dynamic>) {
          return AIResponse.fromJson(data);
        } else if (data is String) {
          // Fallback for simple string responses
          return AIResponse(
            text: data,
            question: message,
            chatId: chatId ?? _generateFallbackChatId(),
            chatMessageId: _generateRandomId(),
            executionId: _generateRandomId(),
            sessionId: chatId ?? _generateFallbackChatId(),
          );
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      // AI Service Error: $e
      // Return fallback response with generated IDs
      return AIResponse(
        text: _getFallbackResponse(message),
        question: message,
        chatId: chatId ?? _generateFallbackChatId(),
        chatMessageId: _generateRandomId(),
        executionId: _generateRandomId(),
        sessionId: chatId ?? _generateFallbackChatId(),
      );
    }
  }

  static String _generateFallbackChatId() {
    return 'fallback_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  static String _generateRandomId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(12)}';
  }

  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[DateTime.now().millisecond % chars.length]).join();
  }

  static String _getFallbackResponse(String message) {
    // Provide a fallback response if API fails
    if (message.toLowerCase().contains('assessment') || message.toLowerCase().contains('assess')) {
      return '''Hello! I'm Mam Rose, your AI math tutor! 🌟 

I'm excited to help you with your mathematics assessment. I'll be asking you questions tailored to your grade level and the topic you've selected.

Here's how our assessment will work:
- I'll ask you questions one at a time
- Take your time to think and provide your best answer
- I'll give you feedback on each response
- Don't worry about making mistakes - that's how we learn!

Are you ready to begin? Let me start with your first question! 📚✨''';
    }
    
    return "I'm here to help you with your math assessment! Let's get started with some questions.";
  }

  static String createInitialAssessmentMessage({
    required String studentName,
    required String grade,
    required String subject,
  }) {
    return '''Hi, I'm $studentName, a $grade student. I want to be assessed on $subject. Please start my personalized math assessment with questions appropriate for my grade level. Focus on testing my understanding of key $subject concepts and provide detailed feedback on my responses.''';
  }
}