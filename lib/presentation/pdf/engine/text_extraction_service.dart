import 'package:flutter/services.dart';

/// Service to extract text and trigger OCR on PDF pages.
class TextExtractionService {
  static const MethodChannel _channel = MethodChannel('com.edunoteai.edunote/ocr_plugin');

  /// Fallback: run on-device OCR on a rendered image of the page.
  Future<String> ocrPage(int pageIndex, String documentId) async {
    try {
      final String result = await _channel.invokeMethod('ocrPage', {
        'pageIndex': pageIndex,
        'documentId': documentId,
      });
      return result;
    } catch (e) {
      print('Error during OCR: $e');
      return '';
    }
  }
}
