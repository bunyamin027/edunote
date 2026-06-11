import 'package:equatable/equatable.dart';

/// Events for the Folder Explorer Bloc.
abstract class FolderExplorerEvent extends Equatable {
  const FolderExplorerEvent();

  @override
  List<Object?> get props => [];
}

/// Load the contents of a folder (or root if folderId is null).
class LoadFolderContents extends FolderExplorerEvent {
  final String? folderId;
  const LoadFolderContents({this.folderId});

  @override
  List<Object?> get props => [folderId];
}

/// Navigate into a sub-folder (push onto breadcrumb stack).
class NavigateToFolder extends FolderExplorerEvent {
  final String folderId;
  final String folderName;
  const NavigateToFolder({required this.folderId, required this.folderName});

  @override
  List<Object?> get props => [folderId, folderName];
}

/// Navigate back to parent folder (pop breadcrumb).
class NavigateBack extends FolderExplorerEvent {}

/// Navigate to a specific breadcrumb item.
class NavigateToBreadcrumb extends FolderExplorerEvent {
  final int index; // index in breadcrumb trail
  const NavigateToBreadcrumb(this.index);

  @override
  List<Object?> get props => [index];
}

/// Create a new folder in the current location.
class CreateFolder extends FolderExplorerEvent {
  final String name;
  final int colorIndex;
  const CreateFolder({required this.name, this.colorIndex = 0});

  @override
  List<Object?> get props => [name, colorIndex];
}

/// Rename a folder.
class RenameFolder extends FolderExplorerEvent {
  final String folderId;
  final String newName;
  const RenameFolder({required this.folderId, required this.newName});

  @override
  List<Object?> get props => [folderId, newName];
}

/// Delete a folder and its contents.
class DeleteFolder extends FolderExplorerEvent {
  final String folderId;
  const DeleteFolder(this.folderId);

  @override
  List<Object?> get props => [folderId];
}

/// Import a file into the current folder.
class ImportFileToCurrentFolder extends FolderExplorerEvent {}

/// Delete a file from the current folder.
class DeleteFile extends FolderExplorerEvent {
  final String fileId;
  const DeleteFile(this.fileId);

  @override
  List<Object?> get props => [fileId];
}

/// Toggle between grid and list view.
class ToggleViewMode extends FolderExplorerEvent {}
