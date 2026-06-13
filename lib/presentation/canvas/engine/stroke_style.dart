import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';

/// Types of drawing tools available.
enum ToolType {
  pen,
  ballpoint,
  brush,
  highlighter,
  eraser,
  lasso,
  smartShape,
  pan,
}

/// Style configuration for a stroke.
class StrokeStyle extends Equatable {
  /// The drawing tool type.
  final ToolType toolType;

  /// Stroke color.
  final Color color;

  /// Base width of the stroke.
  final double width;

  /// Opacity (1.0 = fully opaque, used differently per tool).
  final double opacity;

  const StrokeStyle({
    this.toolType = ToolType.pen,
    this.color = const Color(0xFF0F172A),
    this.width = AppConstants.defaultStrokeWidth,
    this.opacity = 1.0,
  });

  /// Creates a highlighter style.
  factory StrokeStyle.highlighter({
    Color color = const Color(0xFFFCD34D),
    double width = 16.0,
  }) {
    return StrokeStyle(
      toolType: ToolType.highlighter,
      color: color,
      width: width,
      opacity: AppConstants.highlighterOpacity,
    );
  }

  /// Creates an eraser style.
  factory StrokeStyle.eraser({double width = 20.0}) {
    return StrokeStyle(
      toolType: ToolType.eraser,
      color: Colors.transparent,
      width: width,
      opacity: 1.0,
    );
  }

  /// Whether this tool should use pressure sensitivity.
  bool get usesPressure =>
      toolType == ToolType.pen ||
      toolType == ToolType.brush;

  /// Whether this tool should use smooth curve interpolation.
  bool get usesSmoothing =>
      toolType != ToolType.eraser;

  /// The blend mode for rendering this stroke.
  BlendMode get blendMode {
    if (toolType == ToolType.eraser) return BlendMode.clear;
    if (toolType == ToolType.highlighter) return BlendMode.multiply;
    return BlendMode.srcOver;
  }

  /// The stroke cap style.
  StrokeCap get strokeCap {
    switch (toolType) {
      case ToolType.pen:
      case ToolType.ballpoint:
      case ToolType.brush:
      case ToolType.lasso:
      case ToolType.smartShape:
      case ToolType.pan:
        return StrokeCap.round;
      case ToolType.highlighter:
        return StrokeCap.square;
      case ToolType.eraser:
        return StrokeCap.round;
    }
  }

  /// Build a Paint object from this style.
  Paint toPaint({double? overrideWidth}) {
    return Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = overrideWidth ?? width
      ..strokeCap = strokeCap
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = blendMode
      ..isAntiAlias = true;
  }

  StrokeStyle copyWith({
    ToolType? toolType,
    Color? color,
    double? width,
    double? opacity,
  }) {
    return StrokeStyle(
      toolType: toolType ?? this.toolType,
      color: color ?? this.color,
      width: width ?? this.width,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() => {
        'tool': toolType.index,
        'color': color.toARGB32(),
        'width': width,
        'opacity': opacity,
      };

  factory StrokeStyle.fromJson(Map<String, dynamic> json) {
    return StrokeStyle(
      toolType: ToolType.values[json['tool'] as int? ?? 0],
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [toolType, color, width, opacity];
}
