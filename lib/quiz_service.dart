import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ==============================================================================
// QUIZ SERVICE - AI Quiz Generation with GROQ (Llama 3.1)
// ==============================================================================
// Uses Groq API - MUCH FASTER than Gemini!
// Free tier: 14,400 requests/day (way more than enough!)
// ==============================================================================

class QuizService {

  // ==============================================================================
  // YOUR GROQ API KEY
  // ==============================================================================
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // Groq API endpoint
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // ==============================================================================
  // GENERATE QUIZ - Main Method
  // ==============================================================================
  static Future<List<QuizQuestion>> generateQuiz({
    required String text,
    int numberOfQuestions = 10,
  }) async {

    print('🧠 Generating quiz with Groq AI (Llama 3.1)...');
    print('📝 Text length: ${text.length} characters');
    print('❓ Requested questions: $numberOfQuestions');

    try {
      // Create the prompt
      final prompt = _buildQuizPrompt(text, numberOfQuestions);

      print('📤 Sending request to Groq...');

      // Make API request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile',  // Updated model (Dec 2024)
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful teacher creating quiz questions. Always follow the exact format requested.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,  // Balanced creativity
          'max_tokens': 2000,  // Enough for 10 questions
        }),
      );

      print('📬 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Extract generated text
        final generatedText = jsonResponse['choices'][0]['message']['content'];

        print('✅ Response length: ${generatedText.length} characters');

        // Parse into quiz questions
        final questions = _parseQuizResponse(generatedText);

        print('✅ Generated ${questions.length} questions');

        if (questions.isEmpty) {
          throw Exception('No questions were generated');
        }

        return questions;

      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Groq API error: ${errorBody['error']['message']}');
      }

    } catch (e) {
      print('❌ Error generating quiz: $e');
      throw Exception('Failed to generate quiz: $e');
    }
  }

  // ==============================================================================
  // BUILD QUIZ PROMPT
  // ==============================================================================
  static String _buildQuizPrompt(String text, int numberOfQuestions) {
    return '''
Create exactly $numberOfQuestions multiple-choice quiz questions based on this text:

TEXT:
$text

REQUIREMENTS:
1. Create EXACTLY $numberOfQuestions questions
2. Each question must have 4 options (A, B, C, D)
3. Only ONE option is correct
4. Include a brief explanation for the correct answer
5. Questions should test understanding, not memorization

FORMAT (STRICTLY FOLLOW THIS):

QUESTION: [question text here]
A) [first option]
B) [second option]
C) [third option]
D) [fourth option]
CORRECT: [A/B/C/D]
EXPLANATION: [brief explanation]

---

QUESTION: [next question text]
A) [first option]
B) [second option]
C) [third option]
D) [fourth option]
CORRECT: [A/B/C/D]
EXPLANATION: [brief explanation]

---

(Repeat for all $numberOfQuestions questions)

IMPORTANT: Use "---" to separate each question. Do NOT include any other text or formatting.
''';
  }

  // ==============================================================================
  // PARSE QUIZ RESPONSE
  // ==============================================================================
  static List<QuizQuestion> _parseQuizResponse(String response) {
    final questions = <QuizQuestion>[];

    // Split by "---" separator
    final questionBlocks = response.split('---').where((block) => block.trim().isNotEmpty);

    for (final block in questionBlocks) {
      try {
        final lines = block.trim().split('\n').where((line) => line.trim().isNotEmpty).toList();

        String? questionText;
        String? optionA;
        String? optionB;
        String? optionC;
        String? optionD;
        String? correctAnswer;
        String? explanation;

        for (final line in lines) {
          final trimmedLine = line.trim();

          if (trimmedLine.startsWith('QUESTION:')) {
            questionText = trimmedLine.substring('QUESTION:'.length).trim();
          } else if (trimmedLine.startsWith('A)')) {
            optionA = trimmedLine.substring(2).trim();
          } else if (trimmedLine.startsWith('B)')) {
            optionB = trimmedLine.substring(2).trim();
          } else if (trimmedLine.startsWith('C)')) {
            optionC = trimmedLine.substring(2).trim();
          } else if (trimmedLine.startsWith('D)')) {
            optionD = trimmedLine.substring(2).trim();
          } else if (trimmedLine.startsWith('CORRECT:')) {
            correctAnswer = trimmedLine.substring('CORRECT:'.length).trim();
          } else if (trimmedLine.startsWith('EXPLANATION:')) {
            explanation = trimmedLine.substring('EXPLANATION:'.length).trim();
          }
        }

        // Validate all required fields
        if (questionText != null &&
            optionA != null &&
            optionB != null &&
            optionC != null &&
            optionD != null &&
            correctAnswer != null) {

          // Clean up correct answer (remove any extra characters)
          correctAnswer = correctAnswer.toUpperCase();
          if (correctAnswer.length > 1) {
            correctAnswer = correctAnswer[0]; // Take first character only
          }

          questions.add(QuizQuestion(
            question: questionText,
            options: [optionA, optionB, optionC, optionD],
            correctAnswer: correctAnswer,
            explanation: explanation ?? 'No explanation provided.',
          ));
        }
      } catch (e) {
        print('⚠️ Error parsing question block: $e');
        continue;
      }
    }

    return questions;
  }
}

// ==============================================================================
// QUIZ QUESTION MODEL
// ==============================================================================
class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  bool isCorrect(String answer) {
    return answer.toUpperCase() == correctAnswer.toUpperCase();
  }
}

// ==============================================================================
// 🎓 GROQ API - WHY IT'S BETTER:
// ==============================================================================
// 1. ✅ FASTER: 1-3 seconds vs Gemini's 5-10 seconds
// 2. ✅ MORE RELIABLE: Doesn't have Gemini's connection issues
// 3. ✅ BETTER FREE TIER: 14,400 requests/day (vs Gemini's 60/min)
// 4. ✅ WORKS IN PAKISTAN: No regional restrictions
// 5. ✅ SIMPLER API: Just HTTP POST, no complex SDK
//
// Model: Llama 3.1 70B Versatile
// - Very smart (comparable to GPT-4)
// - Great for quiz generation
// - Fast inference
//
// Usage:
// final questions = await QuizService.generateQuiz(
//   text: extractedText,
//   numberOfQuestions: 10,
// );
// ==============================================================================