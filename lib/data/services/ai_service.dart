import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/config/app_constants.dart';
import '../models/flashcard_model.dart';
import '../models/imported_file_model.dart';

/// Service for interacting with the Google Gemini API.
class AiService {
  late final GenerativeModel _model;
  late final GenerativeModel _jsonModel;

  AiService() {
    _initModels();
  }

  void _initModels() {
    final apiKey = AppConstants.geminiApiKey;
    
    if (apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      debugPrint('WARNING: Gemini API Key is not set. AI features will fail.');
    }

    // Default model for text/chat (fast)
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    // JSON configured model for structured output like flashcards
    _jsonModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Chat with the AI using context.
  Future<String> chat({
    required String prompt,
    required List<Content> history,
  }) async {
    try {
      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(prompt));
      return response.text ?? 'Yanıt alınamadı.';
    } catch (e) {
      debugPrint('AI Chat error: $e');
      throw Exception('AI ile iletişim kurulamadı. Lütfen tekrar deneyin.');
    }
  }

  /// Summarize a text context.
  Future<String> summarizeText(String text) async {
    try {
      final prompt = '''
Lütfen aşağıdaki metni veya ders notunu kapsamlı ama anlaşılır bir şekilde özetle.
Önemli anahtar kelimeleri ve ana fikirleri vurgula.

METİN:
$text
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Özet oluşturulamadı.';
    } catch (e) {
      debugPrint('AI Summarize error: $e');
      throw Exception('Özet oluşturulurken bir hata meydana geldi.');
    }
  }

  /// Summarize an imported image.
  Future<String> summarizeImage(ImportedFile file) async {
    try {
      final imageFile = File(file.localPath);
      final bytes = await imageFile.readAsBytes();
      final prompt = 'Lütfen bu görseldeki notları veya içeriği detaylıca analiz et ve özetle. Önemli maddeleri listele.';
      
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(file.mimeType, bytes),
        ])
      ];

      final response = await _model.generateContent(content);
      return response.text ?? 'Görselden özet çıkarılamadı.';
    } catch (e) {
      debugPrint('AI Image summarize error: $e');
      throw Exception('Görsel analiz edilirken bir hata oluştu.');
    }
  }

  /// Generate flashcards from text.
  Future<List<FlashcardModel>> generateFlashcards(String text) async {
    try {
      final prompt = '''
Aşağıdaki metni analiz et ve bu metinden öğrenmeyi kolaylaştıracak en önemli 5 Soru-Cevap (Flashcard) çıkar.
Yanıtını sadece aşağıdaki JSON formatında bir dizi olarak ver, başka hiçbir metin ekleme:

[
  {
    "question": "Soru metni",
    "answer": "Cevap metni",
    "topic": "İlgili konu başlığı"
  }
]

METİN:
$text
''';
      
      final response = await _jsonModel.generateContent([Content.text(prompt)]);
      final rawText = response.text;
      
      if (rawText == null || rawText.isEmpty) {
        throw Exception('Boş yanıt alındı');
      }

      // Parse JSON
      final List<dynamic> jsonList = jsonDecode(rawText);
      return jsonList.map((e) => FlashcardModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('AI Flashcard generation error: $e');
      throw Exception('Flashcard\'lar oluşturulamadı. Metin çok kısa veya yetersiz olabilir.');
    }
  }
}
