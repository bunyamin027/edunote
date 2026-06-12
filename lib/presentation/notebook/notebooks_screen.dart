import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../bloc/notebook/notebook_bloc.dart';
import '../../bloc/notebook/notebook_event.dart';
import '../../bloc/notebook/notebook_state.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/notebook_model.dart';
import 'create_notebook_sheet.dart';

/// Notebooks Screen — Full list of all notebooks with search.
class NotebooksScreen extends StatefulWidget {
  const NotebooksScreen({super.key});

  @override
  State<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends State<NotebooksScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    context.read<NotebookBloc>().add(const LoadNotebooks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Defterleri'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(
              _isGridView
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingHorizontal,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<NotebookBloc>().add(SearchNotebooks(query));
              },
              decoration: InputDecoration(
                hintText: 'Not defterlerinde ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<NotebookBloc>()
                              .add(const LoadNotebooks());
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Notebook list
          Expanded(
            child: BlocBuilder<NotebookBloc, NotebookState>(
              builder: (context, state) {
                if (state is NotebookLoaded) {
                  if (state.notebooks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Henüz not defteri yok',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_isGridView) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(
                        AppSpacing.pagePaddingHorizontal,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: state.notebooks.length,
                      itemBuilder: (context, index) {
                        final notebook = state.notebooks[index];
                        return _NotebookGridItem(
                          notebook: notebook,
                          onTap: () => context.push(
                            AppRoutes.canvasPath(notebook.id),
                          ),
                          onDelete: () => context
                              .read<NotebookBloc>()
                              .add(DeleteNotebook(notebook.id)),
                        ).animate().fadeIn(
                              duration: 300.ms,
                              delay: (index * 50).ms,
                            );
                      },
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(
                      AppSpacing.pagePaddingHorizontal,
                    ),
                    itemCount: state.notebooks.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final notebook = state.notebooks[index];
                      return _NotebookListItem(
                        notebook: notebook,
                        onTap: () => context.push(
                          AppRoutes.canvasPath(notebook.id),
                        ),
                        onDelete: () => context
                            .read<NotebookBloc>()
                            .add(DeleteNotebook(notebook.id)),
                      ).animate().fadeIn(
                            duration: 300.ms,
                            delay: (index * 50).ms,
                          );
                    },
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notebooks_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => const CreateNotebookSheet(),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── Grid Item ──────────────────────────────────────────
class _NotebookGridItem extends StatelessWidget {
  final NotebookModel notebook;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotebookGridItem({
    required this.notebook,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.coverGradients[
        notebook.coverIndex % AppColors.coverGradients.length];

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 36,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      notebook.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDate(notebook.updatedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(notebook.name),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Sil'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes}dk önce';
    if (diff.inDays < 1) return '${diff.inHours}sa önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return '${date.day}.${date.month}.${date.year}';
  }
}

// ─── List Item ──────────────────────────────────────────
class _NotebookListItem extends StatelessWidget {
  final NotebookModel notebook;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotebookListItem({
    required this.notebook,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.coverGradients[
        notebook.coverIndex % AppColors.coverGradients.length];

    return ListTile(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      tileColor: theme.colorScheme.surface,
      leading: Container(
        width: 44,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: const Icon(
          Icons.menu_book_rounded,
          color: Colors.white70,
          size: 20,
        ),
      ),
      title: Text(
        notebook.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${notebook.pageCount} sayfa'),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(notebook.name),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Sil'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal'),
        ),
      ),
    );
  }
}
