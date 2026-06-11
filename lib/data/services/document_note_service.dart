import 'package:hive_flutter/hive_flutter.dart';

import '../models/document_note_model.dart';

/// Service for managing document notes using Hive.
class DocumentNoteService {
  final Box _notesBox;

  DocumentNoteService(this._notesBox);

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
}
