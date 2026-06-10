import '../../data/models/notebook_model.dart';

/// Abstract repository interface for notebooks.
abstract class NotebookRepository {
  /// Get all notebooks, sorted by most recently updated.
  List<NotebookModel> getAllNotebooks();

  /// Get a notebook by its ID.
  NotebookModel? getNotebookById(String id);

  /// Get notebooks in a specific folder.
  List<NotebookModel> getNotebooksByFolder(String? folderId);

  /// Create a new notebook.
  Future<void> createNotebook(NotebookModel notebook);

  /// Update an existing notebook.
  Future<void> updateNotebook(NotebookModel notebook);

  /// Delete a notebook.
  Future<void> deleteNotebook(String id);

  /// Search notebooks by name.
  List<NotebookModel> searchNotebooks(String query);

  /// Get the total count of notebooks.
  int get notebookCount;
}
