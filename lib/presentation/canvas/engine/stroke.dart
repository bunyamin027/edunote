import 'dart:ui';
import 'package:equatable/equatable.dart';

import 'stroke_point.dart';
import 'stroke_style.dart';

/// Represents a complete stroke — a collection of points with a style.
class Stroke extends Equatable {
  /// Unique identifier for this stroke.
  final String id;

  /// The visual style of this stroke.
  final StrokeStyle style;

  /// Ordered list of points comprising this stroke.
  final List<StrokePoint> points;

  const Stroke({
    required this.id,
    required this.style,
    required this.points,
  });

  /// Whether this stroke has enough points to render.
  bool get isValid => points.length >= 2;

  /// Whether this stroke is a single dot (tap without drag).
  bool get isDot => points.length == 1;

  /// Axis-aligned bounding box for spatial queries.
  Rect get boundingBox {
    if (points.isEmpty) return Rect.zero;
    
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;
    
    final padding = style.width / 2;

    for (final p in points) {
      if (p.x < left) left = p.x;
      if (p.x > right) right = p.x;
      if (p.y < top) top = p.y;
      if (p.y > bottom) bottom = p.y;
    }

    return Rect.fromLTRB(
      left - padding, 
      top - padding, 
      right + padding, 
      bottom + padding
    );
  }

  /// Whether a point is inside this stroke's path (with padding).
  bool containsPoint(Offset point) {
    if (!boundingBox.contains(point)) return false;
    
    final threshold = style.width / 2 + 5.0; // 5px padding for easier selection
    final thresholdSq = threshold * threshold;

    for (final p in points) {
      final dx = p.x - point.dx;
      final dy = p.y - point.dy;
      if (dx * dx + dy * dy <= thresholdSq) {
        return true;
      }
    }
    return false;
  }

  /// Whether this stroke is fully contained within a lasso path.
  bool isContainedIn(Path lassoPath) {
    if (points.isEmpty) return false;
    
    // For performance, just check if all points are inside
    // For large strokes, might want to step by N points
    for (final p in points) {
      if (!lassoPath.contains(p.offset)) {
        return false;
      }
    }
    return true;
  }

  /// Add a point to this stroke (returns new instance).
  Stroke addPoint(StrokePoint point) {
    return Stroke(
      id: id,
      style: style,
      points: [...points, point],
    );
  }

  /// Simplify the stroke by removing points that are too close together.
  /// Uses Ramer-Douglas-Peucker algorithm concept with distance threshold.
  Stroke simplify({double tolerance = 1.0}) {
    if (points.length <= 3) return this;

    final simplified = <StrokePoint>[points.first];

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final dx = curr.x - prev.x;
      final dy = curr.y - prev.y;
      final dist = dx * dx + dy * dy; // squared distance for performance

      if (dist > tolerance * tolerance) {
        simplified.add(curr);
      }
    }

    simplified.add(points.last);

    return Stroke(
      id: id,
      style: style,
      points: simplified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'style': style.toJson(),
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id'] as String,
      style: StrokeStyle.fromJson(json['style'] as Map<String, dynamic>),
      points: (json['points'] as List)
          .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, style, points];
}
