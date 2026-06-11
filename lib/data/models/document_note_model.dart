import 'package:equatable/equatable.dart';

/// Represents a note taken on a specific document (PDF, Image, etc.).
class DocumentNoteModel extends Equatable {
  final String id;
  final String sourceFileId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentNoteModel({
    required this.id,
    required this.sourceFileId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentNoteModel.create({
    required String id,
    required String sourceFileId,
    required String content,
  }) {
    final now = DateTime.now();
    return DocumentNoteModel(
      id: id,
      sourceFileId: sourceFileId,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
  }

  DocumentNoteModel copyWith({
    String? content,
    DateTime? updatedAt,
  }) {
    return DocumentNoteModel(
      id: id,
      sourceFileId: sourceFileId,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceFileId': sourceFileId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DocumentNoteModel.fromJson(Map<String, dynamic> json) {
    return DocumentNoteModel(
      id: json['id'] as String,
      sourceFileId: json['sourceFileId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, sourceFileId, content, createdAt, updatedAt];
}
