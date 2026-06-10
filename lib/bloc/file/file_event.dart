import 'package:equatable/equatable.dart';

abstract class FileEvent extends Equatable {
  const FileEvent();

  @override
  List<Object?> get props => [];
}

/// Load all files for a notebook.
class LoadFiles extends FileEvent {
  final String notebookId;
  const LoadFiles(this.notebookId);

  @override
  List<Object?> get props => [notebookId];
}

/// Import a PDF file.
class ImportPdf extends FileEvent {
  final String notebookId;
  const ImportPdf(this.notebookId);

  @override
  List<Object?> get props => [notebookId];
}

/// Import an image file.
class ImportImage extends FileEvent {
  final String notebookId;
  const ImportImage(this.notebookId);

  @override
  List<Object?> get props => [notebookId];
}

/// Import an audio file.
class ImportAudio extends FileEvent {
  final String notebookId;
  const ImportAudio(this.notebookId);

  @override
  List<Object?> get props => [notebookId];
}

/// Import any supported file.
class ImportAnyFile extends FileEvent {
  final String notebookId;
  const ImportAnyFile(this.notebookId);

  @override
  List<Object?> get props => [notebookId];
}

/// Delete a file.
class DeleteFile extends FileEvent {
  final String fileId;
  final String notebookId;
  const DeleteFile({required this.fileId, required this.notebookId});

  @override
  List<Object?> get props => [fileId, notebookId];
}
