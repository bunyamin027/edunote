import 'package:hive_flutter/hive_flutter.dart';

import '../../models/notebook_model.dart';

/// Local datasource for notebooks using Hive.
class HiveNotebookDatasource {
  final Box _box;

  HiveNotebookDatasource(this._box);

  /// Get all notebooks.
  List<NotebookModel> getAll() {
    return _box.values
        .map((e) => NotebookModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Get a single notebook by ID.
  NotebookModel? getById(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return NotebookModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Get notebooks by folder ID.
  List<NotebookModel> getByFolderId(String? folderId) {
    return getAll().where((n) => n.folderId == folderId).toList();
  }

  /// Save or update a notebook.
  Future<void> save(NotebookModel notebook) async {
    await _box.put(notebook.id, notebook.toJson());
  }

  /// Delete a notebook.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Search notebooks by name.
  List<NotebookModel> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll()
        .where((n) => n.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get the count of notebooks.
  int get count => _box.length;
}
