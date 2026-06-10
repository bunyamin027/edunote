import 'package:equatable/equatable.dart';

import '../../data/models/chat_message_model.dart';
import '../../data/models/flashcard_model.dart';

abstract class AiState extends Equatable {
  const AiState();

  @override
  List<Object?> get props => [];
}

class AiInitial extends AiState {}

/// State while AI is processing a request (typing...).
class AiProcessing extends AiState {
  final List<ChatMessage> messages;

  const AiProcessing(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// State when AI is idle and displaying chat.
class AiChatIdle extends AiState {
  final List<ChatMessage> messages;

  const AiChatIdle(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// State when flashcards are generated successfully.
class AiFlashcardsGenerated extends AiState {
  final List<ChatMessage> messages;
  final List<FlashcardModel> flashcards;

  const AiFlashcardsGenerated({
    required this.messages,
    required this.flashcards,
  });

  @override
  List<Object?> get props => [messages, flashcards];
}

/// State when a summary is generated successfully.
class AiSummaryGenerated extends AiState {
  final List<ChatMessage> messages;
  final String summary;

  const AiSummaryGenerated({
    required this.messages,
    required this.summary,
  });

  @override
  List<Object?> get props => [messages, summary];
}

class AiError extends AiState {
  final List<ChatMessage> messages;
  final String errorMessage;

  const AiError({required this.messages, required this.errorMessage});

  @override
  List<Object?> get props => [messages, errorMessage];
}
