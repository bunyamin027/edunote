import 'package:hive_flutter/hive_flutter.dart';

import '../../models/folder_model.dart';

/// Local datasource for folders using Hive.
class HiveFolderDatasource {
  final Box _box;

  HiveFolderDatasource(this._box);

  /// Get all folders.
  List<FolderModel> getAll() {
    return _box.values
        .map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get a folder by ID.
  FolderModel? getById(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return FolderModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Get child folders of a parent.
  List<FolderModel> getChildren(String? parentId) {
    return getAll().where((f) => f.parentId == parentId).toList();
  }

  /// Get root-level folders.
  List<FolderModel> getRootFolders() => getChildren(null);

  /// Save or update a folder.
  Future<void> save(FolderModel folder) async {
    await _box.put(folder.id, folder.toJson());
  }

  /// Delete a folder.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Get count of folders.
  int get count => _box.length;
}
