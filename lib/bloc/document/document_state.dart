import 'package:equatable/equatable.dart';

import '../../data/models/chat_message_model.dart';
import '../../data/models/flashcard_model.dart';

/// States for the Document Analysis Bloc.
abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object?> get props => [];
}

/// No document loaded yet.
class DocumentInitial extends DocumentState {}

/// File picker is open, waiting for selection.
class DocumentPicking extends DocumentState {}

/// Document selected and text extracted — ready for AI operations.
class DocumentLoaded extends DocumentState {
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final String extractedText;

  const DocumentLoaded({
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.extractedText,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [fileName, fileExtension, fileSizeBytes, extractedText];
}

/// AI is processing a request on the document.
class DocumentProcessing extends DocumentState {
  final String fileName;
  final String extractedText;
  final String operationLabel; // e.g. "Özet çıkarılıyor..."

  const DocumentProcessing({
    required this.fileName,
    required this.extractedText,
    required this.operationLabel,
  });

  @override
  List<Object?> get props => [fileName, extractedText, operationLabel];
}

/// AI result ready — summary or questions text.
class DocumentResultReady extends DocumentState {
  final String fileName;
  final String extractedText;
  final String resultTitle;  // e.g. "Özet", "Sınav Soruları"
  final String resultContent;

  const DocumentResultReady({
    required this.fileName,
    required this.extractedText,
    required this.resultTitle,
    required this.resultContent,
  });

  @override
  List<Object?> get props => [fileName, extractedText, resultTitle, resultContent];
}

/// Flashcards generated from document.
class DocumentFlashcardsReady extends DocumentState {
  final String fileName;
  final String extractedText;
  final List<FlashcardModel> flashcards;

  const DocumentFlashcardsReady({
    required this.fileName,
    required this.extractedText,
    required this.flashcards,
  });

  @override
  List<Object?> get props => [fileName, extractedText, flashcards];
}

/// Document chat mode — ongoing conversation about the document.
class DocumentChatActive extends DocumentState {
  final String fileName;
  final String extractedText;
  final List<ChatMessage> messages;
  final bool isProcessing;

  const DocumentChatActive({
    required this.fileName,
    required this.extractedText,
    required this.messages,
    this.isProcessing = false,
  });

  @override
  List<Object?> get props => [fileName, extractedText, messages, isProcessing];
}

/// An error occurred.
class DocumentError extends DocumentState {
  final String message;
  final String? fileName;
  final String? extractedText;

  const DocumentError({
    required this.message,
    this.fileName,
    this.extractedText,
  });

  /// Whether we can still show the document (e.g. AI failed but doc is loaded).
  bool get hasDocument => fileName != null && extractedText != null;

  @override
  List<Object?> get props => [message, fileName, extractedText];
}
