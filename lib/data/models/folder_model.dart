import 'package:equatable/equatable.dart';

/// Folder model — represents a folder in the hierarchy.
class FolderModel extends Equatable {
  final String id;
  final String name;
  final String? parentId; // null = root folder
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FolderModel({
    required this.id,
    required this.name,
    this.parentId,
    this.colorIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new folder with defaults.
  factory FolderModel.create({
    required String id,
    required String name,
    String? parentId,
    int colorIndex = 0,
  }) {
    final now = DateTime.now();
    return FolderModel(
      id: id,
      name: name,
      parentId: parentId,
      colorIndex: colorIndex,
      createdAt: now,
      updatedAt: now,
    );
  }

  FolderModel copyWith({
    String? name,
    String? parentId,
    int? colorIndex,
    DateTime? updatedAt,
  }) {
    return FolderModel(
      id: id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'colorIndex': colorIndex,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      colorIndex: json['colorIndex'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, parentId, colorIndex, createdAt, updatedAt];
}
