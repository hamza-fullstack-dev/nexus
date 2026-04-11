import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoiceService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _whisperUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String _chatUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // ── Step 1: Transcribe audio using Groq Whisper ──
  static Future<String> transcribeAudio(String filePath) async {
    debugPrint('NEXUS: Starting transcription for file: $filePath');

    final file = File(filePath);
    final exists = await file.exists();
    debugPrint('NEXUS: File exists: $exists');

    if (!exists) throw Exception('Audio file not found at: $filePath');

    final fileSize = await file.length();
    debugPrint('NEXUS: File size: $fileSize bytes');

    if (fileSize < 100) throw Exception('Audio file too small: $fileSize bytes. Recording may have failed.');

    final request = http.MultipartRequest('POST', Uri.parse(_whisperUrl));
    request.headers['Authorization'] = 'Bearer $_apiKey';
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      filePath,
      filename: 'audio.mp4',
      contentType: MediaType('audio', 'mp4'),
    ));
    request.fields['model'] = 'whisper-large-v3';
    request.fields['language'] = 'en';
    request.fields['response_format'] = 'text';

    debugPrint('NEXUS: Sending to Whisper API...');

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Whisper API timed out after 30 seconds'),
    );

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('NEXUS: Whisper status: ${response.statusCode}');
    debugPrint('NEXUS: Whisper response: ${response.body}');

    if (response.statusCode == 200) {
      final transcript = response.body.trim();
      if (transcript.isEmpty) throw Exception('Whisper returned empty transcript');
      return transcript;
    } else {
      throw Exception('Whisper API error ${response.statusCode}: ${response.body}');
    }
  }

  // ── Step 2: Summarize transcript using Groq Llama ──
  static Future<String> summarizeText(String transcript) async {
    debugPrint('NEXUS: Starting summarization...');

    final response = await http.post(
      Uri.parse(_chatUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content':
            'You are a study assistant that summarizes voice notes. '
                'Create a clear, concise summary with key points. '
                'Use bullet points for main ideas. '
                'Keep it focused and useful for studying. '
                'Do not add any preamble - go straight to the summary.',
          },
          {
            'role': 'user',
            'content': 'Summarize this voice note transcript:\n\n$transcript',
          }
        ],
        'temperature': 0.5,
        'max_tokens': 500,
      }),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Groq API timed out after 30 seconds'),
    );

    debugPrint('NEXUS: Groq status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception('Groq API error ${response.statusCode}: ${response.body}');
    }
  }
}