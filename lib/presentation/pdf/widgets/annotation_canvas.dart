import 'package:flutter/material.dart';

import '../engine/coordinate_mapper.dart';
import '../engine/viewport_controller.dart';
import '../../canvas/engine/drawing_engine.dart';
import '../../canvas/engine/input_handler.dart';
import '../../canvas/engine/canvas_painter.dart';

/// Transparent overlay that sits on top of a specific PDF page.
/// 
/// Captures gestures, converts them from screen space to PDF page space,
/// and feeds them to the DrawingEngine. Also renders the strokes using CanvasPainter.
class AnnotationCanvas extends StatelessWidget {
  final int pageIndex;
  final Size pageSize;
  final ViewportController viewportController;
  final CoordinateMapper coordinateMapper;
  final DrawingEngine drawingEngine;
  final InputHandler inputHandler;

  const AnnotationCanvas({
    super.key,
    required this.pageIndex,
    required this.pageSize,
    required this.viewportController,
    required this.coordinateMapper,
    required this.drawingEngine,
    required this.inputHandler,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      // We use Listener to get raw PointerEvents (needed for pressure/tilt/stylus info)
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.translucent,
      child: ListenableBuilder(
        listenable: viewportController.transformController,
        builder: (context, _) {
          return ListenableBuilder(
            listenable: drawingEngine,
            builder: (context, _) {
              // Only render if this is the active page being drawn on,
              // or if it has completed strokes.
              final bool isActivePage = drawingEngine.currentPageIndex == pageIndex;
              final strokes = drawingEngine.getStrokesForPage(pageIndex);
              final activeStroke = isActivePage ? drawingEngine.activeStroke : null;

              // Always return CustomPaint so the Listener has a hit-test area
              // even when there are no strokes.

              return CustomPaint(
                size: pageSize,
                isComplex: true,
                willChange: isActivePage && activeStroke != null,
                painter: CanvasPainter(
                  strokes: strokes,
                  activeStroke: activeStroke,
                  // We don't draw background/paper pattern here; the PDF layer provides it
                  backgroundColor: Colors.transparent,
                  paperPattern: PaperPattern.blank, 
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── Input Handling ─────────────────────────────────────

  void _handlePointerDown(PointerDownEvent event) {
    if (!inputHandler.shouldDraw(event)) return;

    // Switch drawing engine context to this page
    drawingEngine.switchPage(pageIndex);

    // event.localPosition is already in the local PDF page coordinates
    // because the Listener is inside the InteractiveViewer transformed stack.
    final Offset localPoint = event.localPosition;

    drawingEngine.startStroke(
      localPoint.dx,
      localPoint.dy,
      pressure: inputHandler.getPressure(event),
      tilt: inputHandler.getTilt(event),
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // Only process if this is the active page and we are currently drawing
    if (drawingEngine.currentPageIndex != pageIndex) return;
    if (drawingEngine.activeStroke == null) return;
    if (!inputHandler.shouldDraw(event)) return;

    final Offset localPoint = event.localPosition;

    drawingEngine.addPoint(
      localPoint.dx,
      localPoint.dy,
      pressure: inputHandler.getPressure(event),
      tilt: inputHandler.getTilt(event),
    );
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (drawingEngine.currentPageIndex != pageIndex) return;
    if (!inputHandler.shouldDraw(event)) return;

    drawingEngine.endStroke();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (drawingEngine.currentPageIndex != pageIndex) return;
    drawingEngine.cancelStroke();
  }

  // Coordinate mapping from local to PDF
  Offset _getLocalPoint(Offset localPosition) {
    return coordinateMapper.canvasToPdf(localPosition);
  }
}
