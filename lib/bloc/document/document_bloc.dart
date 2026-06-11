import 'dart:io';

import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/chat_message_model.dart';
import '../../data/models/ai_result_model.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/ai_result_service.dart';
import 'document_event.dart';
import 'document_state.dart';

/// Bloc for document analysis workflow:
/// pick file → extract text → AI operations (summarize, questions, flashcards, chat).
class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final AiService _aiService;
  final AiResultService _aiResultService;
  final _uuid = const Uuid();

  // Internal state for document content
  String? _fileName;
  String? _fileExtension;
  int _fileSizeBytes = 0;
  String _extractedText = '';
  
  // Context state for saving
  String? _folderId;
  String? _sourceFileId;

  // Chat history for document-based conversations
  final List<ChatMessage> _chatMessages = [];

  DocumentBloc(this._aiService, this._aiResultService) : super(DocumentInitial()) {
    on<PickDocument>(_onPickDocument);
    on<LoadDocument>(_onLoadDocument);
    on<SummarizeDocument>(_onSummarize);
    on<GenerateDocumentQuestions>(_onGenerateQuestions);
    on<GenerateDocumentFlashcards>(_onGenerateFlashcards);
    on<ChatAboutDocument>(_onChat);
    on<ClearDocumentResults>(_onClearResults);
    on<ResetDocument>(_onReset);
  }

  // ─── Pick & Extract ───────────────────────────────────

  Future<void> _onPickDocument(PickDocument event, Emitter<DocumentState> emit) async {
    emit(DocumentPicking());

    try {
      final result = await picker.FilePicker.platform.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        emit(DocumentInitial());
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        emit(const DocumentError(message: 'Dosya yolu bulunamadı.'));
        return;
      }

      _fileName = file.name;
      _fileExtension = file.extension?.toLowerCase() ?? '';
      _fileSizeBytes = file.size;
      _chatMessages.clear();
      _folderId = null;
      _sourceFileId = null;

      // Extract text based on file type
      _extractedText = await _extractText(file.path!, _fileExtension!);

      if (_extractedText.trim().isEmpty) {
        emit(const DocumentError(
          message: 'Bu dosyadan metin çıkarılamadı. Lütfen metin içeren bir PDF veya TXT dosyası deneyin.',
        ));
        return;
      }

      emit(DocumentLoaded(
        fileName: _fileName!,
        fileExtension: _fileExtension!,
        fileSizeBytes: _fileSizeBytes,
        extractedText: _extractedText,
      ));
    } catch (e) {
      debugPrint('Document pick error: $e');
      emit(DocumentError(message: 'Dosya seçilirken hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onLoadDocument(LoadDocument event, Emitter<DocumentState> emit) async {
    emit(DocumentPicking());

    try {
      _fileName = event.fileName;
      _fileExtension = event.fileExtension;
      _fileSizeBytes = event.fileSizeBytes;
      _folderId = event.folderId;
      _sourceFileId = event.sourceFileId;
      _chatMessages.clear();

      _extractedText = await _extractText(event.filePath, _fileExtension!);

      if (_extractedText.trim().isEmpty) {
        emit(const DocumentError(
          message: 'Bu dosyadan metin çıkarılamadı.',
        ));
        return;
      }

      emit(DocumentLoaded(
        fileName: _fileName!,
        fileExtension: _fileExtension!,
        fileSizeBytes: _fileSizeBytes,
        extractedText: _extractedText,
      ));
    } catch (e) {
      debugPrint('Document load error: $e');
      emit(DocumentError(message: 'Dosya yüklenirken hata oluştu: ${e.toString()}'));
    }
  }

  Future<String> _extractText(String filePath, String extension) async {
    if (extension == 'pdf') {
      return _extractPdfText(filePath);
    } else if (extension == 'txt') {
      return File(filePath).readAsString();
    } else if (['png', 'jpg', 'jpeg', 'webp'].contains(extension)) {
      // For images, we'll send the image directly to Gemini for analysis
      // Return a placeholder and handle image separately in AI calls
      return '[GÖRSEL_DOSYA:$filePath]';
    }
    return '';
  }

  Future<String> _extractPdfText(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final textExtractor = PdfTextExtractor(document);

      final buffer = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        final pageText = textExtractor.extractText(startPageIndex: i);
        if (pageText.isNotEmpty) {
          buffer.writeln(pageText);
          buffer.writeln(''); // Page separator
        }
      }

      document.dispose();

      final text = buffer.toString().trim();
      // Limit text to avoid token limits (~30,000 chars ≈ ~8K tokens)
      if (text.length > 30000) {
        return '${text.substring(0, 30000)}\n\n[... Metin çok uzun, ilk 30.000 karakter alındı ...]';
      }
      return text;
    } catch (e) {
      debugPrint('PDF text extraction error: $e');
      return '';
    }
  }

  // ─── AI Operations ────────────────────────────────────

  Future<void> _onSummarize(SummarizeDocument event, Emitter<DocumentState> emit) async {
    if (_extractedText.isEmpty || _fileName == null) return;

    emit(DocumentProcessing(
      fileName: _fileName!,
      extractedText: _extractedText,
      operationLabel: 'Özet çıkarılıyor...',
    ));

    try {
      final String summary;

      if (_extractedText.startsWith('[GÖRSEL_DOSYA:')) {
        // Image file — use multimodal
        final imagePath = _extractedText.replaceAll('[GÖRSEL_DOSYA:', '').replaceAll(']', '');
        final bytes = await File(imagePath).readAsBytes();
        final mimeType = _getMimeType(_fileExtension!);

        summary = await _aiService.analyzeDocumentImage(bytes, mimeType);
      } else {
        summary = await _aiService.summarizeDocument(_extractedText);
      }

      emit(DocumentResultReady(
        fileName: _fileName!,
        extractedText: _extractedText,
        resultTitle: '📝 Özet',
        resultContent: summary,
      ));
    } catch (e) {
      emit(DocumentError(
        message: 'Özet oluşturulamadı: ${e.toString().replaceAll('Exception: ', '')}',
        fileName: _fileName,
        extractedText: _extractedText,
      ));
    }
  }

  Future<void> _onGenerateQuestions(GenerateDocumentQuestions event, Emitter<DocumentState> emit) async {
    if (_extractedText.isEmpty || _fileName == null) return;

    emit(DocumentProcessing(
      fileName: _fileName!,
      extractedText: _extractedText,
      operationLabel: 'Sorular üretiliyor...',
    ));

    try {
      final String questions;

      if (_extractedText.startsWith('[GÖRSEL_DOSYA:')) {
        final imagePath = _extractedText.replaceAll('[GÖRSEL_DOSYA:', '').replaceAll(']', '');
        final bytes = await File(imagePath).readAsBytes();
        final mimeType = _getMimeType(_fileExtension!);
        questions = await _aiService.generateQuestionsFromImage(bytes, mimeType);
      } else {
        questions = await _aiService.generateQuestions(_extractedText);
      }

      emit(DocumentResultReady(
        fileName: _fileName!,
        extractedText: _extractedText,
        resultTitle: '❓ Sınav Soruları',
        resultContent: questions,
      ));
    } catch (e) {
      emit(DocumentError(
        message: 'Sorular üretilemedi: ${e.toString().replaceAll('Exception: ', '')}',
        fileName: _fileName,
        extractedText: _extractedText,
      ));
    }
  }

  Future<void> _onGenerateFlashcards(GenerateDocumentFlashcards event, Emitter<DocumentState> emit) async {
    if (_extractedText.isEmpty || _fileName == null) return;

    emit(DocumentProcessing(
      fileName: _fileName!,
      extractedText: _extractedText,
      operationLabel: 'Flashcardlar oluşturuluyor...',
    ));

    try {
      // For images, first extract a summary then generate flashcards from that
      String textForFlashcards = _extractedText;
      if (_extractedText.startsWith('[GÖRSEL_DOSYA:')) {
        final imagePath = _extractedText.replaceAll('[GÖRSEL_DOSYA:', '').replaceAll(']', '');
        final bytes = await File(imagePath).readAsBytes();
        final mimeType = _getMimeType(_fileExtension!);
        textForFlashcards = await _aiService.analyzeDocumentImage(bytes, mimeType);
      }

      final flashcards = await _aiService.generateFlashcards(textForFlashcards);

      emit(DocumentFlashcardsReady(
        fileName: _fileName!,
        extractedText: _extractedText,
        flashcards: flashcards,
      ));
    } catch (e) {
      emit(DocumentError(
        message: 'Flashcardlar oluşturulamadı: ${e.toString().replaceAll('Exception: ', '')}',
        fileName: _fileName,
        extractedText: _extractedText,
      ));
    }
  }

  Future<void> _onChat(ChatAboutDocument event, Emitter<DocumentState> emit) async {
    if (_extractedText.isEmpty || _fileName == null) return;

    // Add user message
    _chatMessages.add(ChatMessage(
      id: _uuid.v4(),
      text: event.question,
      role: ChatRole.user,
      timestamp: DateTime.now(),
    ));

    emit(DocumentChatActive(
      fileName: _fileName!,
      extractedText: _extractedText,
      messages: List.unmodifiable(_chatMessages),
      isProcessing: true,
    ));

    try {
      final history = _chatMessages
          .where((m) => !m.isError)
          .map((m) => m.role == ChatRole.user
              ? Content.text(m.text)
              : Content.model([TextPart(m.text)]))
          .toList();

      final response = await _aiService.chatAboutDocument(
        extractedText: _extractedText,
        question: event.question,
        history: history,
      );

      _chatMessages.add(ChatMessage(
        id: _uuid.v4(),
        text: response,
        role: ChatRole.model,
        timestamp: DateTime.now(),
      ));

      emit(DocumentChatActive(
        fileName: _fileName!,
        extractedText: _extractedText,
        messages: List.unmodifiable(_chatMessages),
        isProcessing: false,
      ));
    } catch (e) {
      _chatMessages.add(ChatMessage(
        id: _uuid.v4(),
        text: 'Hata: ${e.toString().replaceAll('Exception: ', '')}',
        role: ChatRole.model,
        timestamp: DateTime.now(),
        isError: true,
      ));

      emit(DocumentChatActive(
        fileName: _fileName!,
        extractedText: _extractedText,
        messages: List.unmodifiable(_chatMessages),
        isProcessing: false,
      ));
    }
  }

  void _onClearResults(ClearDocumentResults event, Emitter<DocumentState> emit) {
    if (_fileName != null && _extractedText.isNotEmpty) {
      _chatMessages.clear();
      emit(DocumentLoaded(
        fileName: _fileName!,
        fileExtension: _fileExtension!,
        fileSizeBytes: _fileSizeBytes,
        extractedText: _extractedText,
      ));
    }
  }

  void _onReset(ResetDocument event, Emitter<DocumentState> emit) {
    _fileName = null;
    _fileExtension = null;
    _fileSizeBytes = 0;
    _extractedText = '';
    _folderId = null;
    _sourceFileId = null;
    _chatMessages.clear();
    emit(DocumentInitial());
  }

  Future<void> _onSaveAiResult(SaveAiResult event, Emitter<DocumentState> emit) async {
    if (_folderId == null) {
      // Cannot save if we don't have a folder context
      return;
    }

    try {
      final result = AiResultModel(
        id: _uuid.v4(),
        folderId: _folderId!,
        sourceFileId: _sourceFileId,
        sourceFileName: _fileName,
        type: AiResultType.values[event.typeIndex],
        title: event.title,
        content: event.content,
        createdAt: DateTime.now(),
      );

      await _aiResultService.saveResult(result);
    } catch (e) {
      debugPrint('Failed to save AI result: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────

  String _getMimeType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
