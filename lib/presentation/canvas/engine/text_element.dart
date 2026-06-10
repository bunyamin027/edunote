import 'package:equatable/equatable.dart';

/// Represents a text element placed on the canvas.
class TextElement extends Equatable {
  /// Unique identifier.
  final String id;

  /// Text content.
  final String text;

  /// Position on canvas (top-left corner).
  final double x;
  final double y;

  /// Font size in logical pixels.
  final double fontSize;

  /// Font weight index (0=normal, 1=bold).
  final int fontWeightIndex;

  /// Whether text is italic.
  final bool isItalic;

  /// Whether text has underline.
  final bool isUnderline;

  /// Text color as ARGB int.
  final int colorValue;

  /// Width of the text box (0 = auto).
  final double width;

  /// Rotation angle in radians.
  final double rotation;

  const TextElement({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 16.0,
    this.fontWeightIndex = 0,
    this.isItalic = false,
    this.isUnderline = false,
    this.colorValue = 0xFF0F172A,
    this.width = 0,
    this.rotation = 0,
  });

  TextElement copyWith({
    String? text,
    double? x,
    double? y,
    double? fontSize,
    int? fontWeightIndex,
    bool? isItalic,
    bool? isUnderline,
    int? colorValue,
    double? width,
    double? rotation,
  }) {
    return TextElement(
      id: id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      fontWeightIndex: fontWeightIndex ?? this.fontWeightIndex,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      colorValue: colorValue ?? this.colorValue,
      width: width ?? this.width,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'fontWeightIndex': fontWeightIndex,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'colorValue': colorValue,
        'width': width,
        'rotation': rotation,
      };

  factory TextElement.fromJson(Map<String, dynamic> json) {
    return TextElement(
      id: json['id'] as String,
      text: json['text'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      fontWeightIndex: json['fontWeightIndex'] as int? ?? 0,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      colorValue: json['colorValue'] as int? ?? 0xFF0F172A,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id, text, x, y, fontSize, fontWeightIndex,
        isItalic, isUnderline, colorValue, width, rotation,
      ];
}
