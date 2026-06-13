import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../engine/stroke_style.dart';
import '../../canvas/engine/stroke.dart';
import '../../../data/repositories/annotation_repository.dart';

/// Flattens drift annotations directly onto a PDF using Syncfusion.
class PdfExportService {
  final AnnotationRepository annotationRepository;

  PdfExportService(this.annotationRepository);

  /// Flattens all annotations onto the PDF and saves it as a new file.
  /// Does not modify the original.
  Future<String> exportFlattenedPdf(String sourcePdfPath, String outputPdfPath, String fileId) async {
    // 1. Load original PDF
    final file = File(sourcePdfPath);
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    // 2. Iterate pages
    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final annotations = await annotationRepository.getAnnotationsForPage(fileId, i);
      
      if (annotations.isEmpty) continue;

      // 3. Draw each annotation onto the PDF page graphics
      for (final annot in annotations) {
        final stroke = annotationRepository.dbToStroke(annot);
        if (stroke == null) continue;

        _drawStrokeToPdf(page.graphics, stroke);
      }
    }

    // 4. Save to new file
    final File outputFile = File(outputPdfPath);
    await outputFile.writeAsBytes(await document.save());
    document.dispose();

    return outputPdfPath;
  }

  void _drawStrokeToPdf(PdfGraphics graphics, Stroke stroke) {
    if (stroke.points.length < 2) return;

    final style = stroke.style;
    
    // Syncfusion PdfColor expects 0-255 RGB
    final pdfColor = PdfColor(
      style.color.r.toInt(),
      style.color.g.toInt(),
      style.color.b.toInt(),
    );

    // Create a pen for drawing lines
    final pen = PdfPen(
      pdfColor,
      width: style.width,
    );
    
    pen.lineCap = style.toolType == ToolType.highlighter 
        ? PdfLineCap.square 
        : PdfLineCap.round;
    pen.lineJoin = PdfLineJoin.round;

    // Optional: apply opacity
    // graphics.setTransparency(style.opacity);

    // Simplistic drawing: connect points with lines
    // For a production app, we would translate our Catmull-Rom logic to PDF paths
    final path = PdfPath();
    path.addLine(
      PdfPoint(stroke.points[0].x, stroke.points[0].y),
      PdfPoint(stroke.points[1].x, stroke.points[1].y),
    );

    for (int i = 1; i < stroke.points.length - 1; i++) {
      path.addLine(
        PdfPoint(stroke.points[i].x, stroke.points[i].y),
        PdfPoint(stroke.points[i+1].x, stroke.points[i+1].y),
      );
    }

    graphics.drawPath(path, pen: pen);
    
    // graphics.setTransparency(1.0); // Reset
  }
}
