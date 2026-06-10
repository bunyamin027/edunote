import 'package:equatable/equatable.dart';

import '../../data/models/imported_file_model.dart';

abstract class FileState extends Equatable {
  const FileState();

  @override
  List<Object?> get props => [];
}

class FileInitial extends FileState {}

class FileLoading extends FileState {}

class FileLoaded extends FileState {
  final List<ImportedFile> files;
  final String notebookId;

  const FileLoaded({required this.files, required this.notebookId});

  @override
  List<Object?> get props => [files, notebookId];
}

class FileImporting extends FileState {
  final List<ImportedFile> existingFiles;
  final String notebookId;

  const FileImporting({
    required this.existingFiles,
    required this.notebookId,
  });

  @override
  List<Object?> get props => [existingFiles, notebookId];
}

class FileImportSuccess extends FileState {
  final ImportedFile importedFile;
  final List<ImportedFile> allFiles;
  final String notebookId;

  const FileImportSuccess({
    required this.importedFile,
    required this.allFiles,
    required this.notebookId,
  });

  @override
  List<Object?> get props => [importedFile, allFiles, notebookId];
}

class FileError extends FileState {
  final String message;
  final List<ImportedFile> existingFiles;
  final String notebookId;

  const FileError({
    required this.message,
    required this.existingFiles,
    required this.notebookId,
  });

  @override
  List<Object?> get props => [message, existingFiles, notebookId];
}
