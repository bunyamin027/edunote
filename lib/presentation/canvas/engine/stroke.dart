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
