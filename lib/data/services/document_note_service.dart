import 'package:hive_flutter/hive_flutter.dart';

import '../models/document_note_model.dart';

import '../repositories/annotation_repository.dart';
import '../../presentation/canvas/engine/stroke.dart';

/// Service for managing document notes (Hive) and annotations (Drift SQLite).
class DocumentNoteService {
  final Box _notesBox;
  final AnnotationRepository _annotationRepo;

  DocumentNoteService(this._notesBox, this._annotationRepo);

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

  /// Save annotation strokes for a specific file and page.
  Future<void> saveAnnotations(
    String fileId,
    int page,
    List<Map<String, dynamic>> strokesData,
  ) async {
    // Delete existing annotations for this page first to avoid duplicates
    // since we're saving the whole page state
    final existing = await _annotationRepo.getAnnotationsForPage(fileId, page);
    for (final annot in existing) {
      await _annotationRepo.deleteAnnotation(annot.id);
    }
    
    // Convert generic map data back to Strokes temporarily to calculate bounds
    for (final strokeData in strokesData) {
      final stroke = Stroke.fromJson(strokeData);
      final companion = _annotationRepo.strokeToDb(fileId, page, stroke);
      await _annotationRepo.saveAnnotation(companion);
    }
  }

  /// Load annotation strokes for a specific file and page.
  Future<List<Map<String, dynamic>>> loadAnnotations(String fileId, int page) async {
    final annotations = await _annotationRepo.getAnnotationsForPage(fileId, page);
    
    final result = <Map<String, dynamic>>[];
    for (final annot in annotations) {
      final stroke = _annotationRepo.dbToStroke(annot);
      if (stroke != null) {
        result.add(stroke.toJson());
      }
    }
    return result;
  }

  /// Delete all annotations for a file.
  Future<void> deleteAnnotationsForFile(String fileId) async {
    await _annotationRepo.deleteAllForFile(fileId);
  }
}
