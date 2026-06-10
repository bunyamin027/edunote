import 'package:equatable/equatable.dart';

/// Paper template types for notebook pages.
enum PaperTemplate {
  blank,
  lined,
  grid,
  dotted,
  isometric,
}

/// Notebook model — represents a user's digital notebook.
class NotebookModel extends Equatable {
  final String id;
  final String name;
  final int coverIndex; // Index into AppColors.coverGradients
  final PaperTemplate template;
  final String? folderId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int pageCount;

  const NotebookModel({
    required this.id,
    required this.name,
    this.coverIndex = 0,
    this.template = PaperTemplate.blank,
    this.folderId,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.pageCount = 1,
  });

  /// Create a new notebook with defaults.
  factory NotebookModel.create({
    required String id,
    required String name,
    int coverIndex = 0,
    PaperTemplate template = PaperTemplate.blank,
    String? folderId,
  }) {
    final now = DateTime.now();
    return NotebookModel(
      id: id,
      name: name,
      coverIndex: coverIndex,
      template: template,
      folderId: folderId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with modifications.
  NotebookModel copyWith({
    String? name,
    int? coverIndex,
    PaperTemplate? template,
    String? folderId,
    List<String>? tags,
    DateTime? updatedAt,
    int? pageCount,
  }) {
    return NotebookModel(
      id: id,
      name: name ?? this.name,
      coverIndex: coverIndex ?? this.coverIndex,
      template: template ?? this.template,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      pageCount: pageCount ?? this.pageCount,
    );
  }

  /// Serialize to JSON map for Hive storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'coverIndex': coverIndex,
        'template': template.index,
        'folderId': folderId,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pageCount': pageCount,
      };

  /// Deserialize from JSON map.
  factory NotebookModel.fromJson(Map<String, dynamic> json) {
    return NotebookModel(
      id: json['id'] as String,
      name: json['name'] as String,
      coverIndex: json['coverIndex'] as int? ?? 0,
      template: PaperTemplate.values[json['template'] as int? ?? 0],
      folderId: json['folderId'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pageCount: json['pageCount'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        coverIndex,
        template,
        folderId,
        tags,
        createdAt,
        updatedAt,
        pageCount,
      ];
}
