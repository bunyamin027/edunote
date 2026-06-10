import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/imported_file_model.dart';
import '../../data/services/file_import_service.dart';
import 'file_event.dart';
import 'file_state.dart';

class FileBloc extends Bloc<FileEvent, FileState> {
  final FileImportService _importService;

  FileBloc(this._importService) : super(FileInitial()) {
    on<LoadFiles>(_onLoadFiles);
    on<ImportPdf>(_onImportPdf);
    on<ImportImage>(_onImportImage);
    on<ImportAudio>(_onImportAudio);
    on<ImportAnyFile>(_onImportAnyFile);
    on<DeleteFile>(_onDeleteFile);
  }

  void _onLoadFiles(LoadFiles event, Emitter<FileState> emit) {
    emit(FileLoading());
    final files = _importService.getFilesForNotebook(event.notebookId);
    emit(FileLoaded(files: files, notebookId: event.notebookId));
  }

  Future<void> _onImportPdf(ImportPdf event, Emitter<FileState> emit) async {
    final currentFiles = _getCurrentFiles();
    emit(FileImporting(existingFiles: currentFiles, notebookId: event.notebookId));

    final picked = await _importService.pickPdf();
    await _processImport(picked, event.notebookId, currentFiles, emit);
  }

  Future<void> _onImportImage(ImportImage event, Emitter<FileState> emit) async {
    final currentFiles = _getCurrentFiles();
    emit(FileImporting(existingFiles: currentFiles, notebookId: event.notebookId));

    final picked = await _importService.pickImage();
    await _processImport(picked, event.notebookId, currentFiles, emit);
  }

  Future<void> _onImportAudio(ImportAudio event, Emitter<FileState> emit) async {
    final currentFiles = _getCurrentFiles();
    emit(FileImporting(existingFiles: currentFiles, notebookId: event.notebookId));

    final picked = await _importService.pickAudio();
    await _processImport(picked, event.notebookId, currentFiles, emit);
  }

  Future<void> _onImportAnyFile(ImportAnyFile event, Emitter<FileState> emit) async {
    final currentFiles = _getCurrentFiles();
    emit(FileImporting(existingFiles: currentFiles, notebookId: event.notebookId));

    final picked = await _importService.pickAnyFile();
    await _processImport(picked, event.notebookId, currentFiles, emit);
  }

  Future<void> _onDeleteFile(DeleteFile event, Emitter<FileState> emit) async {
    await _importService.deleteFile(event.fileId);
    final files = _importService.getFilesForNotebook(event.notebookId);
    emit(FileLoaded(files: files, notebookId: event.notebookId));
  }

  Future<void> _processImport(
    picker.PlatformFile? picked,
    String notebookId,
    List<ImportedFile> currentFiles,
    Emitter<FileState> emit,
  ) async {
    if (picked == null) {
      // User cancelled picker
      emit(FileLoaded(
        files: _importService.getFilesForNotebook(notebookId),
        notebookId: notebookId,
      ));
      return;
    }

    final result = await _importService.importFile(
      pickedFile: picked,
      notebookId: notebookId,
    );

    if (result != null) {
      final updatedFiles = _importService.getFilesForNotebook(notebookId);
      emit(FileImportSuccess(
        importedFile: result,
        allFiles: updatedFiles,
        notebookId: notebookId,
      ));
    } else {
      emit(FileError(
        message: 'Dosya import edilemedi',
        existingFiles: _importService.getFilesForNotebook(notebookId),
        notebookId: notebookId,
      ));
    }
  }

  List<ImportedFile> _getCurrentFiles() {
    final currentState = state;
    if (currentState is FileLoaded) return currentState.files;
    if (currentState is FileImportSuccess) return currentState.allFiles;
    return [];
  }
}
