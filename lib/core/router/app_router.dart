import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/auth_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/notebook/notebooks_screen.dart';
import '../../presentation/ai/ai_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/canvas/canvas_screen.dart';
import '../../presentation/files/files_screen.dart';

/// Route path constants.
class AppRoutes {
  AppRoutes._();

  static const String auth = '/auth';
  static const String home = '/';
  static const String notebooks = '/notebooks';
  static const String ai = '/ai';
  static const String settings = '/settings';
  static const String canvas = '/canvas/:notebookId';
  static const String files = '/files/:notebookId';

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
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Defterler',
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
        // Notebooks
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.notebooks,
              builder: (context, state) => const NotebooksScreen(),
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
  ],
);
