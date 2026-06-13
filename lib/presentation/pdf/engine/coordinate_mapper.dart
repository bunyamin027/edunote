import 'package:flutter/material.dart';

/// Handles coordinate transformations between Screen, Canvas, and PDF spaces.
class CoordinateMapper {
  final Size pdfPageSize;

  CoordinateMapper({required this.pdfPageSize});

  /// Transform screen point (e.g., from gesture) to canvas point.
  Offset screenToCanvas(Offset screenPoint, Matrix4 viewportTransform) {
    final Matrix4 inverse = Matrix4.inverted(viewportTransform);
    return MatrixUtils.transformPoint(inverse, screenPoint);
  }

  /// Transform canvas point to screen point.
  Offset canvasToScreen(Offset canvasPoint, Matrix4 viewportTransform) {
    return MatrixUtils.transformPoint(viewportTransform, canvasPoint);
  }

  /// Transform canvas point to PDF point.
  /// 
  /// Usually these spaces are 1:1, but this allows for future abstraction 
  /// if the canvas size diverges from the native 72DPI PDF size.
  Offset canvasToPdf(Offset canvasPoint) {
    return canvasPoint; // 1:1 mapping for now
  }

  /// Transform PDF point to canvas point.
  Offset pdfToCanvas(Offset pdfPoint) {
    return pdfPoint; // 1:1 mapping for now
  }

  /// Scale stroke width based on the current zoom level.
  /// This ensures strokes don't appear massive when zoomed out or tiny when zoomed in.
  double scaleStrokeWidth(double baseWidth, double currentZoom) {
    // Inverse scale the width so it stays visually consistent relative to the page
    return baseWidth / currentZoom.clamp(0.5, 3.0);
  }
}
