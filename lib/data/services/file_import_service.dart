import 'dart:io';

import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/imported_file_model.dart';

/// Service for importing, storing, and managing files.
///
/// Handles file selection via native picker, copying to app storage,
/// MIME type detection, and Hive-based metadata persistence.
class FileImportService {
  final Box _filesBox;
  final _uuid = const Uuid();

  FileImportService(this._filesBox);

  // ─── File Picking ───────────────────────────────────

  /// Open file picker for PDF files.
  Future<picker.PlatformFile?> pickPdf() async {
    final result = await picker.FilePicker.platform.pickFiles(
      type: picker.FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    return result?.files.firstOrNull;
  }

  /// Open file picker for image files.
  Future<picker.PlatformFile?> pickImage() async {
    final result = await picker.FilePicker.platform.pickFiles(
      type: picker.FileType.image,
      allowMultiple: false,
    );
    return result?.files.firstOrNull;
  }

  /// Open file picker for audio files.
  Future<picker.PlatformFile?> pickAudio() async {
    final result = await picker.FilePicker.platform.pickFiles(
      type: picker.FileType.audio,
      allowMultiple: false,
    );
    return result?.files.firstOrNull;
  }

  /// Open file picker for any supported file type.
  Future<picker.PlatformFile?> pickAnyFile() async {
    final result = await picker.FilePicker.platform.pickFiles(
      type: picker.FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'mp3', 'wav', 'm4a'],
      allowMultiple: false,
    );
    return result?.files.firstOrNull;
  }

  // ─── File Import ────────────────────────────────────

  /// Import a picked file into app storage and save metadata (notebook-based).
  Future<ImportedFile?> importFile({
    required picker.PlatformFile pickedFile,
    required String notebookId,
  }) async {
    try {
      if (pickedFile.path == null) return null;

      // Determine file type from MIME
      final mimeType = lookupMimeType(pickedFile.name) ?? 'application/octet-stream';
      final fileType = _categorizeFile(mimeType);

      // Copy file to app storage
      final appDir = await getApplicationDocumentsDirectory();
      final filesDir = Directory('${appDir.path}/edunote_files/$notebookId');
      if (!await filesDir.exists()) {
        await filesDir.create(recursive: true);
      }

      final fileId = _uuid.v4();
      final extension = pickedFile.extension ?? 'bin';
      final destPath = '${filesDir.path}/$fileId.$extension';

      final sourceFile = File(pickedFile.path!);
      await sourceFile.copy(destPath);

      // Create metadata
      final importedFile = ImportedFile(
        id: fileId,
        fileName: pickedFile.name,
        localPath: destPath,
        mimeType: mimeType,
        fileSize: pickedFile.size,
        fileType: fileType,
        notebookId: notebookId,
        createdAt: DateTime.now(),
      );

      // Save to Hive
      await _saveFileMetadata(importedFile);

      return importedFile;
    } catch (e) {
      debugPrint('File import error: $e');
      return null;
    }
  }

  /// Import a picked file into a folder.
  Future<ImportedFile?> importFileToFolder({
    required picker.PlatformFile pickedFile,
    required String folderId,
  }) async {
    try {
      if (pickedFile.path == null) return null;

      final mimeType = lookupMimeType(pickedFile.name) ?? 'application/octet-stream';
      final fileType = _categorizeFile(mimeType);

      // Copy file to folder-specific app storage
      final appDir = await getApplicationDocumentsDirectory();
      final filesDir = Directory('${appDir.path}/edunote_folders/$folderId');
      if (!await filesDir.exists()) {
        await filesDir.create(recursive: true);
      }

      final fileId = _uuid.v4();
      final extension = pickedFile.extension ?? 'bin';
      final destPath = '${filesDir.path}/$fileId.$extension';

      final sourceFile = File(pickedFile.path!);
      await sourceFile.copy(destPath);

      final importedFile = ImportedFile(
        id: fileId,
        fileName: pickedFile.name,
        localPath: destPath,
        mimeType: mimeType,
        fileSize: pickedFile.size,
        fileType: fileType,
        folderId: folderId,
        createdAt: DateTime.now(),
      );

      await _saveFileMetadata(importedFile);
      return importedFile;
    } catch (e) {
      debugPrint('File import to folder error: $e');
      return null;
    }
  }

  // ─── File Queries ───────────────────────────────────

  /// Get all imported files for a notebook.
  List<ImportedFile> getFilesForNotebook(String notebookId) {
    final allData = _filesBox.values.toList();
    return allData
        .whereType<Map>()
        .map((data) => ImportedFile.fromJson(Map<String, dynamic>.from(data)))
        .where((f) => f.notebookId == notebookId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all imported files for a folder.
  List<ImportedFile> getFilesForFolder(String folderId) {
    final allData = _filesBox.values.toList();
    return allData
        .whereType<Map>()
        .map((data) => ImportedFile.fromJson(Map<String, dynamic>.from(data)))
        .where((f) => f.folderId == folderId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all imported files (across all folders/notebooks).
  List<ImportedFile> getAllFiles() {
    final allData = _filesBox.values.toList();
    return allData
        .whereType<Map>()
        .map((data) => ImportedFile.fromJson(Map<String, dynamic>.from(data)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a single file by ID.
  ImportedFile? getFileById(String fileId) {
    final data = _filesBox.get(fileId);
    if (data == null) return null;
    return ImportedFile.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ─── File Deletion ──────────────────────────────────

  /// Delete a file from storage and metadata.
  Future<void> deleteFile(String fileId) async {
    final file = getFileById(fileId);
    if (file == null) return;

    // Delete physical file
    try {
      final physicalFile = File(file.localPath);
      if (await physicalFile.exists()) {
        await physicalFile.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }

    // Delete metadata
    await _filesBox.delete(fileId);
  }

  /// Delete all files for a notebook.
  Future<void> deleteFilesForNotebook(String notebookId) async {
    final files = getFilesForNotebook(notebookId);
    for (final file in files) {
      await deleteFile(file.id);
    }
  }

  /// Delete all files for a folder.
  Future<void> deleteFilesForFolder(String folderId) async {
    final files = getFilesForFolder(folderId);
    for (final file in files) {
      await deleteFile(file.id);
    }
  }

  // ─── Helpers ────────────────────────────────────────

  Future<void> _saveFileMetadata(ImportedFile file) async {
    await _filesBox.put(file.id, file.toJson());
  }

  FileType _categorizeFile(String mimeType) {
    if (mimeType.startsWith('application/pdf')) return FileType.pdf;
    if (mimeType.startsWith('image/')) return FileType.image;
    if (mimeType.startsWith('audio/')) return FileType.audio;
    return FileType.unknown;
  }
}
