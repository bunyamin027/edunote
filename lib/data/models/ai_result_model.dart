import 'package:equatable/equatable.dart';

/// Types of AI-generated results.
enum AiResultType {
  summary,
  questions,
  flashcards,
  chat,
}

/// Represents an AI-generated result saved in a folder.
class AiResultModel extends Equatable {
  /// Unique identifier.
  final String id;

  /// Folder this result belongs to.
  final String folderId;

  /// Source file ID that generated this result (optional).
  final String? sourceFileId;

  /// Source file name for display.
  final String? sourceFileName;

  /// Type of AI result.
  final AiResultType type;

  /// User-facing title (e.g. "Lineer Cebir Özeti").
  final String title;

  /// The AI-generated content.
  final String content;

  /// Creation timestamp.
  final DateTime createdAt;

  const AiResultModel({
    required this.id,
    required this.folderId,
    this.sourceFileId,
    this.sourceFileName,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  /// Human-readable type label.
  String get typeLabel {
    switch (type) {
      case AiResultType.summary:
        return 'Özet';
      case AiResultType.questions:
        return 'Sınav Soruları';
      case AiResultType.flashcards:
        return 'Flashcard';
      case AiResultType.chat:
        return 'Sohbet';
    }
  }

  /// Icon for this result type.
  String get typeEmoji {
    switch (type) {
      case AiResultType.summary:
        return '📝';
      case AiResultType.questions:
        return '❓';
      case AiResultType.flashcards:
        return '🎴';
      case AiResultType.chat:
        return '💬';
    }
  }

  AiResultModel copyWith({
    String? folderId,
    String? title,
    String? content,
  }) {
    return AiResultModel(
      id: id,
      folderId: folderId ?? this.folderId,
      sourceFileId: sourceFileId,
      sourceFileName: sourceFileName,
      type: type,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'folderId': folderId,
        'sourceFileId': sourceFileId,
        'sourceFileName': sourceFileName,
        'type': type.index,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AiResultModel.fromJson(Map<String, dynamic> json) {
    return AiResultModel(
      id: json['id'] as String,
      folderId: json['folderId'] as String,
      sourceFileId: json['sourceFileId'] as String?,
      sourceFileName: json['sourceFileName'] as String?,
      type: AiResultType.values[json['type'] as int? ?? 0],
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id, folderId, sourceFileId, sourceFileName,
        type, title, content, createdAt,
      ];
}
