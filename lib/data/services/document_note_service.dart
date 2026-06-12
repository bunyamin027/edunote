import 'package:hive_flutter/hive_flutter.dart';

import '../models/document_note_model.dart';

/// Service for managing document notes and annotations using Hive.
class DocumentNoteService {
  final Box _notesBox;

  DocumentNoteService(this._notesBox);

  // ─── Text Notes ────────────────────────────────────

  /// Get all notes for a specific document.
  List<DocumentNoteModel> getNotesForFile(String sourceFileId) {
    final results = _notesBox.values.map((map) {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      final jsonMap = map.map((key, value) => MapEntry(key.toString(), value));
      return DocumentNoteModel.fromJson(jsonMap);
    }).toList();

    return results.where((note) => note.sourceFileId == sourceFileId).toList();
  }

  /// Save or update a note.
  Future<void> saveNote(DocumentNoteModel note) async {
    await _notesBox.put(note.id, note.toJson());
  }

  /// Delete a specific note.
  Future<void> deleteNote(String noteId) async {
    await _notesBox.delete(noteId);
  }

  /// Delete all notes for a specific document (e.g., when the document is deleted).
  Future<void> deleteNotesForFile(String sourceFileId) async {
    final notes = getNotesForFile(sourceFileId);
    for (var note in notes) {
      await deleteNote(note.id);
    }
  }

  /// Clear all document notes (e.g., user logout or full reset).
  Future<void> clearAll() async {
    await _notesBox.clear();
  }

  // ─── Annotations (Drawing Strokes) ─────────────────

  /// Key for storing annotations per file+page.
  String _annotationKey(String fileId, int page) => 'annot_${fileId}_p$page';

  /// Save annotation strokes for a specific file and page.
  Future<void> saveAnnotations(
    String fileId,
    int page,
    List<Map<String, dynamic>> strokesData,
  ) async {
    final key = _annotationKey(fileId, page);
    await _notesBox.put(key, strokesData);
  }

  /// Load annotation strokes for a specific file and page.
  List<Map<String, dynamic>> loadAnnotations(String fileId, int page) {
    final key = _annotationKey(fileId, page);
    final data = _notesBox.get(key);
    if (data == null) return [];

    // Convert from Hive's dynamic list to typed list
    final list = (data as List).cast<Map>();
    return list
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  /// Delete all annotations for a file.
  Future<void> deleteAnnotationsForFile(String fileId) async {
    // Find all annotation keys for this file
    final keysToDelete = _notesBox.keys
        .where((k) => k.toString().startsWith('annot_${fileId}_'))
        .toList();
    for (final key in keysToDelete) {
      await _notesBox.delete(key);
    }
  }
}
