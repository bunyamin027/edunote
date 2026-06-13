import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../presentation/canvas/engine/stroke_style.dart';

/// Database table for storing annotations (strokes, text, shapes).
class Annotations extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get fileId => text()();
  IntColumn get pageIndex => integer()();
  
  /// Type of annotation: 0=stroke, 1=text, 2=shape, 3=highlight
  IntColumn get type => integer()();
  
  /// JSON encoded data (points for strokes, text content for text, etc.)
  TextColumn get data => text()();
  
  /// Bounding box for spatial queries (stored as L,T,R,B for easy querying)
  RealColumn get boundsLeft => real()();
  RealColumn get boundsTop => real()();
  RealColumn get boundsRight => real()();
  RealColumn get boundsBottom => real()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Domain model mapping for Annotation types.
enum AnnotationType {
  stroke(0),
  text(1),
  shape(2),
  highlight(3);

  final int value;
  const AnnotationType(this.value);

  factory AnnotationType.fromValue(int value) {
    return AnnotationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AnnotationType.stroke,
    );
  }

  /// Maps StrokeStyle tool types to AnnotationType
  factory AnnotationType.fromToolType(ToolType toolType) {
    if (toolType == ToolType.highlighter) return AnnotationType.highlight;
    return AnnotationType.stroke;
  }
}
