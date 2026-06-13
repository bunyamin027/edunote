import 'package:flutter/material.dart';

import '../engine/pdf_tile_renderer.dart';
import '../engine/tile_cache.dart';
import '../engine/viewport_controller.dart';
import '../engine/coordinate_mapper.dart';
import '../engine/smart_invert.dart';
import '../../canvas/engine/drawing_engine.dart';
import '../../canvas/engine/input_handler.dart';
import 'pdf_page_layer.dart';
import 'annotation_canvas.dart';

/// Interactive PDF View with tiled rendering and annotation capabilities.
class TiledPdfView extends StatefulWidget {
  final String filePath;
  final DrawingEngine drawingEngine;
  final InputHandler inputHandler;
  final bool isDrawingMode;

  const TiledPdfView({
    super.key,
    required this.filePath,
    required this.drawingEngine,
    required this.inputHandler,
    this.isDrawingMode = false,
  });

  @override
  State<TiledPdfView> createState() => _TiledPdfViewState();
}

class _TiledPdfViewState extends State<TiledPdfView> {
  late final PdfTileRenderer _renderer;
  late final TileCache _cache;
  late final ViewportController _viewportController;
  late final SmartInvertFilter _smartInvert;
  
  bool _isLoading = true;
  int _pageCount = 0;
  final Map<int, Size> _pageSizes = {};
  
  // Layout metadata
  double _totalHeight = 0;
  final double _pageSpacing = 16.0;
  final List<double> _pageOffsets = [];

  @override
  void initState() {
    super.initState();
    _renderer = PdfTileRenderer();
    _cache = TileCache();
    _viewportController = ViewportController();
    _smartInvert = SmartInvertFilter();
    
    // For testing/demo, we can enable it based on system theme later
    // _smartInvert.setEnabled(true);
    
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final success = await _renderer.loadDocument(widget.filePath);
    if (!success) {
      // Handle error
      setState(() => _isLoading = false);
      return;
    }

    _pageCount = await _renderer.getPageCount();
    
    // Fetch all page sizes to calculate total scrollable area
    _totalHeight = 0;
    _pageOffsets.clear();
    
    for (int i = 0; i < _pageCount; i++) {
      final size = await _renderer.getPageSize(i) ?? const Size(800, 1100); // fallback
      _pageSizes[i] = size;
      _pageOffsets.add(_totalHeight);
      _totalHeight += size.height + _pageSpacing;
    }

    // Initialize viewport assuming maximum width among all pages
    double maxWidth = 0;
    for (final size in _pageSizes.values) {
      if (size.width > maxWidth) maxWidth = size.width;
    }
    
    // We will call initialize again in build once we know the screen viewport size
    _viewportController.initialize(Size.zero, Size(maxWidth, _totalHeight));
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _renderer.unloadDocument();
    _cache.dispose();
    _viewportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pageCount == 0) {
      return const Center(child: Text('Doküman yüklenemedi.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Ensure viewport controller knows the screen bounds
        if (_viewportController.visibleRect.isEmpty) {
          double maxWidth = 0;
          for (final size in _pageSizes.values) {
            if (size.width > maxWidth) maxWidth = size.width;
          }
          _viewportController.initialize(viewportSize, Size(maxWidth, _totalHeight));
        } else {
          _viewportController.updateViewportSize(viewportSize);
        }

        return InteractiveViewer(
          transformationController: _viewportController.transformController,
          constrained: false,
          minScale: _viewportController.minScale,
          maxScale: _viewportController.maxScale,
          panEnabled: !widget.isDrawingMode,
          scaleEnabled: true,
          // When isDrawingMode is true, panEnabled is false, so single-finger touches
          // are passed down to AnnotationCanvas for drawing. 2-finger pan/zoom still works.
          child: SizedBox(
            width: _viewportController.documentSize.width,
            height: _totalHeight,
            child: Stack(
              children: List.generate(_pageCount, (index) {
                final pageSize = _pageSizes[index]!;
                final pageOffset = _pageOffsets[index];
                final pageRect = Rect.fromLTWH(0, pageOffset, pageSize.width, pageSize.height);
                
                return Positioned(
                  top: pageOffset,
                  left: 0,
                  width: pageSize.width,
                  height: pageSize.height,
                  child: _buildPageContent(index, pageSize, pageRect),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageContent(int index, Size pageSize, Rect pageRect) {
    return ListenableBuilder(
      listenable: _viewportController.transformController,
      builder: (context, _) {
        final visibleRect = _viewportController.visibleRect;
        
        // If this page is completely outside the viewport, don't render it
        if (!visibleRect.overlaps(pageRect)) {
          return const SizedBox.shrink();
        }

        // Calculate the visible portion of THIS page relative to its own coordinate space (0,0)
        final localVisibleRect = visibleRect.translate(0, -pageRect.top).intersect(
          Offset.zero & pageSize
        );

        final coordinateMapper = CoordinateMapper(pdfPageSize: pageSize);

        return Stack(
          children: [
            // 1. PDF Render Layer (with optional Smart Invert)
            if (_smartInvert.isEnabled && _smartInvert.filter != null)
              ColorFiltered(
                colorFilter: _smartInvert.filter!,
                child: PdfPageLayer(
                  pageIndex: index,
                  pageSize: pageSize,
                  visibleRect: localVisibleRect,
                  scale: _viewportController.scale,
                  coordinateMapper: coordinateMapper,
                  renderer: _renderer,
                  cache: _cache,
                ),
              )
            else
              PdfPageLayer(
                pageIndex: index,
                pageSize: pageSize,
                visibleRect: localVisibleRect,
                scale: _viewportController.scale,
                coordinateMapper: coordinateMapper,
                renderer: _renderer,
                cache: _cache,
              ),
            
            // 2. Annotation Layer
            AnnotationCanvas(
              pageIndex: index,
              pageSize: pageSize,
              viewportController: _viewportController,
              coordinateMapper: coordinateMapper,
              drawingEngine: widget.drawingEngine,
              inputHandler: widget.inputHandler,
            ),
          ],
        );
      },
    );
  }
}
