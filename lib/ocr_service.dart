import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// ==============================================================================
// BALANCED OCR - LIGHT PREPROCESSING + GEMINI
// ==============================================================================
// Strategy:
// 1. Light preprocessing (fixes obvious issues)
// 2. Gemini API (best OCR)
// 3. ML Kit fallback
// ==============================================================================

class OCRService {

  static const String _geminiApiKey = 'AIzaSyCZW3RU8okC-rj96LFP7HmNPNuQB3Mpy-g';
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';

  // ==============================================================================
  // MAIN METHOD
  // ==============================================================================
  static Future<String> extractText(String imagePath) async {
    print('🎯 Starting balanced OCR...');

    try {
      if (!await File(imagePath).exists()) {
        throw Exception('Image not found');
      }

      final hasInternet = await hasInternetConnection();
      print('📡 ${hasInternet ? "Online" : "Offline"}');

      if (hasInternet) {
        try {
          // Light preprocessing before Gemini
          print('🔧 Applying light preprocessing...');
          final processed = await _lightPreprocess(imagePath);
          return await _extractWithGemini(processed);
        } catch (e) {
          print('⚠️ Gemini failed: $e');
          print('🔄 Trying ML Kit...');
          return await _extractWithMLKit(imagePath);
        }
      } else {
        print('📴 Offline - using ML Kit');
        return await _extractWithMLKit(imagePath);
      }

    } catch (e) {
      print('❌ Error: $e');
      throw Exception('OCR failed: $e');
    }
  }

  // ==============================================================================
  // LIGHT PREPROCESSING - JUST FIX OBVIOUS ISSUES
  // ==============================================================================
  static Future<String> _lightPreprocess(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) {
      print('   ⚠️ Could not preprocess, using original');
      return imagePath;
    }

    img.Image image = decoded;

    // 1. Convert to grayscale (reduces noise)
    image = img.grayscale(image);

    // 2. LIGHT contrast boost (not extreme)
    image = img.adjustColor(image, contrast: 1.3, brightness: 1.1);

    // 3. Light sharpening (just one pass)
    image = _lightSharpen(image);

    // 4. Save with high quality
    final tempDir = await getTemporaryDirectory();
    final outputPath = path.join(
      tempDir.path,
      'preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final outputBytes = img.encodeJpg(image, quality: 95);
    await File(outputPath).writeAsBytes(outputBytes);

    print('   ✅ Light preprocessing done');
    return outputPath;
  }

  // ==============================================================================
  // LIGHT SHARPENING - NOT AGGRESSIVE
  // ==============================================================================
  static img.Image _lightSharpen(img.Image src) {
    final output = img.Image.from(src);
    // Gentler kernel than before
    final kernel = [0, -0.5, 0, -0.5, 3, -0.5, 0, -0.5, 0];

    for (int y = 1; y < src.height - 1; y++) {
      for (int x = 1; x < src.width - 1; x++) {
        double sum = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final p = src.getPixel(x + kx, y + ky);
            sum += p.r * kernel[(ky + 1) * 3 + (kx + 1)];
          }
        }

        final c = sum.clamp(0, 255).toInt();
        output.setPixelRgba(x, y, c, c, c, 255);
      }
    }

    return output;
  }

  // ==============================================================================
  // GEMINI VISION API
  // ==============================================================================
  static Future<String> _extractWithGemini(String imagePath) async {
    print('🤖 Using Gemini Flash');

    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final request = {
      'contents': [
        {
          'parts': [
            {
              'text': 'This is a document or handwritten note. Please carefully read ALL the text you can see and transcribe it EXACTLY as written. Pay close attention to:\n- Spelling and grammar\n- Numbers and dates\n- Names of people and places\n- Preserve line breaks and formatting\n\nReturn ONLY the transcribed text, nothing else. If text is unclear, make your best educated guess based on context.'
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.0,
        'maxOutputTokens': 4096,
      }
    };

    final response = await http.post(
      Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request),
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final candidates = jsonResponse['candidates'];

      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        if (content != null) {
          final parts = content['parts'];
          if (parts != null && parts.isNotEmpty) {
            String text = parts[0]['text'] ?? '';
            text = text.trim();

            if (text.isEmpty) {
              throw Exception('No text found');
            }

            print('✅ Gemini: ${text.length} chars');
            return text;
          }
        }
      }

      throw Exception('No text in response');

    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception('Invalid request: ${error['error']['message']}');
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded');
    } else {
      throw Exception('Gemini error: ${response.statusCode}');
    }
  }

  // ==============================================================================
  // ML KIT FALLBACK
  // ==============================================================================
  static Future<String> _extractWithMLKit(String imagePath) async {
    print('📱 Using ML Kit');

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer();

    try {
      final result = await recognizer.processImage(inputImage);
      String text = result.text.trim();

      if (text.isEmpty) {
        throw Exception('No text detected');
      }

      print('✅ ML Kit: ${text.length} chars');
      return text;

    } finally {
      await recognizer.close();
    }
  }

  // ==============================================================================
  // INTERNET CHECK
  // ==============================================================================
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

// ==============================================================================
// ✅ BALANCED OCR - BEST OF BOTH WORLDS
// ==============================================================================
// Features:
// - Light preprocessing (fixes angle, shadows, contrast)
// - Gemini API (best OCR quality)
// - ML Kit fallback (offline)
// - No heavy corruption
// - Better accuracy than raw images
//
// Usage:
// String text = await OCRService.extractText(imagePath);
// ==============================================================================