import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Represents a single point in a stroke with pressure and tilt data.
class StrokePoint extends Equatable {
  /// X coordinate on the canvas.
  final double x;

  /// Y coordinate on the canvas.
  final double y;

  /// Pressure value from stylus (0.0 - 1.0).
  /// Defaults to 0.5 for touch/mouse input.
  final double pressure;

  /// Tilt angle of the stylus in radians.
  final double tilt;

  /// Timestamp when this point was captured.
  final int timestamp;

  const StrokePoint({
    required this.x,
    required this.y,
    this.pressure = 0.5,
    this.tilt = 0.0,
    required this.timestamp,
  });

  Offset get offset => Offset(x, y);

  /// Interpolated width based on pressure and base width.
  double getWidth(double baseWidth) {
    // Pressure multiplier: 0.3x at lightest, 1.5x at heaviest
    final pressureMultiplier = 0.3 + (pressure * 1.2);
    return baseWidth * pressureMultiplier;
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'p': pressure,
        't': tilt,
        'ts': timestamp,
      };

  factory StrokePoint.fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: (json['p'] as num?)?.toDouble() ?? 0.5,
      tilt: (json['t'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['ts'] as int,
    );
  }

  @override
  List<Object?> get props => [x, y, pressure, tilt, timestamp];
}
