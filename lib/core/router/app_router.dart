import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/folder/folder_explorer_bloc.dart';
import '../../bloc/document_note/document_note_cubit.dart';
import '../../core/config/injection.dart';
import '../../data/services/document_note_service.dart';
import '../../data/services/file_import_service.dart';
import '../../data/services/ai_result_service.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../domain/repositories/notebook_repository.dart';
import '../../presentation/auth/auth_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/folders/folder_explorer_screen.dart';
import '../../presentation/ai/ai_screen.dart';
import '../../presentation/ai/ai_result_viewer_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/canvas/canvas_screen.dart';
import '../../presentation/files/files_screen.dart';
import '../../presentation/document/document_analysis_screen.dart';
import '../../presentation/pdf/pdf_document_screen.dart';
import '../../data/models/imported_file_model.dart';
import '../../data/models/ai_result_model.dart';

/// Route path constants.
class AppRoutes {
  AppRoutes._();

  static const String auth = '/auth';
  static const String home = '/';
  static const String notebooks = '/notebooks';
  static const String ai = '/ai';
  static const String aiResultViewer = '/ai-result-viewer';
  static const String settings = '/settings';
  static const String canvas = '/canvas/:notebookId';
  static const String files = '/files/:notebookId';
  static const String documentAnalysis = '/document-analysis';
  static const String documentViewer = '/document-viewer';

  /// Generate canvas route with notebook ID.
  static String canvasPath(String notebookId) => '/canvas/$notebookId';

  /// Generate files route with notebook ID.
  static String filesPath(String notebookId) => '/files/$notebookId';
}

/// Shell for bottom navigation — wraps all main tabs.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Dosyalarım',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'AI Asistan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

/// Application router configuration.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.auth,
  routes: [
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    // ─── Main Shell (Bottom Navigation) ─────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _MainShell(navigationShell: navigationShell),
      branches: [
        // Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Dosyalarım (Folder Explorer)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.notebooks,
              builder: (context, state) => BlocProvider(
                create: (_) => FolderExplorerBloc(
                  folderRepo: sl<FolderRepository>(),
                  notebookRepo: sl<NotebookRepository>(),
                  fileService: sl<FileImportService>(),
                  aiResultService: sl<AiResultService>(),
                ),
                child: const FolderExplorerScreen(),
              ),
            ),
          ],
        ),
        // AI Assistant
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.ai,
              builder: (context, state) => const AiScreen(),
            ),
          ],
        ),
        // Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // ─── Canvas (Full Screen — No Bottom Nav) ───────
    GoRoute(
      path: AppRoutes.canvas,
      builder: (context, state) {
        final notebookId = state.pathParameters['notebookId']!;
        return CanvasScreen(notebookId: notebookId);
      },
    ),

    // ─── Files (Full Screen — No Bottom Nav) ────────
    GoRoute(
      path: AppRoutes.files,
      builder: (context, state) {
        final notebookId = state.pathParameters['notebookId']!;
        return FilesScreen(notebookId: notebookId);
      },
    ),

    // ─── Document Analysis (Full Screen — No Bottom Nav) ────
    GoRoute(
      path: AppRoutes.documentAnalysis,
      builder: (context, state) {
        final file = state.extra as ImportedFile?;
        return DocumentAnalysisScreen(file: file);
      },
    ),

    // ─── Document Viewer (Full Screen — No Bottom Nav) ─────
    GoRoute(
      path: AppRoutes.documentViewer,
      builder: (context, state) {
        final file = state.extra as ImportedFile;
        return PdfDocumentScreen(file: file);
      },
    ),

    // ─── AI Result Viewer ──────────────────────────────────
    GoRoute(
      path: AppRoutes.aiResultViewer,
      builder: (context, state) {
        final aiResult = state.extra as AiResultModel;
        return AiResultViewerScreen(aiResult: aiResult);
      },
    ),
  ],
);
