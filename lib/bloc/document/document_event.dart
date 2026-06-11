import 'package:equatable/equatable.dart';

/// Events for the Document Analysis Bloc.
abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

/// Pick a file from the device and extract its text content.
class PickDocument extends DocumentEvent {}

/// Load an existing file for analysis.
class LoadDocument extends DocumentEvent {
  final String filePath;
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final String? folderId;
  final String? sourceFileId;

  const LoadDocument({
    required this.filePath,
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    this.folderId,
    this.sourceFileId,
  });

  @override
  List<Object?> get props => [filePath, fileName, fileExtension, fileSizeBytes, folderId, sourceFileId];
}

/// Summarize the currently loaded document.
class SummarizeDocument extends DocumentEvent {}

/// Generate exam questions from the currently loaded document.
class GenerateDocumentQuestions extends DocumentEvent {}

/// Generate flashcards from the currently loaded document.
class GenerateDocumentFlashcards extends DocumentEvent {}

/// Ask a question about the currently loaded document.
class ChatAboutDocument extends DocumentEvent {
  final String question;

  const ChatAboutDocument(this.question);

  @override
  List<Object?> get props => [question];
}

/// Clear the current results but keep the document loaded.
class ClearDocumentResults extends DocumentEvent {}

/// Reset everything — go back to initial state.
class ResetDocument extends DocumentEvent {}

/// Save an AI result.
class SaveAiResult extends DocumentEvent {
  final String title;
  final String content;
  final int typeIndex; // from AiResultType enum

  const SaveAiResult({
    required this.title,
    required this.content,
    required this.typeIndex,
  });

  @override
  List<Object?> get props => [title, content, typeIndex];
}
