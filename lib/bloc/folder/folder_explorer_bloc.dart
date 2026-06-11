import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/folder_model.dart';
import '../../data/services/file_import_service.dart';
import '../../data/services/ai_result_service.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../domain/repositories/notebook_repository.dart';
import 'folder_explorer_event.dart';
import 'folder_explorer_state.dart';

/// Bloc for the folder explorer — Windows Explorer-like navigation
/// through folders, notebooks, and imported files.
class FolderExplorerBloc
    extends Bloc<FolderExplorerEvent, FolderExplorerState> {
  final FolderRepository _folderRepo;
  final NotebookRepository _notebookRepo;
  final FileImportService _fileService;
  final AiResultService _aiResultService;
  final _uuid = const Uuid();

  // Navigation state
  final List<BreadcrumbItem> _breadcrumbs = [
    const BreadcrumbItem(name: 'Dosyalarım'),
  ];
  bool _isGridView = true;

  FolderExplorerBloc({
    required FolderRepository folderRepo,
    required NotebookRepository notebookRepo,
    required FileImportService fileService,
    required AiResultService aiResultService,
  })  : _folderRepo = folderRepo,
        _notebookRepo = notebookRepo,
        _fileService = fileService,
        _aiResultService = aiResultService,
        super(FolderExplorerInitial()) {
    on<LoadFolderContents>(_onLoadContents);
    on<NavigateToFolder>(_onNavigateToFolder);
    on<NavigateBack>(_onNavigateBack);
    on<NavigateToBreadcrumb>(_onNavigateToBreadcrumb);
    on<CreateFolder>(_onCreateFolder);
    on<RenameFolder>(_onRenameFolder);
    on<DeleteFolder>(_onDeleteFolder);
    on<ImportFileToCurrentFolder>(_onImportFile);
    on<DeleteFile>(_onDeleteFile);
    on<ToggleViewMode>(_onToggleView);
  }

  String? get _currentFolderId {
    if (_breadcrumbs.length <= 1) return null;
    return _breadcrumbs.last.folderId;
  }

  // ─── Load Contents ────────────────────────────────────

  void _onLoadContents(
      LoadFolderContents event, Emitter<FolderExplorerState> emit) {
    emit(FolderExplorerLoading());

    try {
      final folderId = event.folderId ?? _currentFolderId;

      // Get sub-folders
      final subFolders = _folderRepo.getChildFolders(folderId);

      // Get notebooks in this folder
      final notebooks = _notebookRepo.getNotebooksByFolder(folderId);

      // Get files and AI results in this folder (only if we have a specific folder)
      final files = folderId != null
          ? _fileService.getFilesForFolder(folderId)
          : <dynamic>[];
          
      final aiResults = folderId != null
          ? _aiResultService.getResultsForFolder(folderId)
          : <dynamic>[];

      emit(FolderExplorerLoaded(
        currentFolderId: folderId,
        breadcrumbs: List.unmodifiable(_breadcrumbs),
        subFolders: subFolders,
        notebooks: notebooks,
        files: List.from(files),
        aiResults: List.from(aiResults),
        isGridView: _isGridView,
      ));
    } catch (e) {
      debugPrint('Folder load error: $e');
      emit(FolderExplorerError('Klasör yüklenirken hata oluştu: $e'));
    }
  }

  // ─── Navigation ───────────────────────────────────────

  void _onNavigateToFolder(
      NavigateToFolder event, Emitter<FolderExplorerState> emit) {
    _breadcrumbs.add(BreadcrumbItem(
      folderId: event.folderId,
      name: event.folderName,
    ));
    add(LoadFolderContents(folderId: event.folderId));
  }

  void _onNavigateBack(
      NavigateBack event, Emitter<FolderExplorerState> emit) {
    if (_breadcrumbs.length > 1) {
      _breadcrumbs.removeLast();
      add(LoadFolderContents(folderId: _currentFolderId));
    }
  }

  void _onNavigateToBreadcrumb(
      NavigateToBreadcrumb event, Emitter<FolderExplorerState> emit) {
    if (event.index >= 0 && event.index < _breadcrumbs.length) {
      // Remove everything after the selected breadcrumb
      while (_breadcrumbs.length > event.index + 1) {
        _breadcrumbs.removeLast();
      }
      add(LoadFolderContents(folderId: _currentFolderId));
    }
  }

  // ─── Folder CRUD ──────────────────────────────────────

  Future<void> _onCreateFolder(
      CreateFolder event, Emitter<FolderExplorerState> emit) async {
    try {
      final folder = FolderModel.create(
        id: _uuid.v4(),
        name: event.name,
        parentId: _currentFolderId,
        colorIndex: event.colorIndex,
      );

      await _folderRepo.createFolder(folder);
      add(LoadFolderContents(folderId: _currentFolderId));
    } catch (e) {
      debugPrint('Create folder error: $e');
    }
  }

  Future<void> _onRenameFolder(
      RenameFolder event, Emitter<FolderExplorerState> emit) async {
    try {
      final folder = _folderRepo.getFolderById(event.folderId);
      if (folder == null) return;

      final updated = folder.copyWith(name: event.newName);
      await _folderRepo.updateFolder(updated);
      add(LoadFolderContents(folderId: _currentFolderId));
    } catch (e) {
      debugPrint('Rename folder error: $e');
    }
  }

  Future<void> _onDeleteFolder(
      DeleteFolder event, Emitter<FolderExplorerState> emit) async {
    try {
      // Delete files and AI results in folder first
      await _fileService.deleteFilesForFolder(event.folderId);
      await _aiResultService.deleteResultsForFolder(event.folderId);
      // Then delete the folder itself
      await _folderRepo.deleteFolder(event.folderId);
      add(LoadFolderContents(folderId: _currentFolderId));
    } catch (e) {
      debugPrint('Delete folder error: $e');
    }
  }

  // ─── File Operations ──────────────────────────────────

  Future<void> _onImportFile(
      ImportFileToCurrentFolder event, Emitter<FolderExplorerState> emit) async {
    try {
      final result = await picker.FilePicker.platform.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'png', 'jpg', 'jpeg', 'webp', 'doc', 'docx', 'pptx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      final folderId = _currentFolderId;

      if (folderId != null) {
        await _fileService.importFileToFolder(
          pickedFile: pickedFile,
          folderId: folderId,
        );
      }

      add(LoadFolderContents(folderId: _currentFolderId));
    } catch (e) {
      debugPrint('Import file error: $e');
    }
  }

  Future<void> _onDeleteFile(
      DeleteFile event, Emitter<FolderExplorerState> emit) async {
    try {
      await _fileService.deleteFile(event.fileId);
      add(LoadFolderContents(folderId: _currentFolderId));
    } catch (e) {
      debugPrint('Delete file error: $e');
    }
  }

  // ─── View Mode ────────────────────────────────────────

  void _onToggleView(
      ToggleViewMode event, Emitter<FolderExplorerState> emit) {
    _isGridView = !_isGridView;
    final currentState = state;
    if (currentState is FolderExplorerLoaded) {
      emit(currentState.copyWith(isGridView: _isGridView));
    }
  }
}
