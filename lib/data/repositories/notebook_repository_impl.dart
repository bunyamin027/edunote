import '../../domain/repositories/notebook_repository.dart';
import '../datasources/local/hive_notebook_datasource.dart';
import '../models/notebook_model.dart';

/// Concrete implementation of [NotebookRepository] using Hive.
class NotebookRepositoryImpl implements NotebookRepository {
  final HiveNotebookDatasource _datasource;

  NotebookRepositoryImpl(this._datasource);

  @override
  List<NotebookModel> getAllNotebooks() => _datasource.getAll();

  @override
  NotebookModel? getNotebookById(String id) => _datasource.getById(id);

  @override
  List<NotebookModel> getNotebooksByFolder(String? folderId) =>
      _datasource.getByFolderId(folderId);

  @override
  Future<void> createNotebook(NotebookModel notebook) =>
      _datasource.save(notebook);

  @override
  Future<void> updateNotebook(NotebookModel notebook) =>
      _datasource.save(notebook);

  @override
  Future<void> deleteNotebook(String id) => _datasource.delete(id);

  @override
  List<NotebookModel> searchNotebooks(String query) =>
      _datasource.search(query);

  @override
  int get notebookCount => _datasource.count;
}
