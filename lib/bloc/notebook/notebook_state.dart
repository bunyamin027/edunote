import 'package:equatable/equatable.dart';
import '../../data/models/notebook_model.dart';

/// States for the NotebookBloc.
abstract class NotebookState extends Equatable {
  const NotebookState();

  @override
  List<Object?> get props => [];
}

/// Initial state — nothing loaded yet.
class NotebookInitial extends NotebookState {
  const NotebookInitial();
}

/// Notebooks are loading.
class NotebookLoading extends NotebookState {
  const NotebookLoading();
}

/// Notebooks loaded successfully.
class NotebookLoaded extends NotebookState {
  final List<NotebookModel> notebooks;
  final List<NotebookModel> recentNotebooks;

  const NotebookLoaded({
    required this.notebooks,
    required this.recentNotebooks,
  });

  @override
  List<Object?> get props => [notebooks, recentNotebooks];
}

/// A notebook was just created — includes the new ID for navigation.
class NotebookCreated extends NotebookState {
  final String notebookId;

  const NotebookCreated(this.notebookId);

  @override
  List<Object?> get props => [notebookId];
}

/// An error occurred.
class NotebookError extends NotebookState {
  final String message;

  const NotebookError(this.message);

  @override
  List<Object?> get props => [message];
}
