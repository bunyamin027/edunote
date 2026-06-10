import 'package:flutter/material.dart';

import 'stroke.dart';
import 'stroke_style.dart';

/// CustomPainter that renders all strokes on the canvas.
///
/// Uses Catmull-Rom spline interpolation for smooth curves
/// and variable-width rendering for pressure sensitivity.
class CanvasPainter extends CustomPainter {
  /// Completed strokes to render.
  final List<Stroke> strokes;

  /// The stroke currently being drawn (if any).
  final Stroke? activeStroke;

  /// Background color of the canvas.
  final Color backgroundColor;

  /// Paper template type for background pattern.
  final PaperPattern paperPattern;

  CanvasPainter({
    required this.strokes,
    this.activeStroke,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.paperPattern = PaperPattern.blank,
  }) : super(repaint: null);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // Draw paper pattern
    _drawPaperPattern(canvas, size);

    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw active stroke
    if (activeStroke != null) {
      _drawStroke(canvas, activeStroke!);
    }
  }

  /// Draws a single stroke on the canvas.
  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final points = stroke.points;
    final style = stroke.style;

    // Single dot
    if (stroke.isDot) {
      final point = points.first;
      final dotWidth = style.usesPressure
          ? point.getWidth(style.width)
          : style.width;
      canvas.drawCircle(
        point.offset,
        dotWidth / 2,
        style.toPaint(overrideWidth: dotWidth),
      );
      return;
    }

    // For eraser tool, use simple line segments
    if (style.toolType == ToolType.eraser) {
      _drawSimpleStroke(canvas, stroke);
      return;
    }

    // For pressure-sensitive tools, draw variable-width path
    if (style.usesPressure && points.length >= 3) {
      _drawPressureSensitiveStroke(canvas, stroke);
    } else {
      _drawSmoothedStroke(canvas, stroke);
    }
  }

  /// Draws a simple polyline stroke (for eraser).
  void _drawSimpleStroke(Canvas canvas, Stroke stroke) {
    final paint = stroke.style.toPaint();
    final path = Path();
    path.moveTo(stroke.points.first.x, stroke.points.first.y);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].x, stroke.points[i].y);
    }

    canvas.drawPath(path, paint);
  }

  /// Draws a smoothed stroke using Catmull-Rom spline interpolation.
  void _drawSmoothedStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.points;
    if (points.length < 2) return;

    final paint = stroke.style.toPaint();
    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    if (points.length == 2) {
      path.lineTo(points[1].x, points[1].y);
    } else {
      // Catmull-Rom spline through all points
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

        // Convert to cubic bezier control points from Catmull-Rom
        final cp1x = p1.x + (p2.x - p0.x) / 6;
        final cp1y = p1.y + (p2.y - p0.y) / 6;
        final cp2x = p2.x - (p3.x - p1.x) / 6;
        final cp2y = p2.y - (p3.y - p1.y) / 6;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y);
      }
    }

    canvas.drawPath(path, paint);
  }

  /// Draws a pressure-sensitive stroke with variable width.
  /// Renders as a filled polygon that follows the stroke path.
  void _drawPressureSensitiveStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.points;
    final style = stroke.style;

    if (points.length < 2) return;

    // For each segment, draw a line with interpolated width
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Interpolate width based on pressure
      final w1 = style.usesPressure
          ? p1.getWidth(style.width)
          : style.width;
      final w2 = style.usesPressure
          ? p2.getWidth(style.width)
          : style.width;

      // Average width for this segment
      final segmentWidth = (w1 + w2) / 2;

      final paint = style.toPaint(overrideWidth: segmentWidth);

      // Smooth connection using quadratic bezier for mid-segments
      if (i < points.length - 2 && i > 0) {
        final midX = (p1.x + p2.x) / 2;
        final midY = (p1.y + p2.y) / 2;

        final path = Path()
          ..moveTo(p1.x, p1.y)
          ..quadraticBezierTo(p1.x, p1.y, midX, midY);

        canvas.drawPath(path, paint);
      } else {
        canvas.drawLine(p1.offset, p2.offset, paint);
      }
    }

    // Draw rounded end caps
    if (points.isNotEmpty) {
      final firstPoint = points.first;
      final lastPoint = points.last;
      final firstWidth = style.usesPressure
          ? firstPoint.getWidth(style.width)
          : style.width;
      final lastWidth = style.usesPressure
          ? lastPoint.getWidth(style.width)
          : style.width;

      final capPaint = Paint()
        ..color = style.color.withValues(alpha: style.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(firstPoint.offset, firstWidth / 2, capPaint);
      canvas.drawCircle(lastPoint.offset, lastWidth / 2, capPaint);
    }
  }

  /// Draws the paper pattern (lines, grid, dots, etc.).
  void _drawPaperPattern(Canvas canvas, Size size) {
    if (paperPattern == PaperPattern.blank) return;

    final paint = Paint()
      ..color = const Color(0xFFD4D8E0)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 28.0;
    const margin = 40.0;

    switch (paperPattern) {
      case PaperPattern.blank:
        break;

      case PaperPattern.lined:
        for (double y = margin; y < size.height; y += spacing) {
          canvas.drawLine(
            Offset(margin, y),
            Offset(size.width - margin, y),
            paint,
          );
        }
        // Red margin line
        canvas.drawLine(
          Offset(margin + 40, 0),
          Offset(margin + 40, size.height),
          Paint()
            ..color = const Color(0xFFFFB3B3)
            ..strokeWidth = 0.8,
        );

      case PaperPattern.grid:
        // Horizontal lines
        for (double y = margin; y < size.height; y += spacing) {
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y),
            paint,
          );
        }
        // Vertical lines
        for (double x = margin; x < size.width; x += spacing) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, size.height),
            paint,
          );
        }

      case PaperPattern.dotted:
        final dotPaint = Paint()
          ..color = const Color(0xFFBBC3D0)
          ..style = PaintingStyle.fill;
        for (double y = margin; y < size.height; y += spacing) {
          for (double x = margin; x < size.width; x += spacing) {
            canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
          }
        }

      case PaperPattern.isometric:
        final isoPaint = Paint()
          ..color = const Color(0xFFD4D8E0)
          ..strokeWidth = 0.4
          ..style = PaintingStyle.stroke;
        const isoSpacing = 28.0;
        // Horizontal lines
        for (double y = 0; y < size.height; y += isoSpacing * 0.866) {
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y),
            isoPaint,
          );
        }
        // Diagonal lines (left-to-right)
        for (double x = -size.height; x < size.width + size.height;
            x += isoSpacing) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x + size.height * 0.577, size.height),
            isoPaint,
          );
        }
        // Diagonal lines (right-to-left)
        for (double x = -size.height; x < size.width + size.height;
            x += isoSpacing) {
          canvas.drawLine(
            Offset(x + size.width, 0),
            Offset(x + size.width - size.height * 0.577, size.height),
            isoPaint,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activeStroke != activeStroke ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.paperPattern != paperPattern;
  }
}

/// Paper pattern types for canvas background.
enum PaperPattern {
  blank,
  lined,
  grid,
  dotted,
  isometric,
}
