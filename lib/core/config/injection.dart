import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/app_constants.dart';
import '../../data/datasources/local/hive_notebook_datasource.dart';
import '../../data/datasources/local/hive_folder_datasource.dart';
import '../../data/repositories/notebook_repository_impl.dart';
import '../../data/repositories/folder_repository_impl.dart';
import '../../domain/repositories/notebook_repository.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../data/services/canvas_storage_service.dart';
import '../../data/services/file_import_service.dart';
import '../../data/services/ai_service.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Initialize all dependencies.
Future<void> initDependencies() async {
  // ─── Hive Boxes ───────────────────────────────────
  final notebooksBox = await Hive.openBox(AppConstants.notebooksBox);
  final foldersBox = await Hive.openBox(AppConstants.foldersBox);
  final settingsBox = await Hive.openBox(AppConstants.settingsBox);
  final pagesBox = await Hive.openBox(AppConstants.pagesBox);
  final filesBox = await Hive.openBox(AppConstants.filesBox);

  sl.registerSingleton<Box>(notebooksBox, instanceName: 'notebooksBox');
  sl.registerSingleton<Box>(foldersBox, instanceName: 'foldersBox');
  sl.registerSingleton<Box>(settingsBox, instanceName: 'settingsBox');
  sl.registerSingleton<Box>(pagesBox, instanceName: 'pagesBox');
  sl.registerSingleton<Box>(filesBox, instanceName: 'filesBox');

  // ─── Data Sources ─────────────────────────────────
  sl.registerLazySingleton<HiveNotebookDatasource>(
    () => HiveNotebookDatasource(sl(instanceName: 'notebooksBox')),
  );
  sl.registerLazySingleton<HiveFolderDatasource>(
    () => HiveFolderDatasource(sl(instanceName: 'foldersBox')),
  );

  // ─── Repositories ─────────────────────────────────
  sl.registerLazySingleton<NotebookRepository>(
    () => NotebookRepositoryImpl(sl<HiveNotebookDatasource>()),
  );
  sl.registerLazySingleton<FolderRepository>(
    () => FolderRepositoryImpl(sl<HiveFolderDatasource>()),
  );

  // ─── Services ───────────────────────────────────
  sl.registerLazySingleton<CanvasStorageService>(
    () => CanvasStorageService(sl(instanceName: 'pagesBox')),
  );
  sl.registerLazySingleton<FileImportService>(
    () => FileImportService(sl(instanceName: 'filesBox')),
  );
  sl.registerLazySingleton<AiService>(
    () => AiService(),
  );
}
