import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/imported_file_model.dart';
import 'widgets/document_notes_panel.dart';

/// Document Viewer — Opens and displays PDF, image, and text files.
/// Provides read access with AI integration entry points.
class DocumentViewerScreen extends StatefulWidget {
  final ImportedFile file;

  const DocumentViewerScreen({super.key, required this.file});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  String? _textContent;

  @override
  void initState() {
    super.initState();
    if (widget.file.fileType == FileType.unknown &&
        widget.file.extension == 'txt') {
      _loadTextFile();
    }
  }

  Future<void> _loadTextFile() async {
    try {
      final content = await File(widget.file.localPath).readAsString();
      setState(() => _textContent = content);
    } catch (e) {
      setState(() => _textContent = 'Dosya okunamadı: $e');
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.file.fileName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Notes button
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Notlar',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          // AI Analysis button
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'AI ile Analiz Et',
            onPressed: () => context.push(AppRoutes.documentAnalysis, extra: widget.file),
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Paylaş',
            onPressed: () => _shareFile(),
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'info') _showFileInfo(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Dosya Bilgileri'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      endDrawer: const DocumentNotesPanel(),
      body: _buildViewer(theme, isDark),
      // Page indicator for PDFs
      bottomNavigationBar: widget.file.fileType == FileType.pdf && _totalPages > 1
          ? _PdfPageBar(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) {
                _pdfController.jumpToPage(page);
              },
            )
          : null,
    );
  }

  Widget _buildViewer(ThemeData theme, bool isDark) {
    switch (widget.file.fileType) {
      case FileType.pdf:
        return _buildPdfViewer(theme);
      case FileType.image:
        return _buildImageViewer(theme);
      default:
        if (widget.file.extension == 'txt') {
          return _buildTextViewer(theme);
        }
        return _buildUnsupportedViewer(theme);
    }
  }

  // ─── PDF Viewer ────────────────────────────────────────

  Widget _buildPdfViewer(ThemeData theme) {
    final file = File(widget.file.localPath);

    if (!file.existsSync()) {
      return _buildFileNotFound(theme);
    }

    return SfPdfViewer.file(
      file,
      controller: _pdfController,
      canShowScrollHead: true,
      canShowPaginationDialog: true,
      enableDoubleTapZooming: true,
      onDocumentLoaded: (details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
      onPageChanged: (details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
    );
  }

  // ─── Image Viewer ──────────────────────────────────────

  Widget _buildImageViewer(ThemeData theme) {
    final file = File(widget.file.localPath);

    if (!file.existsSync()) {
      return _buildFileNotFound(theme);
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildFileNotFound(theme);
          },
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Text Viewer ───────────────────────────────────────

  Widget _buildTextViewer(ThemeData theme) {
    if (_textContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: SelectableText(
        _textContent!,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.8,
          fontFamily: 'monospace',
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Unsupported Viewer ────────────────────────────────

  Widget _buildUnsupportedViewer(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            child: const Icon(
              Icons.insert_drive_file_rounded,
              color: AppColors.accent,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Bu dosya türü henüz desteklenmiyor',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.file.fileName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton.icon(
            onPressed: () => _shareFile(),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Başka Uygulamada Aç'),
          ),
        ],
      ),
    );
  }

  // ─── File Not Found ────────────────────────────────────

  Widget _buildFileNotFound(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Dosya bulunamadı',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Dosya taşınmış veya silinmiş olabilir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────

  Future<void> _shareFile() async {
    try {
      final file = XFile(widget.file.localPath);
      await Share.shareXFiles([file], subject: widget.file.fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paylaşım hatası: $e')),
        );
      }
    }
  }

  void _showFileInfo(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Dosya Bilgileri',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InfoRow(label: 'Dosya Adı', value: widget.file.fileName),
              _InfoRow(label: 'Boyut', value: widget.file.formattedSize),
              _InfoRow(
                  label: 'Tür',
                  value: widget.file.mimeType),
              _InfoRow(
                label: 'Eklenme Tarihi',
                value:
                    '${widget.file.createdAt.day}.${widget.file.createdAt.month}.${widget.file.createdAt.year} '
                    '${widget.file.createdAt.hour}:${widget.file.createdAt.minute.toString().padLeft(2, '0')}',
              ),
              if (_totalPages > 0)
                _InfoRow(label: 'Sayfa Sayısı', value: '$_totalPages'),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PDF Page Bar ────────────────────────────────────────

class _PdfPageBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PdfPageBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePaddingHorizontal,
        right: AppSpacing.pagePaddingHorizontal,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.navigate_before_rounded),
            onPressed:
                currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primarySurface,
                thumbColor: AppColors.primary,
                trackHeight: 3,
              ),
              child: Slider(
                value: currentPage.toDouble(),
                min: 1,
                max: totalPages.toDouble(),
                divisions: totalPages > 1 ? totalPages - 1 : 1,
                onChanged: (value) => onPageChanged(value.toInt()),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next_rounded),
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
