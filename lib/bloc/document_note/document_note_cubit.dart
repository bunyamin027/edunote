import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/document_note_model.dart';
import '../../data/services/document_note_service.dart';
import 'document_note_state.dart';

class DocumentNoteCubit extends Cubit<DocumentNoteState> {
  final DocumentNoteService _noteService;
  final String sourceFileId;
  final _uuid = const Uuid();

  DocumentNoteCubit(this._noteService, this.sourceFileId) : super(DocumentNoteInitial());

  /// Load notes for the current file
  Future<void> loadNotes() async {
    emit(DocumentNoteLoading());
    try {
      final notes = _noteService.getNotesForFile(sourceFileId);
      // Sort by newest first
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      emit(DocumentNoteLoaded(notes));
    } catch (e) {
      emit(DocumentNoteError('Notlar yüklenirken bir hata oluştu: $e'));
    }
  }

  /// Save a new note
  Future<void> addNote(String content) async {
    if (content.trim().isEmpty) return;

    try {
      final note = DocumentNoteModel.create(
        id: _uuid.v4(),
        sourceFileId: sourceFileId,
        content: content.trim(),
      );
      
      await _noteService.saveNote(note);
      await loadNotes(); // reload
    } catch (e) {
      emit(DocumentNoteError('Not kaydedilirken bir hata oluştu: $e'));
    }
  }

  /// Update an existing note
  Future<void> updateNote(DocumentNoteModel existingNote, String newContent) async {
    if (newContent.trim().isEmpty) return;

    try {
      final updatedNote = existingNote.copyWith(content: newContent.trim());
      await _noteService.saveNote(updatedNote);
      await loadNotes(); // reload
    } catch (e) {
      emit(DocumentNoteError('Not güncellenirken bir hata oluştu: $e'));
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _noteService.deleteNote(noteId);
      await loadNotes(); // reload
    } catch (e) {
      emit(DocumentNoteError('Not silinirken bir hata oluştu: $e'));
    }
  }
}
