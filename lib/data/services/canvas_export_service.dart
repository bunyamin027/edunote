import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../presentation/canvas/engine/canvas_painter.dart';
import '../../presentation/canvas/engine/stroke.dart';

/// Service for exporting canvas content to PNG and PDF.
class CanvasExportService {
  /// Export canvas as PNG bytes.
  ///
  /// Renders all strokes on a clean canvas at the specified resolution
  /// and returns the encoded PNG data.
  Future<Uint8List?> exportAsPng({
    required List<Stroke> strokes,
    PaperPattern paperPattern = PaperPattern.blank,
    Color backgroundColor = Colors.white,
    double width = 2480,
    double height = 3508,
    double pixelRatio = 1.0,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(width, height);

      // Paint using our CanvasPainter
      final painter = CanvasPainter(
        strokes: strokes,
        backgroundColor: backgroundColor,
        paperPattern: paperPattern,
      );
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (width * pixelRatio).toInt(),
        (height * pixelRatio).toInt(),
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      picture.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('PNG export error: $e');
      return null;
    }
  }

  /// Export canvas as a thumbnail (smaller resolution PNG).
  Future<Uint8List?> exportThumbnail({
    required List<Stroke> strokes,
    PaperPattern paperPattern = PaperPattern.blank,
    Color backgroundColor = Colors.white,
    double thumbnailWidth = 248,
    double thumbnailHeight = 350,
  }) async {
    return exportAsPng(
      strokes: strokes,
      paperPattern: paperPattern,
      backgroundColor: backgroundColor,
      width: thumbnailWidth,
      height: thumbnailHeight,
      pixelRatio: 1.0,
    );
  }

  /// Export multiple pages as a list of PNG byte arrays.
  ///
  /// Useful for generating PDF pages or sharing multiple pages.
  Future<List<Uint8List>> exportAllPagesAsPng({
    required List<List<Stroke>> pagesStrokes,
    required List<PaperPattern> pagesPatterns,
    Color backgroundColor = Colors.white,
    double width = 2480,
    double height = 3508,
  }) async {
    final pngList = <Uint8List>[];

    for (int i = 0; i < pagesStrokes.length; i++) {
      final png = await exportAsPng(
        strokes: pagesStrokes[i],
        paperPattern: i < pagesPatterns.length
            ? pagesPatterns[i]
            : PaperPattern.blank,
        backgroundColor: backgroundColor,
        width: width,
        height: height,
      );

      if (png != null) {
        pngList.add(png);
      }
    }

    return pngList;
  }
}
