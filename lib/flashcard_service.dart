import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
class Flashcard {
  final String front; // Question / Term
  final String back;  // Answer / Definition
  final String category;

  Flashcard({
    required this.front,
    required this.back,
    required this.category,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      category: json['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() => {
    'front': front,
    'back': back,
    'category': category,
  };
}

class FlashcardService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Generates flashcards from the given study text using OpenAI
  static Future<List<Flashcard>> generateFlashcards(String text, {int count = 10}) async {
    final prompt = '''
You are an expert study assistant. Analyze the following study notes and generate exactly $count flashcards.

Rules:
- Each flashcard must have a concise FRONT (question or key term, max 15 words)
- Each flashcard must have a clear BACK (answer or definition, max 50 words)
- Assign a CATEGORY (e.g., "Definition", "Concept", "Process", "Key Term", "Fact")
- Focus on the most important, testable concepts
- Do NOT repeat similar questions
- Return ONLY valid JSON array, no extra text

Study Notes:
"""
$text
"""

Return this exact JSON format:
[
  {
    "front": "Question or key term here",
    "back": "Answer or definition here",
    "category": "Category"
  }
]
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a study assistant that generates flashcards. Always respond with valid JSON only.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Clean up any markdown code blocks if present
        String cleanJson = content.trim();
        if (cleanJson.startsWith('```')) {
          cleanJson = cleanJson.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '').trim();
        }

        final List<dynamic> jsonList = jsonDecode(cleanJson);
        return jsonList.map((item) => Flashcard.fromJson(item)).toList();
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate flashcards: $e');
    }
  }
}