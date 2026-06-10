import 'package:equatable/equatable.dart';

enum ChatRole { user, model }

/// Represents a message in the AI chat interface.
class ChatMessage extends Equatable {
  final String id;
  final String text;
  final ChatRole role;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.isError = false,
  });

  @override
  List<Object?> get props => [id, text, role, timestamp, isError];
}
