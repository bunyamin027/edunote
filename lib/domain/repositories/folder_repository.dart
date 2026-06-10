import '../../data/models/folder_model.dart';

/// Abstract repository interface for folders.
abstract class FolderRepository {
  /// Get all folders.
  List<FolderModel> getAllFolders();

  /// Get a folder by its ID.
  FolderModel? getFolderById(String id);

  /// Get children of a parent folder.
  List<FolderModel> getChildFolders(String? parentId);

  /// Get root-level folders.
  List<FolderModel> getRootFolders();

  /// Create a new folder.
  Future<void> createFolder(FolderModel folder);

  /// Update an existing folder.
  Future<void> updateFolder(FolderModel folder);

  /// Delete a folder.
  Future<void> deleteFolder(String id);
}
