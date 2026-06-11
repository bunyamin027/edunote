import 'package:equatable/equatable.dart';
import '../../data/models/document_note_model.dart';

abstract class DocumentNoteState extends Equatable {
  const DocumentNoteState();

  @override
  List<Object?> get props => [];
}

class DocumentNoteInitial extends DocumentNoteState {}

class DocumentNoteLoading extends DocumentNoteState {}

class DocumentNoteLoaded extends DocumentNoteState {
  final List<DocumentNoteModel> notes;

  const DocumentNoteLoaded(this.notes);

  @override
  List<Object?> get props => [notes];
}

class DocumentNoteError extends DocumentNoteState {
  final String message;

  const DocumentNoteError(this.message);

  @override
  List<Object?> get props => [message];
}
