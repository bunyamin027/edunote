import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/config/injection.dart';
import '../../bloc/file/file_bloc.dart';
import '../../bloc/file/file_event.dart';
import '../../bloc/file/file_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/imported_file_model.dart';
import '../../data/services/file_import_service.dart';

/// Screen showing imported files for a notebook with import options.
class FilesScreen extends StatelessWidget {
  final String notebookId;

  const FilesScreen({super.key, required this.notebookId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FileBloc(sl<FileImportService>())
        ..add(LoadFiles(notebookId)),
      child: _FilesView(notebookId: notebookId),
    );
  }
}

class _FilesView extends StatelessWidget {
  final String notebookId;

  const _FilesView({required this.notebookId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar.large(
            title: const Text('Dosyalar'),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => _showHelpDialog(context),
              ),
            ],
          ),

          // Import buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _ImportButtons(notebookId: notebookId),
            ),
          ),

          // File list
          BlocConsumer<FileBloc, FileState>(
            listener: (context, state) {
              if (state is FileImportSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${state.importedFile.fileName} eklendi'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                );
              }
              if (state is FileError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ ${state.message}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              final files = _extractFiles(state);

              if (state is FileLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (files.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyFilesView(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList.separated(
                  itemCount: files.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return _FileCard(
                      file: file,
                      onTap: () => _openFile(context, file),
                      onDelete: () => _confirmDelete(context, file),
                    ).animate().fadeIn(
                          duration: 200.ms,
                          delay: (index * 40).ms,
                        );
                  },
                ),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxxl),
          ),
        ],
      ),
    );
  }

  List<ImportedFile> _extractFiles(FileState state) {
    if (state is FileLoaded) return state.files;
    if (state is FileImportSuccess) return state.allFiles;
    if (state is FileImporting) return state.existingFiles;
    if (state is FileError) return state.existingFiles;
    return [];
  }

  void _openFile(BuildContext context, ImportedFile file) {
    OpenFilex.open(file.localPath);
  }

  void _confirmDelete(BuildContext context, ImportedFile file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dosyayı Sil'),
        content: Text('${file.fileName} silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              context.read<FileBloc>().add(
                    DeleteFile(fileId: file.id, notebookId: notebookId),
                  );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dosya Yönetimi'),
        content: const Text(
          'PDF, görsel veya ses dosyalarını not defterinize ekleyebilirsiniz.\n\n'
          '• PDF: Ders notları, kitap sayfaları\n'
          '• Görsel: Fotoğraflar, diyagramlar\n'
          '• Ses: Ders kayıtları, podcast\n\n'
          'Dosyalar cihazınızda güvenle saklanır.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}

// ─── Import Buttons ─────────────────────────────────────

class _ImportButtons extends StatelessWidget {
  final String notebookId;

  const _ImportButtons({required this.notebookId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ImportButton(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            color: AppColors.error,
            onTap: () => context.read<FileBloc>().add(ImportPdf(notebookId)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ImportButton(
            icon: Icons.image_rounded,
            label: 'Görsel',
            color: AppColors.primary,
            onTap: () => context.read<FileBloc>().add(ImportImage(notebookId)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ImportButton(
            icon: Icons.audiotrack_rounded,
            label: 'Ses',
            color: AppColors.accent,
            onTap: () => context.read<FileBloc>().add(ImportAudio(notebookId)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ImportButton(
            icon: Icons.attach_file_rounded,
            label: 'Dosya',
            color: AppColors.secondary,
            onTap: () =>
                context.read<FileBloc>().add(ImportAnyFile(notebookId)),
          ),
        ),
      ],
    );
  }
}

class _ImportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── File Card ──────────────────────────────────────────

class _FileCard extends StatelessWidget {
  final ImportedFile file;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FileCard({
    required this.file,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Row(
          children: [
            // File icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getFileColor(file.fileType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                _getFileIcon(file.fileType),
                color: _getFileColor(file.fileType),
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Text(
                        file.formattedSize,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '•',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        file.extension.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getFileColor(file.fileType),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
              onPressed: onDelete,
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(FileType type) {
    switch (type) {
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

  Color _getFileColor(FileType type) {
    switch (type) {
      case FileType.pdf:
        return AppColors.error;
      case FileType.image:
        return AppColors.primary;
      case FileType.audio:
        return AppColors.accent;
      case FileType.unknown:
        return AppColors.secondary;
    }
  }
}

// ─── Empty State ────────────────────────────────────────

class _EmptyFilesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Henüz dosya yok',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'PDF, görsel veya ses dosyalarını\nyukarıdaki butonlarla ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}
