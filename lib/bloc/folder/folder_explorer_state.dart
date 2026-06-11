import 'package:equatable/equatable.dart';

import '../../data/models/folder_model.dart';
import '../../data/models/imported_file_model.dart';
import '../../data/models/notebook_model.dart';
import '../../data/models/ai_result_model.dart';

/// A breadcrumb entry for folder navigation.
class BreadcrumbItem extends Equatable {
  final String? folderId; // null = root
  final String name;

  const BreadcrumbItem({this.folderId, required this.name});

  @override
  List<Object?> get props => [folderId, name];
}

/// States for the Folder Explorer Bloc.
abstract class FolderExplorerState extends Equatable {
  const FolderExplorerState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any content is loaded.
class FolderExplorerInitial extends FolderExplorerState {}

/// Loading folder contents.
class FolderExplorerLoading extends FolderExplorerState {}

/// Folder contents loaded — shows sub-folders, notebooks, and files.
class FolderExplorerLoaded extends FolderExplorerState {
  /// Current folder ID (null = root).
  final String? currentFolderId;

  /// Breadcrumb trail for navigation.
  final List<BreadcrumbItem> breadcrumbs;

  /// Sub-folders in the current location.
  final List<FolderModel> subFolders;

  /// Notebooks in the current folder.
  final List<NotebookModel> notebooks;

  /// Imported files in the current folder.
  final List<ImportedFile> files;

  /// AI results in the current folder.
  final List<AiResultModel> aiResults;

  /// Whether to show grid or list view.
  final bool isGridView;

  const FolderExplorerLoaded({
    this.currentFolderId,
    required this.breadcrumbs,
    required this.subFolders,
    required this.notebooks,
    required this.files,
    required this.aiResults,
    this.isGridView = true,
  });

  /// Total item count.
  int get totalItems => subFolders.length + notebooks.length + files.length + aiResults.length;

  /// Whether we are at the root level.
  bool get isRoot => currentFolderId == null;

  FolderExplorerLoaded copyWith({
    String? currentFolderId,
    List<BreadcrumbItem>? breadcrumbs,
    List<FolderModel>? subFolders,
    List<NotebookModel>? notebooks,
    List<ImportedFile>? files,
    List<AiResultModel>? aiResults,
    bool? isGridView,
  }) {
    return FolderExplorerLoaded(
      currentFolderId: currentFolderId ?? this.currentFolderId,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      subFolders: subFolders ?? this.subFolders,
      notebooks: notebooks ?? this.notebooks,
      files: files ?? this.files,
      aiResults: aiResults ?? this.aiResults,
      isGridView: isGridView ?? this.isGridView,
    );
  }

  @override
  List<Object?> get props => [
        currentFolderId, breadcrumbs, subFolders,
        notebooks, files, aiResults, isGridView,
      ];
}

/// Error loading folder contents.
class FolderExplorerError extends FolderExplorerState {
  final String message;
  const FolderExplorerError(this.message);

  @override
  List<Object?> get props => [message];
}
