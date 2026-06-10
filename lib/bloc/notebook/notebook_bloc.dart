import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/notebook_model.dart';
import '../../domain/repositories/notebook_repository.dart';
import 'notebook_event.dart';
import 'notebook_state.dart';

/// BLoC for managing notebook operations.
class NotebookBloc extends Bloc<NotebookEvent, NotebookState> {
  final NotebookRepository _repository;
  final _uuid = const Uuid();

  NotebookBloc({required NotebookRepository repository})
      : _repository = repository,
        super(const NotebookInitial()) {
    on<LoadNotebooks>(_onLoadNotebooks);
    on<CreateNotebook>(_onCreateNotebook);
    on<DeleteNotebook>(_onDeleteNotebook);
    on<RenameNotebook>(_onRenameNotebook);
    on<SearchNotebooks>(_onSearchNotebooks);
  }

  void _onLoadNotebooks(
    LoadNotebooks event,
    Emitter<NotebookState> emit,
  ) {
    emit(const NotebookLoading());
    try {
      final notebooks = _repository.getAllNotebooks();
      final recent = notebooks.take(6).toList();
      emit(NotebookLoaded(notebooks: notebooks, recentNotebooks: recent));
    } catch (e) {
      emit(NotebookError('Not defterleri yüklenirken hata oluştu: $e'));
    }
  }

  Future<void> _onCreateNotebook(
    CreateNotebook event,
    Emitter<NotebookState> emit,
  ) async {
    try {
      final id = _uuid.v4();
      final notebook = NotebookModel.create(
        id: id,
        name: event.name,
        coverIndex: event.coverIndex,
        template: PaperTemplate.values[event.templateIndex],
        folderId: event.folderId,
      );
      await _repository.createNotebook(notebook);
      emit(NotebookCreated(id));
      // Reload notebooks list
      add(const LoadNotebooks());
    } catch (e) {
      emit(NotebookError('Not defteri oluşturulamadı: $e'));
    }
  }

  Future<void> _onDeleteNotebook(
    DeleteNotebook event,
    Emitter<NotebookState> emit,
  ) async {
    try {
      await _repository.deleteNotebook(event.id);
      add(const LoadNotebooks());
    } catch (e) {
      emit(NotebookError('Not defteri silinemedi: $e'));
    }
  }

  Future<void> _onRenameNotebook(
    RenameNotebook event,
    Emitter<NotebookState> emit,
  ) async {
    try {
      final notebook = _repository.getNotebookById(event.id);
      if (notebook != null) {
        await _repository.updateNotebook(
          notebook.copyWith(name: event.newName),
        );
        add(const LoadNotebooks());
      }
    } catch (e) {
      emit(NotebookError('Not defteri yeniden adlandırılamadı: $e'));
    }
  }

  void _onSearchNotebooks(
    SearchNotebooks event,
    Emitter<NotebookState> emit,
  ) {
    try {
      final results = event.query.isEmpty
          ? _repository.getAllNotebooks()
          : _repository.searchNotebooks(event.query);
      final recent = results.take(6).toList();
      emit(NotebookLoaded(notebooks: results, recentNotebooks: recent));
    } catch (e) {
      emit(NotebookError('Arama hatası: $e'));
    }
  }
}
