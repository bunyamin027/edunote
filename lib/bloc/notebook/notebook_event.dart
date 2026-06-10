import 'package:equatable/equatable.dart';

/// Events for the NotebookBloc.
abstract class NotebookEvent extends Equatable {
  const NotebookEvent();

  @override
  List<Object?> get props => [];
}

/// Load all notebooks.
class LoadNotebooks extends NotebookEvent {
  const LoadNotebooks();
}

/// Create a new notebook.
class CreateNotebook extends NotebookEvent {
  final String name;
  final int coverIndex;
  final int templateIndex;
  final String? folderId;

  const CreateNotebook({
    required this.name,
    required this.coverIndex,
    required this.templateIndex,
    this.folderId,
  });

  @override
  List<Object?> get props => [name, coverIndex, templateIndex, folderId];
}

/// Delete a notebook.
class DeleteNotebook extends NotebookEvent {
  final String id;

  const DeleteNotebook(this.id);

  @override
  List<Object?> get props => [id];
}

/// Rename a notebook.
class RenameNotebook extends NotebookEvent {
  final String id;
  final String newName;

  const RenameNotebook({required this.id, required this.newName});

  @override
  List<Object?> get props => [id, newName];
}

/// Search notebooks.
class SearchNotebooks extends NotebookEvent {
  final String query;

  const SearchNotebooks(this.query);

  @override
  List<Object?> get props => [query];
}
