import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_constants.dart';
import '../../core/config/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/services/canvas_storage_service.dart';
import '../../data/services/canvas_export_service.dart';
import 'engine/canvas_painter.dart';
import 'engine/drawing_engine.dart';
import 'engine/input_handler.dart';
import 'engine/page_model.dart';
import 'engine/stroke.dart';
import 'engine/stroke_style.dart';
import 'engine/text_element.dart';
import 'widgets/drawing_toolbar.dart';
import 'widgets/export_sheet.dart';
import 'widgets/page_navigator.dart';
import 'widgets/text_layer_overlay.dart';

/// Full-screen canvas for drawing and note-taking.
///
/// Integrates DrawingEngine, multi-page support, text layer,
/// Hive persistence, and all toolbar controls.
class CanvasScreen extends StatefulWidget {
  final String notebookId;

  const CanvasScreen({super.key, required this.notebookId});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with TickerProviderStateMixin {
  late final DrawingEngine _engine;
  late final InputHandler _inputHandler;
  late final CanvasStorageService _storage;
  final CanvasExportService _exportService = CanvasExportService();

  // Multi-page state
  List<PageModel> _pages = [];
  int _currentPageIndex = 0;

  // Text layer
  List<TextElement> _textElements = [];
  bool _isTextMode = false;

  // Zoom & Pan
  final TransformationController _transformController =
      TransformationController();
  bool _isPanning = false;

  // UI state
  final bool _showToolbar = true;
  bool _showPageNav = false;
  bool _isDrawing = false;
  bool _isSaving = false;

  // Auto-save timer
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _engine = DrawingEngine();
    _inputHandler = InputHandler();
    _storage = sl<CanvasStorageService>();

    _engine.addListener(_onEngineChanged);

    // Load pages
    _loadPages();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Save current page before leaving
    _saveCurrentPage();

    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _transformController.dispose();
    _autoSaveTimer?.cancel();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─── Data Loading ───────────────────────────────────

  void _loadPages() {
    _pages = _storage.loadPages(widget.notebookId);
    _loadPageIntoEngine(0);
    setState(() {});
  }

  void _loadPageIntoEngine(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pages.length) return;

    // Save current page first
    if (_currentPageIndex != pageIndex && _pages.isNotEmpty) {
      _saveCurrentPage();
    }

    final page = _pages[pageIndex];
    _currentPageIndex = pageIndex;

    // Load strokes
    _engine.clearCanvas();
    if (page.strokesData.isNotEmpty) {
      _engine.loadStrokes(page.strokesData);
    }

    // Load paper pattern
    _engine.setPaperPattern(page.paperPattern);

    // Load text elements
    _textElements = page.textElementsData
        .map((d) => TextElement.fromJson(d))
        .toList();

    // Reset transform
    _transformController.value = Matrix4.identity();

    setState(() {});
  }

  // ─── Saving ─────────────────────────────────────────

  void _onEngineChanged() {
    setState(() {});
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(milliseconds: AppConstants.autoSaveIntervalMs),
      _performAutoSave,
    );
  }

  Future<void> _performAutoSave() async {
    await _saveCurrentPage();
  }

  Future<void> _saveCurrentPage() async {
    if (_pages.isEmpty || _currentPageIndex >= _pages.length) return;
    if (_isSaving) return;

    _isSaving = true;

    try {
      final page = _pages[_currentPageIndex].copyWith(
        strokesData: _engine.exportStrokes(),
        textElementsData: _textElements.map((t) => t.toJson()).toList(),
        paperPatternIndex: _engine.paperPattern.index,
        updatedAt: DateTime.now(),
      );

      _pages[_currentPageIndex] = page;
      await _storage.savePage(widget.notebookId, page);
    } finally {
      _isSaving = false;
    }
  }

  // ─── Page Management ────────────────────────────────

  Future<void> _addPage() async {
    await _saveCurrentPage();
    final newPage = await _storage.addPage(widget.notebookId);
    _pages.add(newPage);
    _loadPageIntoEngine(_pages.length - 1);
  }

  Future<void> _deletePage(int index) async {
    if (_pages.length <= 1) return;

    final pageId = _pages[index].id;
    await _storage.deletePage(widget.notebookId, pageId);
    _pages.removeAt(index);

    // Re-number
    for (int i = 0; i < _pages.length; i++) {
      _pages[i] = _pages[i].copyWith(pageNumber: i + 1);
    }

    final newIndex = index.clamp(0, _pages.length - 1);
    _loadPageIntoEngine(newIndex);
  }

  // ─── Build ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Stack(
        children: [
          // Canvas surface
          Positioned.fill(
            child: _buildCanvasSurface(),
          ),

          // Text layer overlay
          if (_isTextMode || _textElements.isNotEmpty)
            Positioned.fill(
              child: TextLayerOverlay(
                textElements: _textElements,
                onTextElementsChanged: (elements) {
                  setState(() => _textElements = elements);
                  _scheduleAutoSave();
                },
                isTextMode: _isTextMode,
                transform: _transformController.value,
              ),
            ),

          // Top bar
          if (_showToolbar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(theme, isDark),
            ),

          // Bottom toolbar
          if (_showToolbar)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
              left: 0,
              right: _showPageNav ? 80 : 0,
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

          // Page navigator (right side)
          if (_showPageNav)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              bottom: MediaQuery.of(context).padding.bottom + 8,
              right: 4,
              child: PageNavigator(
                pages: _pages,
                currentPageIndex: _currentPageIndex,
                onPageSelected: (index) => _loadPageIntoEngine(index),
                onAddPage: _addPage,
                onDeletePage: _deletePage,
              ),
            ),

          // Stylus indicator
          if (_inputHandler.isStylusActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              right: _showPageNav ? 84 : AppSpacing.lg,
              child: _StylusIndicator(),
            ),

          // Text mode indicator
          if (_isTextMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: AppSpacing.lg,
              child: _ModeIndicator(
                icon: Icons.text_fields_rounded,
                label: 'Metin Modu',
                color: AppColors.accent,
              ),
            ),

          // Page counter
          if (_pages.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom +
                  (_showToolbar ? 64 : AppSpacing.lg),
              right: _showPageNav ? 84 : AppSpacing.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                ),
                child: Text(
                  '${_currentPageIndex + 1} / ${_pages.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Canvas Surface ─────────────────────────────────
  Widget _buildCanvasSurface() {
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 5.0,
      panEnabled: _isPanning || _isTextMode,
      scaleEnabled: true,
      onInteractionStart: (details) {
        if (details.pointerCount >= 2) {
          setState(() => _isPanning = true);
        }
      },
      onInteractionEnd: (details) {
        setState(() => _isPanning = false);
      },
      child: SizedBox(
        width: 2480,
        height: 3508,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _isTextMode ? null : _onPointerDown,
          onPointerMove: _isTextMode ? null : _onPointerMove,
          onPointerUp: _isTextMode ? null : _onPointerUp,
          onPointerCancel: _isTextMode ? null : _onPointerCancel,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: CanvasPainter(
                strokes: _engine.strokes,
                activeStroke: _engine.activeStroke,
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                paperPattern: _engine.paperPattern,
              ),
              size: const Size(2480, 3508),
            ),
          ),
        ),
      ),
    );
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // ─── Top Bar ────────────────────────────────────────
  Widget _buildTopBar(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.backgroundDark : Colors.white)
                .withValues(alpha: 0.95),
            (isDark ? AppColors.backgroundDark : Colors.white)
                .withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          _TopBarButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              _saveCurrentPage();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Text(
              'Not Defteri',
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Text mode toggle
          _TopBarButton(
            icon: _isTextMode
                ? Icons.text_fields_rounded
                : Icons.text_fields_outlined,
            isActive: _isTextMode,
            onTap: () => setState(() => _isTextMode = !_isTextMode),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Paper pattern
          _TopBarButton(
            icon: Icons.grid_4x4_rounded,
            onTap: _showPaperPatternPicker,
          ),
          const SizedBox(width: AppSpacing.xs),

          // Pages toggle
          _TopBarButton(
            icon: Icons.layers_rounded,
            isActive: _showPageNav,
            onTap: () => setState(() => _showPageNav = !_showPageNav),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Clear canvas
          _TopBarButton(
            icon: Icons.delete_sweep_rounded,
            onTap: _showClearConfirmation,
          ),
          const SizedBox(width: AppSpacing.xs),

          // Export
          _TopBarButton(
            icon: Icons.ios_share_rounded,
            onTap: _showExportSheet,
          ),
        ],
      ),
    );
  }

  // ─── Pointer Events ─────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    if (_isPanning) return;
    if (!_inputHandler.shouldDraw(event)) return;

    if (_inputHandler.isEraserEnd(event)) {
      _engine.setToolType(ToolType.eraser);
    }

    final localPosition = _getCanvasPosition(event.localPosition);
    final pressure = _inputHandler.getPressure(event);
    final tilt = _inputHandler.getTilt(event);

    _engine.startStroke(
      localPosition.dx,
      localPosition.dy,
      pressure: pressure,
      tilt: tilt,
    );

    setState(() => _isDrawing = true);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDrawing || _isPanning) return;
    if (!_inputHandler.shouldDraw(event)) return;

    final localPosition = _getCanvasPosition(event.localPosition);
    final pressure = _inputHandler.getPressure(event);
    final tilt = _inputHandler.getTilt(event);

    _engine.addPoint(
      localPosition.dx,
      localPosition.dy,
      pressure: pressure,
      tilt: tilt,
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

  Offset _getCanvasPosition(Offset localPosition) {
    final matrix = _transformController.value;
    final inverse = Matrix4.inverted(matrix);
    final result = MatrixUtils.transformPoint(inverse, localPosition);
    return result;
  }

  // ─── Dialogs ────────────────────────────────────────

  void _showPaperPatternPicker() {
    final patterns = [
      ('Boş', PaperPattern.blank, Icons.crop_square_rounded),
      ('Çizgili', PaperPattern.lined, Icons.format_line_spacing_rounded),
      ('Kareli', PaperPattern.grid, Icons.grid_4x4_rounded),
      ('Noktalı', PaperPattern.dotted, Icons.grain_rounded),
      ('İzometrik', PaperPattern.isometric, Icons.change_history_rounded),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXxl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusRound),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Kağıt Şablonu', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: patterns.map((p) {
                  final isSelected = _engine.paperPattern == p.$2;
                  return GestureDetector(
                    onTap: () {
                      _engine.setPaperPattern(p.$2);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: AppSpacing.animFast,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primarySurface
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : theme.colorScheme.outline,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            p.$3,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            p.$1,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tuvali Temizle'),
        content: const Text(
          'Tüm çizimler ve metinler silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              _engine.clearCanvas();
              setState(() => _textElements.clear());
              _scheduleAutoSave();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  // ─── Export ──────────────────────────────────────────

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportSheet(
        totalPages: _pages.length,
        currentPage: _currentPageIndex,
        onExportCurrentPng: _exportCurrentPagePng,
        onExportAllPng: _exportAllPagesPng,
        onExportPdf: _exportPdf,
      ),
    );
  }

  Future<void> _exportCurrentPagePng() async {
    await _saveCurrentPage();

    _showSnackBar('PNG oluşturuluyor...');

    final png = await _exportService.exportAsPng(
      strokes: _engine.strokes,
      paperPattern: _engine.paperPattern,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    );

    if (png != null) {
      _showSnackBar('✅ PNG başarıyla oluşturuldu (${(png.length / 1024).toStringAsFixed(0)} KB)');
      
      final xFile = XFile.fromData(
        png,
        mimeType: 'image/png',
        name: 'defter_sayfa_${_currentPageIndex + 1}.png',
      );
      await Share.shareXFiles([xFile], subject: 'Çizim Defteri');
    } else {
      _showSnackBar('❌ PNG oluşturulurken hata oluştu');
    }
  }

  Future<void> _exportAllPagesPng() async {
    await _saveCurrentPage();

    _showSnackBar('Tüm sayfalar dışa aktarılıyor...');

    final allStrokes = <List<Stroke>>[];
    final allPatterns = <PaperPattern>[];

    for (final page in _pages) {
      final strokes = page.strokesData
          .map((d) => Stroke.fromJson(d))
          .toList();
      allStrokes.add(strokes);
      allPatterns.add(page.paperPattern);
    }

    final pngs = await _exportService.exportAllPagesAsPng(
      pagesStrokes: allStrokes,
      pagesPatterns: allPatterns,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    );

    _showSnackBar('✅ ${pngs.length} sayfa başarıyla dışa aktarıldı');
    
    final xFiles = <XFile>[];
    for (int i = 0; i < pngs.length; i++) {
      xFiles.add(
        XFile.fromData(
          pngs[i],
          mimeType: 'image/png',
          name: 'defter_sayfa_${i + 1}.png',
        ),
      );
    }
    
    await Share.shareXFiles(xFiles, subject: 'Çizim Defteri (Tüm Sayfalar)');
  }

  Future<void> _exportPdf() async {
    await _saveCurrentPage();
    _showSnackBar('PDF desteği yakında eklenecek (pdf paketi ile)');
    // TODO: Use 'pdf' package to generate actual PDF from PNG pages
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

// ─── Helper Widgets ─────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                  .withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive
              ? AppColors.primary
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _StylusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            'Kalem',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ModeIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ModeIndicator({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
