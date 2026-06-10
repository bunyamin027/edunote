import '../../domain/repositories/folder_repository.dart';
import '../datasources/local/hive_folder_datasource.dart';
import '../models/folder_model.dart';

/// Concrete implementation of [FolderRepository] using Hive.
class FolderRepositoryImpl implements FolderRepository {
  final HiveFolderDatasource _datasource;

  FolderRepositoryImpl(this._datasource);

  @override
  List<FolderModel> getAllFolders() => _datasource.getAll();

  @override
  FolderModel? getFolderById(String id) => _datasource.getById(id);

  @override
  List<FolderModel> getChildFolders(String? parentId) =>
      _datasource.getChildren(parentId);

  @override
  List<FolderModel> getRootFolders() => _datasource.getRootFolders();

  @override
  Future<void> createFolder(FolderModel folder) => _datasource.save(folder);

  @override
  Future<void> updateFolder(FolderModel folder) => _datasource.save(folder);

  @override
  Future<void> deleteFolder(String id) => _datasource.delete(id);
}
