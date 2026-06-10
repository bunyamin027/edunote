import 'package:equatable/equatable.dart';

/// Types of files that can be imported into a notebook.
enum FileType {
  pdf,
  image,
  audio,
  unknown,
}

/// Represents an imported file attached to a notebook.
class ImportedFile extends Equatable {
  /// Unique identifier.
  final String id;

  /// Original file name.
  final String fileName;

  /// File path in app's local storage.
  final String localPath;

  /// MIME type of the file.
  final String mimeType;

  /// File size in bytes.
  final int fileSize;

  /// File type category.
  final FileType fileType;

  /// Associated notebook ID.
  final String notebookId;

  /// Number of pages (for PDFs).
  final int? pageCount;

  /// Thumbnail path (generated for PDFs and images).
  final String? thumbnailPath;

  /// Creation timestamp.
  final DateTime createdAt;

  const ImportedFile({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.mimeType,
    required this.fileSize,
    required this.fileType,
    required this.notebookId,
    this.pageCount,
    this.thumbnailPath,
    required this.createdAt,
  });

  /// Human-readable file size.
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// File extension from filename.
  String get extension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  ImportedFile copyWith({
    String? localPath,
    String? thumbnailPath,
    int? pageCount,
  }) {
    return ImportedFile(
      id: id,
      fileName: fileName,
      localPath: localPath ?? this.localPath,
      mimeType: mimeType,
      fileSize: fileSize,
      fileType: fileType,
      notebookId: notebookId,
      pageCount: pageCount ?? this.pageCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'localPath': localPath,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'fileType': fileType.index,
        'notebookId': notebookId,
        'pageCount': pageCount,
        'thumbnailPath': thumbnailPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ImportedFile.fromJson(Map<String, dynamic> json) {
    return ImportedFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      localPath: json['localPath'] as String,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      fileSize: json['fileSize'] as int? ?? 0,
      fileType: FileType.values[json['fileType'] as int? ?? 3],
      notebookId: json['notebookId'] as String,
      pageCount: json['pageCount'] as int?,
      thumbnailPath: json['thumbnailPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id, fileName, localPath, mimeType, fileSize,
        fileType, notebookId, pageCount, thumbnailPath, createdAt,
      ];
}
