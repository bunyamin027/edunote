import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/chat_message_model.dart';
import '../../data/services/ai_service.dart';
import 'ai_event.dart';
import 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final AiService _aiService;
  final _uuid = const Uuid();

  // Internal chat history state
  final List<ChatMessage> _messages = [];

  AiBloc(this._aiService) : super(AiInitial()) {
    on<SendChatMessage>(_onSendChatMessage);
    on<SummarizeText>(_onSummarizeText);
    on<SummarizeFile>(_onSummarizeFile);
    on<GenerateFlashcards>(_onGenerateFlashcards);
    on<ClearChat>(_onClearChat);
    
    // Add initial greeting
    _addModelMessage('Merhaba! Ben EduNote AI asistanınızım. Notlarınızı özetleyebilir, sorular çıkarabilir veya dilediğiniz konuda size yardımcı olabilirim.');
  }

  Future<void> _onSendChatMessage(SendChatMessage event, Emitter<AiState> emit) async {
    _addUserMessage(event.message);
    emit(AiProcessing(List.unmodifiable(_messages)));

    try {
      final history = _convertToGeminiHistory();
      final response = await _aiService.chat(
        prompt: event.message,
        history: history,
      );

      _addModelMessage(response);
      emit(AiChatIdle(List.unmodifiable(_messages)));
    } catch (e) {
      _addErrorMessage(e.toString().replaceAll('Exception: ', ''));
      emit(AiError(messages: List.unmodifiable(_messages), errorMessage: e.toString()));
      emit(AiChatIdle(List.unmodifiable(_messages))); // Return to idle
    }
  }

  Future<void> _onSummarizeText(SummarizeText event, Emitter<AiState> emit) async {
    _addUserMessage('Lütfen bu notu özetle.');
    emit(AiProcessing(List.unmodifiable(_messages)));

    try {
      final summary = await _aiService.summarizeText(event.text);
      _addModelMessage('İşte özetiniz:\n\n$summary');
      emit(AiSummaryGenerated(
        messages: List.unmodifiable(_messages),
        summary: summary,
      ));
      emit(AiChatIdle(List.unmodifiable(_messages)));
    } catch (e) {
      _addErrorMessage(e.toString().replaceAll('Exception: ', ''));
      emit(AiError(messages: List.unmodifiable(_messages), errorMessage: e.toString()));
      emit(AiChatIdle(List.unmodifiable(_messages)));
    }
  }

  Future<void> _onSummarizeFile(SummarizeFile event, Emitter<AiState> emit) async {
    _addUserMessage('Lütfen ${event.file.fileName} dosyasını analiz et ve özetle.');
    emit(AiProcessing(List.unmodifiable(_messages)));

    try {
      final summary = await _aiService.summarizeImage(event.file);
      _addModelMessage('Görsel analizi ve özet:\n\n$summary');
      emit(AiSummaryGenerated(
        messages: List.unmodifiable(_messages),
        summary: summary,
      ));
      emit(AiChatIdle(List.unmodifiable(_messages)));
    } catch (e) {
      _addErrorMessage(e.toString().replaceAll('Exception: ', ''));
      emit(AiError(messages: List.unmodifiable(_messages), errorMessage: e.toString()));
      emit(AiChatIdle(List.unmodifiable(_messages)));
    }
  }

  Future<void> _onGenerateFlashcards(GenerateFlashcards event, Emitter<AiState> emit) async {
    _addUserMessage('Bu nottan flashcard (soru-cevap) oluştur.');
    emit(AiProcessing(List.unmodifiable(_messages)));

    try {
      final flashcards = await _aiService.generateFlashcards(event.text);
      _addModelMessage('${flashcards.length} adet flashcard oluşturuldu!');
      
      emit(AiFlashcardsGenerated(
        messages: List.unmodifiable(_messages),
        flashcards: flashcards,
      ));
      emit(AiChatIdle(List.unmodifiable(_messages)));
    } catch (e) {
      _addErrorMessage(e.toString().replaceAll('Exception: ', ''));
      emit(AiError(messages: List.unmodifiable(_messages), errorMessage: e.toString()));
      emit(AiChatIdle(List.unmodifiable(_messages)));
    }
  }

  void _onClearChat(ClearChat event, Emitter<AiState> emit) {
    _messages.clear();
    _addModelMessage('Sohbet geçmişi temizlendi. Size nasıl yardımcı olabilirim?');
    emit(AiChatIdle(List.unmodifiable(_messages)));
  }

  // ─── Helpers ──────────────────────────────────────────

  void _addUserMessage(String text) {
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      text: text,
      role: ChatRole.user,
      timestamp: DateTime.now(),
    ));
  }

  void _addModelMessage(String text) {
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      text: text,
      role: ChatRole.model,
      timestamp: DateTime.now(),
    ));
  }

  void _addErrorMessage(String text) {
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      text: text,
      role: ChatRole.model,
      timestamp: DateTime.now(),
      isError: true,
    ));
  }

  List<Content> _convertToGeminiHistory() {
    // Only pass successful messages to Gemini
    return _messages
        .where((m) => !m.isError)
        .map((m) => m.role == ChatRole.user 
            ? Content.text(m.text)
            : Content.model([TextPart(m.text)]))
        .toList();
  }
}
