import 'package:equatable/equatable.dart';

import 'canvas_painter.dart';

/// Represents a single page in a notebook.
///
/// Each page stores its own strokes, text elements, and template.
class PageModel extends Equatable {
  /// Unique page identifier.
  final String id;

  /// Page number (1-indexed).
  final int pageNumber;

  /// Paper pattern for this page.
  final int paperPatternIndex;

  /// Serialized strokes data.
  final List<Map<String, dynamic>> strokesData;

  /// Serialized text elements data.
  final List<Map<String, dynamic>> textElementsData;

  /// Thumbnail data (base64 encoded PNG, generated on save).
  final String? thumbnailBase64;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last modified timestamp.
  final DateTime updatedAt;

  const PageModel({
    required this.id,
    required this.pageNumber,
    this.paperPatternIndex = 0,
    this.strokesData = const [],
    this.textElementsData = const [],
    this.thumbnailBase64,
    required this.createdAt,
    required this.updatedAt,
  });

  PaperPattern get paperPattern =>
      PaperPattern.values[paperPatternIndex.clamp(0, PaperPattern.values.length - 1)];

  PageModel copyWith({
    int? pageNumber,
    int? paperPatternIndex,
    List<Map<String, dynamic>>? strokesData,
    List<Map<String, dynamic>>? textElementsData,
    String? thumbnailBase64,
    DateTime? updatedAt,
  }) {
    return PageModel(
      id: id,
      pageNumber: pageNumber ?? this.pageNumber,
      paperPatternIndex: paperPatternIndex ?? this.paperPatternIndex,
      strokesData: strokesData ?? this.strokesData,
      textElementsData: textElementsData ?? this.textElementsData,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageNumber': pageNumber,
        'paperPatternIndex': paperPatternIndex,
        'strokesData': strokesData,
        'textElementsData': textElementsData,
        'thumbnailBase64': thumbnailBase64,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      paperPatternIndex: json['paperPatternIndex'] as int? ?? 0,
      strokesData: (json['strokesData'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      textElementsData: (json['textElementsData'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      thumbnailBase64: json['thumbnailBase64'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id, pageNumber, paperPatternIndex, strokesData,
        textElementsData, thumbnailBase64, createdAt, updatedAt,
      ];
}
