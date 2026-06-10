import 'package:equatable/equatable.dart';

import '../../data/models/imported_file_model.dart';

abstract class AiEvent extends Equatable {
  const AiEvent();

  @override
  List<Object?> get props => [];
}

/// Send a message to the AI assistant.
class SendChatMessage extends AiEvent {
  final String message;

  const SendChatMessage(this.message);

  @override
  List<Object?> get props => [message];
}

/// Request a summary of text context.
class SummarizeText extends AiEvent {
  final String text;

  const SummarizeText(this.text);

  @override
  List<Object?> get props => [text];
}

/// Request a summary of an imported file (image).
class SummarizeFile extends AiEvent {
  final ImportedFile file;

  const SummarizeFile(this.file);

  @override
  List<Object?> get props => [file];
}

/// Request flashcards generation from text context.
class GenerateFlashcards extends AiEvent {
  final String text;

  const GenerateFlashcards(this.text);

  @override
  List<Object?> get props => [text];
}

/// Clear chat history.
class ClearChat extends AiEvent {}
