import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Handles communication with native platform to render PDF tiles.
class PdfTileRenderer {
  static const MethodChannel _channel = MethodChannel('com.edunoteai.edunote/pdf_renderer');

  /// Document identifier used by native side.
  String? _documentId;

  /// Loads a PDF document into native memory.
  Future<bool> loadDocument(String filePath) async {
    try {
      final result = await _channel.invokeMethod('loadDocument', {
        'path': filePath,
      });
      _documentId = result['documentId'];
      return _documentId != null;
    } catch (e) {
      print('Error loading PDF document: $e');
      return false;
    }
  }

  /// Gets the number of pages in the loaded document.
  Future<int> getPageCount() async {
    if (_documentId == null) return 0;
    try {
      final result = await _channel.invokeMethod('getPageCount', {
        'documentId': _documentId,
      });
      return result as int;
    } catch (e) {
      print('Error getting page count: $e');
      return 0;
    }
  }

  /// Gets the original size of a specific page (at 72 DPI).
  Future<ui.Size?> getPageSize(int pageIndex) async {
    if (_documentId == null) return null;
    try {
      final result = await _channel.invokeMethod('getPageSize', {
        'documentId': _documentId,
        'pageIndex': pageIndex,
      });
      return ui.Size(
        (result['width'] as num).toDouble(),
        (result['height'] as num).toDouble(),
      );
    } catch (e) {
      print('Error getting page size: $e');
      return null;
    }
  }

  /// Renders a specific tile of a page.
  /// 
  /// [pageIndex] 0-based page index.
  /// [tileRect] The bounding box of the tile to render (in unscaled PDF coordinates).
  /// [scale] The current zoom scale factor to render at.
  /// [width], [height] the pixel dimensions of the resulting image tile.
  Future<ui.Image?> renderTile({
    required int pageIndex,
    required ui.Rect tileRect,
    required double scale,
    required int width,
    required int height,
  }) async {
    if (_documentId == null) return null;
    
    try {
      final Uint8List? pixels = await _channel.invokeMethod('renderTile', {
        'documentId': _documentId,
        'pageIndex': pageIndex,
        'x': tileRect.left,
        'y': tileRect.top,
        'width': tileRect.width,
        'height': tileRect.height,
        'scale': scale,
        'pixelWidth': width,
        'pixelHeight': height,
      });

      if (pixels == null) return null;

      // Decode RGBA pixels into ui.Image
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
      final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      final ui.Codec codec = await descriptor.instantiateCodec();
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      print('Error rendering tile: $e');
      return null;
    }
  }

  /// Unloads the document and frees native memory.
  Future<void> unloadDocument() async {
    if (_documentId == null) return;
    try {
      await _channel.invokeMethod('unloadDocument', {
        'documentId': _documentId,
      });
      _documentId = null;
    } catch (e) {
      print('Error unloading document: $e');
    }
  }
}
