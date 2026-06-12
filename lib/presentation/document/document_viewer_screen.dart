import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/config/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/imported_file_model.dart';
import '../../data/services/document_note_service.dart';
import '../canvas/engine/canvas_painter.dart';
import '../canvas/engine/drawing_engine.dart';
import '../canvas/engine/input_handler.dart';
import '../canvas/engine/stroke_style.dart';
import '../canvas/widgets/drawing_toolbar.dart';
import 'widgets/document_notes_panel.dart';

/// Document Viewer — Opens and displays PDF, image, and text files.
/// Supports annotation (drawing) overlay with full drawing tools.
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

  // Annotation state
  late final DrawingEngine _engine;
  late final InputHandler _inputHandler;
  late final DocumentNoteService _noteService;
  bool _annotationMode = false;
  bool _isDrawing = false;
  bool _isSaving = false;
  Timer? _autoSaveTimer;

  // For image/text annotation transform
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();

    _engine = DrawingEngine();
    _inputHandler = InputHandler();
    _noteService = sl<DocumentNoteService>();

    _engine.addListener(_onEngineChanged);

    // Load text file if applicable
    if (widget.file.fileType == FileType.unknown &&
        widget.file.extension == 'txt') {
      _loadTextFile();
    }

    // Load saved annotations for current page
    _loadAnnotations();
  }

  @override
  void dispose() {
    _saveAnnotations();
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _transformController.dispose();
    _autoSaveTimer?.cancel();
    _pdfController.dispose();
    super.dispose();
  }

  // ─── Annotation Persistence ────────────────────────────

  void _loadAnnotations() {
    final strokesData = _noteService.loadAnnotations(
      widget.file.id,
      _currentPage,
    );
    _engine.clearCanvas();
    if (strokesData.isNotEmpty) {
      _engine.loadStrokes(strokesData);
    }
  }

  Future<void> _saveAnnotations() async {
    if (_isSaving) return;
    _isSaving = true;
    try {
      final strokesData = _engine.exportStrokes();
      await _noteService.saveAnnotations(
        widget.file.id,
        _currentPage,
        strokesData,
      );
    } finally {
      _isSaving = false;
    }
  }

  void _onEngineChanged() {
    setState(() {});
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(milliseconds: 2000),
      _saveAnnotations,
    );
  }

  void _onPdfPageChanged(int newPage) {
    if (newPage == _currentPage) return;
    // Save current page annotations before switching
    _saveAnnotations();
    setState(() => _currentPage = newPage);
    _loadAnnotations();
  }

  Future<void> _loadTextFile() async {
    try {
      final content = await File(widget.file.localPath).readAsString();
      setState(() => _textContent = content);
    } catch (e) {
      setState(() => _textContent = 'Dosya okunamadı: $e');
    }
  }

  // ─── Build ─────────────────────────────────────────────

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
          // Annotation mode toggle
          IconButton(
            icon: Icon(
              _annotationMode
                  ? Icons.draw_rounded
                  : Icons.draw_outlined,
              color: _annotationMode ? AppColors.primary : null,
            ),
            tooltip: _annotationMode ? 'Çizimi Kapat' : 'Üzerine Çiz',
            onPressed: () {
              setState(() => _annotationMode = !_annotationMode);
              if (_annotationMode) {
                // Reset PDF zoom and scroll offset so annotations align
                _pdfController.zoomLevel = 1.0;
                _pdfController.jumpToPage(_currentPage);
              } else {
                _saveAnnotations();
              }
            },
          ),
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
            onPressed: () =>
                context.push(AppRoutes.documentAnalysis, extra: widget.file),
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
      body: Column(
        children: [
          // Annotation mode indicator
          if (_annotationMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              color: AppColors.primary,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.draw_rounded, color: Colors.white, size: 14),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Çizim Modu — Dosya üzerine çizim yapabilirsiniz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Main content area (viewer + annotation overlay)
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Document content
                AbsorbPointer(
                  absorbing: _annotationMode,
                  child: _buildViewer(theme, isDark),
                ),

                // Annotation overlay
                if (_annotationMode || _engine.strokeCount > 0)
                  _buildAnnotationLayer(isDark),
              ],
            ),
          ),
          
          // Drawing toolbar (bottom, only in annotation mode)
          if (_annotationMode)
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm),
              child: Center(
                child: ListenableBuilder(
                  listenable: _engine,
                  builder: (context, _) => DrawingToolbar(
                    engine: _engine,
                    canUndo: _engine.canUndo,
                    canRedo: _engine.canRedo,
                    onUndoTap: _engine.undo,
                    onRedoTap: _engine.redo,
                  ),
                ),
              ),
            ),
        ],
      ),
      // Page indicator for PDFs
      bottomNavigationBar:
          widget.file.fileType == FileType.pdf && _totalPages > 1
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

  // ─── Annotation Layer ──────────────────────────────────

  Widget _buildAnnotationLayer(bool isDark) {
    return IgnorePointer(
      ignoring: !_annotationMode,
      child: GestureDetector(
        onPanDown: _annotationMode ? (_) {} : null,
        child: Listener(
          behavior: _annotationMode
              ? HitTestBehavior.opaque
              : HitTestBehavior.translucent,
          onPointerDown: _annotationMode ? _onPointerDown : null,
          onPointerMove: _annotationMode ? _onPointerMove : null,
          onPointerUp: _annotationMode ? _onPointerUp : null,
          onPointerCancel: _annotationMode ? _onPointerCancel : null,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: CanvasPainter(
                strokes: _engine.strokes,
                activeStroke: _engine.activeStroke,
                backgroundColor: Colors.transparent,
                paperPattern: PaperPattern.blank,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Pointer Events ────────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    if (!_inputHandler.shouldDraw(event)) return;

    if (_inputHandler.isEraserEnd(event)) {
      _engine.setToolType(ToolType.eraser);
    }

    _engine.startStroke(
      event.localPosition.dx,
      event.localPosition.dy,
      pressure: _inputHandler.getPressure(event),
      tilt: _inputHandler.getTilt(event),
    );

    setState(() => _isDrawing = true);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDrawing) return;
    if (!_inputHandler.shouldDraw(event)) return;

    _engine.addPoint(
      event.localPosition.dx,
      event.localPosition.dy,
      pressure: _inputHandler.getPressure(event),
      tilt: _inputHandler.getTilt(event),
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    _inputHandler.shouldDraw(event);
    if (_isDrawing) {
      _engine.endStroke();
      setState(() => _isDrawing = false);
    }
    _inputHandler.reset();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _inputHandler.shouldDraw(event);
    _engine.cancelStroke();
    setState(() => _isDrawing = false);
    _inputHandler.reset();
  }

  // ─── Viewer Types ──────────────────────────────────────

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

  Widget _buildPdfViewer(ThemeData theme) {
    final file = File(widget.file.localPath);

    if (!file.existsSync()) {
      return _buildFileNotFound(theme);
    }

    final fileSizeInMB = file.lengthSync() / (1024 * 1024);
    debugPrint('[PDF] Loading file: ${widget.file.fileName}, Size: ${fileSizeInMB.toStringAsFixed(2)} MB');

    return Stack(
      fit: StackFit.expand,
      children: [
        SfPdfViewer.file(
          file,
          key: ValueKey(widget.file.id),
          controller: _pdfController,
          canShowScrollHead: true,
          canShowPaginationDialog: true,
          enableDoubleTapZooming: false,
          onDocumentLoaded: (details) {
            debugPrint('[PDF] Document loaded successfully. Pages: ${details.document.pages.count}');
            setState(() {
              _totalPages = details.document.pages.count;
            });
          },
          onDocumentLoadFailed: (details) {
            debugPrint('[PDF] Load Failed: ${details.error} - ${details.description}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF yüklenemedi: ${details.error}'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 10),
                ),
              );
            }
          },
          onPageChanged: (details) {
            _onPdfPageChanged(details.newPageNumber);
          },
        ),
        if (_totalPages == 0) // Show a custom loading indicator while parsing
          Container(
            color: theme.scaffoldBackgroundColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Büyük dosya işleniyor...\nLütfen bekleyin (${fileSizeInMB.toStringAsFixed(1)} MB)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── Image Viewer ──────────────────────────────────────

  Widget _buildImageViewer(ThemeData theme) {
    final file = File(widget.file.localPath);

    if (!file.existsSync()) {
      return _buildFileNotFound(theme);
    }

    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 5.0,
      panEnabled: !_annotationMode,
      scaleEnabled: !_annotationMode,
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
      physics: _annotationMode
          ? const NeverScrollableScrollPhysics()
          : null,
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
