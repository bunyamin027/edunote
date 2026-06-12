import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/folder/folder_explorer_bloc.dart';
import '../../bloc/folder/folder_explorer_event.dart';
import '../../bloc/folder/folder_explorer_state.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/imported_file_model.dart';
import '../../data/models/notebook_model.dart';
import '../../data/models/ai_result_model.dart';

/// Data attached to a draggable item during drag-and-drop.
class DraggableItemData {
  final String id;
  final DraggableItemType type;
  final String label;

  const DraggableItemData({
    required this.id,
    required this.type,
    required this.label,
  });
}

/// Folder Explorer — Windows Explorer-style navigation
/// for folders, notebooks, and imported files.
class FolderExplorerScreen extends StatefulWidget {
  const FolderExplorerScreen({super.key});

  @override
  State<FolderExplorerScreen> createState() => _FolderExplorerScreenState();
}

class _FolderExplorerScreenState extends State<FolderExplorerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FolderExplorerBloc>().add(const LoadFolderContents());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Dosyalarım'),
        leading: BlocBuilder<FolderExplorerBloc, FolderExplorerState>(
          builder: (context, state) {
            if (state is FolderExplorerLoaded && !state.isRoot) {
              return IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.read<FolderExplorerBloc>().add(NavigateBack()),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        actions: [
          BlocBuilder<FolderExplorerBloc, FolderExplorerState>(
            builder: (context, state) {
              if (state is FolderExplorerLoaded) {
                return IconButton(
                  onPressed: () => context
                      .read<FolderExplorerBloc>()
                      .add(ToggleViewMode()),
                  icon: Icon(
                    state.isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<FolderExplorerBloc, FolderExplorerState>(
        builder: (context, state) {
          if (state is FolderExplorerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FolderExplorerLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb navigation
                if (!state.isRoot) _BreadcrumbBar(breadcrumbs: state.breadcrumbs),

                // Content
                Expanded(
                  child: state.totalItems == 0
                      ? _EmptyState(isRoot: state.isRoot)
                      : state.isGridView
                          ? _GridContent(state: state)
                          : _ListContent(state: state),
                ),
              ],
            );
          }

          if (state is FolderExplorerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(state.message),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<FolderExplorerBloc, FolderExplorerState>(
        builder: (context, state) {
          return FloatingActionButton(
            heroTag: 'folder_fab',
            onPressed: () => _showAddMenu(context, state),
            child: const Icon(Icons.add_rounded),
          );
        },
      ),
    );
  }

  void _showAddMenu(BuildContext context, FolderExplorerState state) {
    // Capture the bloc BEFORE opening the bottom sheet,
    // because showModalBottomSheet creates a new overlay route
    // that doesn't have access to the BlocProvider.
    final bloc = context.read<FolderExplorerBloc>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) => AddMenuSheet(
        state: state,
        onCreateFolder: () {
          Navigator.pop(sheetContext);
          _showCreateFolderDialog(context, bloc);
        },
        onImportFile: () async {
          Navigator.pop(sheetContext);
          await Future.delayed(const Duration(milliseconds: 300));
          bloc.add(ImportFileToCurrentFolder());
        },
        onCreateNotebook: () {
          Navigator.pop(sheetContext);
          // Navigate to create notebook flow
        },
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext parentContext, FolderExplorerBloc bloc) {
    final controller = TextEditingController();
    int selectedColor = 0;

    showDialog(
      context: parentContext,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Yeni Klasör'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Klasör Adı',
                  hintText: 'Örn: Matematik',
                  prefixIcon: Icon(Icons.folder_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Color picker
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppColors.coverGradients.length,
                  itemBuilder: (context, index) {
                    final colors = AppColors.coverGradients[index];
                    final isSelected = index == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = index),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: AppSpacing.xs),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colors.first.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogCtx);
                bloc.add(
                      CreateFolder(name: name, colorIndex: selectedColor),
                    );
              },
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

}

// ─── Breadcrumb Bar ──────────────────────────────────────

class _BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> breadcrumbs;

  const _BreadcrumbBar({required this.breadcrumbs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePaddingHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(breadcrumbs.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }

            final i = index ~/ 2;
            final item = breadcrumbs[i];
            final isLast = i == breadcrumbs.length - 1;

            return GestureDetector(
              onTap: isLast
                  ? null
                  : () => context
                      .read<FolderExplorerBloc>()
                      .add(NavigateToBreadcrumb(i)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: isLast
                      ? AppColors.primarySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  item.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isLast
                        ? AppColors.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isRoot;

  const _EmptyState({required this.isRoot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            child: Icon(
              isRoot ? Icons.folder_open_rounded : Icons.note_add_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            isRoot ? 'Henüz klasör yok' : 'Bu klasör boş',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isRoot
                ? 'Dosyalarınızı düzenlemek için + butonuyla klasör oluşturun'
                : '+ butonuyla dosya yükleyin veya klasör oluşturun',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── Grid Content ────────────────────────────────────────

class _GridContent extends StatelessWidget {
  final FolderExplorerLoaded state;

  const _GridContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: state.totalItems,
      itemBuilder: (context, index) {
        // Folders first, then notebooks, then files, then AI results
        if (index < state.subFolders.length) {
          final folder = state.subFolders[index];
          return _buildDraggable(
            data: DraggableItemData(
              id: folder.id,
              type: DraggableItemType.folder,
              label: folder.name,
            ),
            child: _FolderGridItem(folder: folder),
          ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms);
        }

        final notebookIndex = index - state.subFolders.length;
        if (notebookIndex < state.notebooks.length) {
          final notebook = state.notebooks[notebookIndex];
          return _buildDraggable(
            data: DraggableItemData(
              id: notebook.id,
              type: DraggableItemType.notebook,
              label: notebook.name,
            ),
            child: _NotebookGridItem(notebook: notebook),
          ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms);
        }

        final fileIndex = notebookIndex - state.notebooks.length;
        if (fileIndex < state.files.length) {
          final file = state.files[fileIndex];
          return _buildDraggable(
            data: DraggableItemData(
              id: file.id,
              type: DraggableItemType.file,
              label: file.fileName,
            ),
            child: _FileGridItem(file: file),
          ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms);
        }

        final aiResultIndex = fileIndex - state.files.length;
        final result = state.aiResults[aiResultIndex];
        return _buildDraggable(
          data: DraggableItemData(
            id: result.id,
            type: DraggableItemType.aiResult,
            label: result.title,
          ),
          child: _AiResultGridItem(result: result),
        ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms);
      },
    );
  }

  Widget _buildDraggable({
    required DraggableItemData data,
    required Widget child,
  }) {
    return LongPressDraggable<DraggableItemData>(
      data: data,
      delay: const Duration(milliseconds: 300),
      feedback: _DragFeedback(label: data.label),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}

// ─── List Content ────────────────────────────────────────

class _ListContent extends StatelessWidget {
  final FolderExplorerLoaded state;

  const _ListContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      itemCount: state.totalItems,
      itemBuilder: (context, index) {
        if (index < state.subFolders.length) {
          final folder = state.subFolders[index];
          return _buildDraggable(
            data: DraggableItemData(
              id: folder.id,
              type: DraggableItemType.folder,
              label: folder.name,
            ),
            child: _FolderListItem(folder: folder),
          ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
        }

        final notebookIndex = index - state.subFolders.length;
        if (notebookIndex < state.notebooks.length) {
          final notebook = state.notebooks[notebookIndex];
          return _buildDraggable(
            data: DraggableItemData(
              id: notebook.id,
              type: DraggableItemType.notebook,
              label: notebook.name,
            ),
            child: _NotebookListItem(notebook: notebook),
          ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
        }

        final fileIndex = notebookIndex - state.notebooks.length;
        if (fileIndex < state.files.length) {
          final file = state.files[fileIndex];
          return _buildDraggable(
            data: DraggableItemData(
              id: file.id,
              type: DraggableItemType.file,
              label: file.fileName,
            ),
            child: _FileListItem(file: file),
          ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
        }

        final aiResultIndex = fileIndex - state.files.length;
        final result = state.aiResults[aiResultIndex];
        return _buildDraggable(
          data: DraggableItemData(
            id: result.id,
            type: DraggableItemType.aiResult,
            label: result.title,
          ),
          child: _AiResultListItem(result: result),
        ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
      },
    );
  }

  Widget _buildDraggable({
    required DraggableItemData data,
    required Widget child,
  }) {
    return LongPressDraggable<DraggableItemData>(
      data: data,
      delay: const Duration(milliseconds: 300),
      feedback: _DragFeedback(label: data.label),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}

// ─── Folder Grid Item ────────────────────────────────────

class _FolderGridItem extends StatelessWidget {
  final FolderModel folder;

  const _FolderGridItem({required this.folder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.coverGradients[
        folder.colorIndex % AppColors.coverGradients.length];

    return DragTarget<DraggableItemData>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        // Don't accept dropping a folder onto itself
        if (data.type == DraggableItemType.folder && data.id == folder.id) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        context.read<FolderExplorerBloc>().add(
              MoveItemToFolder(
                itemId: details.data.id,
                targetFolderId: folder.id,
                itemType: details.data.type,
              ),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${details.data.label} → ${folder.name} taşındı'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => context.read<FolderExplorerBloc>().add(
                NavigateToFolder(folderId: folder.id, folderName: folder.name),
              ),
          onLongPress: () => _showFolderOptions(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: isHovering
                  ? Border.all(color: AppColors.primary, width: 2.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isHovering
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: isHovering ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isHovering ? 72 : 64,
                  height: isHovering ? 72 : 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHovering
                          ? colors
                          : colors.map((c) => c.withValues(alpha: 0.15)).toList(),
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(
                    isHovering ? Icons.folder_open_rounded : Icons.folder_rounded,
                    color: isHovering ? Colors.white : colors.first,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    folder.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _formatDate(folder.updatedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFolderOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(folder.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showRenameDialog(context);
            },
            child: const Text('Yeniden Adlandır'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FolderExplorerBloc>().add(DeleteFolder(folder.id));
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

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Klasör Adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                context.read<FolderExplorerBloc>().add(
                      RenameFolder(folderId: folder.id, newName: name),
                    );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
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

// ─── AI Result Grid Item ─────────────────────────────────

class _AiResultGridItem extends StatelessWidget {
  final AiResultModel result;

  const _AiResultGridItem({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.aiResultViewer, extra: result);
      },
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  result.typeEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                result.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              result.typeLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    // Show delete option
  }
}

// ─── AI Result List Item ─────────────────────────────────

class _AiResultListItem extends StatelessWidget {
  final AiResultModel result;

  const _AiResultListItem({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () {
          context.push(AppRoutes.aiResultViewer, extra: result);
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Center(
            child: Text(
              result.typeEmoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        title: Text(
          result.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${result.typeLabel} • ${result.sourceFileName ?? ''}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showOptions(context),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    // Show delete option
  }
}

// ─── Notebook Grid Item ──────────────────────────────────

class _NotebookGridItem extends StatelessWidget {
  final NotebookModel notebook;

  const _NotebookGridItem({required this.notebook});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.coverGradients[
        notebook.coverIndex % AppColors.coverGradients.length];

    return GestureDetector(
      onTap: () => context.push(AppRoutes.canvasPath(notebook.id)),
      onLongPress: () => _showNotebookOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
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
                    size: 32,
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${notebook.pageCount} sayfa',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
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

  void _showNotebookOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(notebook.name),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotebookBloc>().add(DeleteNotebook(notebook.id));
              // Also reload folder contents so it disappears from UI
              context.read<FolderExplorerBloc>().add(const LoadFolderContents());
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

// ─── File Grid Item ──────────────────────────────────────

class _FileGridItem extends StatelessWidget {
  final ImportedFile file;

  const _FileGridItem({required this.file});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.documentViewer, extra: file);
      },
      onLongPress: () => _showFileOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getFileColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(_getFileIcon(), color: _getFileColor(), size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                file.fileName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              file.formattedSize,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showFileOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(file.fileName),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.documentAnalysis);
            },
            child: const Text('AI ile Analiz Et'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FolderExplorerBloc>().add(DeleteFile(file.id));
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

  IconData _getFileIcon() {
    switch (file.fileType) {
      case FileType.pdf:
        return Icons.picture_as_pdf_rounded;
      case FileType.image:
        return Icons.image_rounded;
      case FileType.audio:
        return Icons.audiotrack_rounded;
      case FileType.unknown:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor() {
    switch (file.fileType) {
      case FileType.pdf:
        return AppColors.error;
      case FileType.image:
        return AppColors.secondary;
      case FileType.audio:
        return AppColors.accent;
      case FileType.unknown:
        return AppColors.info;
    }
  }
}

// ─── Folder List Item ────────────────────────────────────

class _FolderListItem extends StatelessWidget {
  final FolderModel folder;

  const _FolderListItem({required this.folder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.coverGradients[
        folder.colorIndex % AppColors.coverGradients.length];

    return DragTarget<DraggableItemData>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data.type == DraggableItemType.folder && data.id == folder.id) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        context.read<FolderExplorerBloc>().add(
              MoveItemToFolder(
                itemId: details.data.id,
                targetFolderId: folder.id,
                itemType: details.data.type,
              ),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${details.data.label} → ${folder.name} taşındı'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: isHovering
                ? Border.all(color: AppColors.primary, width: 2.5)
                : null,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              onTap: () => context.read<FolderExplorerBloc>().add(
                    NavigateToFolder(folderId: folder.id, folderName: folder.name),
                  ),
              onLongPress: () => _showFolderOptions(context),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  isHovering ? Icons.folder_open_rounded : Icons.folder_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              title: Text(folder.name, style: theme.textTheme.titleSmall),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        );
      },
    );
  }

  void _showFolderOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(folder.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showRenameDialog(context);
            },
            child: const Text('Yeniden Adlandır'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FolderExplorerBloc>().add(DeleteFolder(folder.id));
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

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Klasör Adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                context.read<FolderExplorerBloc>().add(
                      RenameFolder(folderId: folder.id, newName: name),
                    );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

// ─── Notebook List Item ──────────────────────────────────

class _NotebookListItem extends StatelessWidget {
  final NotebookModel notebook;

  const _NotebookListItem({required this.notebook});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.coverGradients[
        notebook.coverIndex % AppColors.coverGradients.length];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => context.push(AppRoutes.canvasPath(notebook.id)),
        onLongPress: () => _showNotebookOptions(context),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(Icons.menu_book_rounded,
              color: Colors.white, size: 22),
        ),
        title: Text(notebook.name, style: theme.textTheme.titleSmall),
        subtitle: Text('${notebook.pageCount} sayfa'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  void _showNotebookOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(notebook.name),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotebookBloc>().add(DeleteNotebook(notebook.id));
              context.read<FolderExplorerBloc>().add(const LoadFolderContents());
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

// ─── File List Item ──────────────────────────────────────

class _FileListItem extends StatelessWidget {
  final ImportedFile file;

  const _FileListItem({required this.file});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () {
          context.push(AppRoutes.documentViewer, extra: file);
        },
        onLongPress: () => _showFileOptions(context),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getFileColor().withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(_getFileIcon(), color: _getFileColor(), size: 22),
        ),
        title: Text(
          file.fileName,
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(file.formattedSize),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  IconData _getFileIcon() {
    switch (file.fileType) {
      case FileType.pdf:
        return Icons.picture_as_pdf_rounded;
      case FileType.image:
        return Icons.image_rounded;
      case FileType.audio:
        return Icons.audiotrack_rounded;
      case FileType.unknown:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor() {
    switch (file.fileType) {
      case FileType.pdf:
        return AppColors.error;
      case FileType.image:
        return AppColors.secondary;
      case FileType.audio:
        return AppColors.accent;
      case FileType.unknown:
        return AppColors.info;
    }
  }

  void _showFileOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(file.fileName),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.documentAnalysis);
            },
            child: const Text('AI ile Analiz Et'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FolderExplorerBloc>().add(DeleteFile(file.id));
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

class AddMenuSheet extends StatelessWidget {
  final FolderExplorerState state;
  final VoidCallback onCreateFolder;
  final VoidCallback onImportFile;
  final VoidCallback onCreateNotebook;

  const AddMenuSheet({
    super.key,
    required this.state,
    required this.onCreateFolder,
    required this.onImportFile,
    required this.onCreateNotebook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInFolder = state is FolderExplorerLoaded && !(state as FolderExplorerLoaded).isRoot;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.create_new_folder_rounded,
                    color: AppColors.accent, size: 22),
              ),
              title: const Text('Yeni Klasör'),
              subtitle: const Text('Dosyalarınızı düzenlemek için klasör oluşturun'),
              onTap: onCreateFolder,
            ),
            if (isInFolder) ...[
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.upload_file_rounded,
                      color: AppColors.secondary, size: 22),
                ),
                title: const Text('Dosya Yükle'),
                subtitle: const Text('PDF, görsel veya belge ekleyin'),
                onTap: onImportFile,
              ),
            ],
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColors.primary, size: 22),
              ),
              title: const Text('Yeni Not Defteri'),
              subtitle: const Text('El yazısı ve çizim için not defteri'),
              onTap: onCreateNotebook,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Drag Feedback ───────────────────────────────────────

class _DragFeedback extends StatelessWidget {
  final String label;

  const _DragFeedback({required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      color: AppColors.primary,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        constraints: const BoxConstraints(maxWidth: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_indicator_rounded, color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
