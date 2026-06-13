import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_constants.dart';
import '../../core/config/injection.dart';
import '../../data/models/imported_file_model.dart';
import '../../data/services/canvas_storage_service.dart';
import '../canvas/engine/drawing_engine.dart';
import '../canvas/engine/input_handler.dart';
import '../canvas/engine/page_model.dart';
import '../canvas/engine/stroke_style.dart';
import '../canvas/widgets/draggable_toolbar.dart';
import 'widgets/tiled_pdf_view.dart';
import '../canvas/widgets/drawing_toolbar.dart';

/// The main screen for viewing and annotating a PDF document.
/// Replaces the old `document_viewer_screen.dart` which used Syncfusion.
class PdfDocumentScreen extends StatefulWidget {
  final ImportedFile file;

  const PdfDocumentScreen({super.key, required this.file});

  @override
  State<PdfDocumentScreen> createState() => _PdfDocumentScreenState();
}

class _PdfDocumentScreenState extends State<PdfDocumentScreen> {
  late final DrawingEngine _drawingEngine;
  late final InputHandler _inputHandler = InputHandler();
  late final CanvasStorageService _storage;
  
  bool _isToolbarVisible = true;
  Axis _toolbarAxis = Axis.horizontal;
  
  List<PageModel> _pages = [];
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _drawingEngine = DrawingEngine();
    _storage = sl<CanvasStorageService>();
    
    _drawingEngine.addListener(_onEngineChanged);
    _loadPages();
  }

  void _loadPages() {
    // We use the PDF's unique file ID as the "notebookId" for storing strokes
    _pages = _storage.loadPages(widget.file.id);
    
    // In PdfDocumentScreen, we don't have a single "currentPageIndex" that we flip through.
    // TiledPdfView renders all pages in a scrollable list.
    // But DrawingEngine is designed to handle multiple pages.
    // We can load all strokes into DrawingEngine.
    for (int i = 0; i < _pages.length; i++) {
      if (_pages[i].strokesData.isNotEmpty) {
        _drawingEngine.loadStrokes(i, _pages[i].strokesData);
      }
    }
  }

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
    // The DrawingEngine contains strokes for all pages.
    // We need to convert them back to PageModels and save.
    
    // In a PDF, we might not know the exact total page count easily right here,
    // but we can just save the pages that have strokes.
    // Wait, TiledPdfView manages the actual PDF pages.
    // The easiest way is to extract strokes from drawing engine and update the loaded _pages.
    
    final maxPageIndex = _drawingEngine.currentPageIndex > _pages.length - 1 
        ? _drawingEngine.currentPageIndex 
        : _pages.length - 1;
        
    final List<PageModel> pagesToSave = [];
    
    for (int i = 0; i <= maxPageIndex; i++) {
      final strokesData = _drawingEngine.exportStrokes(i);
      
      // If we already had a PageModel, update it. Otherwise create a new one.
      if (i < _pages.length) {
        pagesToSave.add(_pages[i].copyWith(strokesData: strokesData));
      } else {
        final now = DateTime.now();
        pagesToSave.add(PageModel(
          id: '${widget.file.id}_page_$i',
          pageNumber: i + 1,
          strokesData: strokesData,
          paperPatternIndex: 0,
          createdAt: now,
          updatedAt: now,
        ));
      }
    }
    
    _pages = pagesToSave;
    _storage.savePages(widget.file.id, _pages);
  }

  @override
  void dispose() {
    _performAutoSave();
    _autoSaveTimer?.cancel();
    _drawingEngine.removeListener(_onEngineChanged);
    _drawingEngine.dispose();
    super.dispose();
  }

  void _toggleToolbar() {
    setState(() {
      _isToolbarVisible = !_isToolbarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceDim,
      appBar: AppBar(
        title: Text(widget.file.fileName),
        actions: [
          IconButton(
            icon: Icon(
              _isToolbarVisible ? Icons.edit_off : Icons.edit,
            ),
            onPressed: _toggleToolbar,
            tooltip: 'Araç Çubuğunu Gizle/Göster',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Trigger ExportService
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. The Tiled PDF View
          ListenableBuilder(
            listenable: _drawingEngine,
            builder: (context, _) {
              final isPanTool = _drawingEngine.currentStyle.toolType == ToolType.pan;
              return TiledPdfView(
                filePath: widget.file.localPath,
                drawingEngine: _drawingEngine,
                inputHandler: _inputHandler,
                isDrawingMode: _isToolbarVisible && !isPanTool,
              );
            },
          ),
          
          // 2. Toolbar
          if (_isToolbarVisible)
            DraggableToolbar(
              initialPosition: Offset(
                MediaQuery.of(context).size.width / 2 - 180,
                16,
              ),
              initialAxis: _toolbarAxis,
              onAxisChanged: (axis) => setState(() => _toolbarAxis = axis),
              child: ListenableBuilder(
                listenable: _drawingEngine,
                builder: (context, _) {
                  return DrawingToolbar(
                    engine: _drawingEngine,
                    canUndo: _drawingEngine.canUndo,
                    canRedo: _drawingEngine.canRedo,
                    onUndoTap: () => _drawingEngine.undo(),
                    onRedoTap: () => _drawingEngine.redo(),
                    axis: _toolbarAxis,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
