import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_constants.dart';
import 'stroke.dart';
import 'stroke_point.dart';
import 'stroke_style.dart';
import 'canvas_painter.dart';

/// Core drawing engine that manages strokes, undo/redo, and state.
///
/// This is the central controller for the canvas. It maintains the list
/// of completed strokes, the active (in-progress) stroke, and the
/// undo/redo history stack.
class DrawingEngine extends ChangeNotifier {
  final _uuid = const Uuid();

  /// All completed strokes on the canvas.
  List<Stroke> _strokes = [];
  List<Stroke> get strokes => List.unmodifiable(_strokes);

  /// The stroke currently being drawn.
  Stroke? _activeStroke;
  Stroke? get activeStroke => _activeStroke;

  /// Undo stack — stores removed strokes for redo.
  final List<Stroke> _undoStack = [];

  /// Current tool style.
  StrokeStyle _currentStyle = const StrokeStyle();
  StrokeStyle get currentStyle => _currentStyle;

  /// Current paper pattern.
  PaperPattern _paperPattern = PaperPattern.blank;
  PaperPattern get paperPattern => _paperPattern;

  /// Whether there are actions that can be undone.
  bool get canUndo => _strokes.isNotEmpty;

  /// Whether there are actions that can be redone.
  bool get canRedo => _undoStack.isNotEmpty;

  /// Total number of strokes.
  int get strokeCount => _strokes.length;

  // ─── Drawing Lifecycle ──────────────────────────────

  /// Called when a pointer goes down (user starts drawing).
  void startStroke(double x, double y, {double pressure = 0.5, double tilt = 0.0}) {
    final point = StrokePoint(
      x: x,
      y: y,
      pressure: pressure,
      tilt: tilt,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _activeStroke = Stroke(
      id: _uuid.v4(),
      style: _currentStyle,
      points: [point],
    );

    // Clear redo stack on new drawing action
    _undoStack.clear();

    notifyListeners();
  }

  /// Called as the pointer moves (user continues drawing).
  void addPoint(double x, double y, {double pressure = 0.5, double tilt = 0.0}) {
    if (_activeStroke == null) return;

    final point = StrokePoint(
      x: x,
      y: y,
      pressure: pressure,
      tilt: tilt,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _activeStroke = _activeStroke!.addPoint(point);
    notifyListeners();
  }

  /// Called when the pointer goes up (user finishes drawing).
  void endStroke() {
    if (_activeStroke == null) return;

    // For eraser, remove intersecting strokes instead of adding
    if (_currentStyle.toolType == ToolType.eraser) {
      _eraseIntersectingStrokes(_activeStroke!);
    } else {
      // Simplify the stroke to reduce point count for performance
      final simplified = _activeStroke!.simplify(tolerance: 1.5);
      _strokes.add(simplified);
    }

    _activeStroke = null;
    notifyListeners();
  }

  /// Cancel the current stroke (e.g., on palm rejection).
  void cancelStroke() {
    _activeStroke = null;
    notifyListeners();
  }

  // ─── Eraser Logic ───────────────────────────────────

  /// Remove strokes that intersect with the eraser path.
  void _eraseIntersectingStrokes(Stroke eraserStroke) {
    if (eraserStroke.points.isEmpty) return;

    final eraserWidth = eraserStroke.style.width;
    final toRemove = <int>[];

    for (int i = 0; i < _strokes.length; i++) {
      if (_strokeIntersects(_strokes[i], eraserStroke, eraserWidth)) {
        toRemove.add(i);
      }
    }

    // Remove intersecting strokes (in reverse to maintain indices)
    for (final index in toRemove.reversed) {
      _strokes.removeAt(index);
    }
  }

  /// Check if two strokes intersect within a given threshold.
  bool _strokeIntersects(Stroke target, Stroke eraser, double threshold) {
    for (final ep in eraser.points) {
      for (final tp in target.points) {
        final dx = ep.x - tp.x;
        final dy = ep.y - tp.y;
        if (dx * dx + dy * dy < threshold * threshold) {
          return true;
        }
      }
    }
    return false;
  }

  // ─── Undo / Redo ────────────────────────────────────

  /// Undo the last stroke.
  void undo() {
    if (!canUndo) return;

    final removed = _strokes.removeLast();
    _undoStack.add(removed);

    if (_undoStack.length > AppConstants.undoHistoryLimit) {
      _undoStack.removeAt(0);
    }

    notifyListeners();
  }

  /// Redo the last undone stroke.
  void redo() {
    if (!canRedo) return;

    final restored = _undoStack.removeLast();
    _strokes.add(restored);

    notifyListeners();
  }

  // ─── Tool Configuration ─────────────────────────────

  /// Set the current drawing tool type.
  void setToolType(ToolType type) {
    if (type == ToolType.highlighter) {
      _currentStyle = StrokeStyle.highlighter(
        color: _currentStyle.color,
      );
    } else if (type == ToolType.eraser) {
      _currentStyle = StrokeStyle.eraser();
    } else {
      _currentStyle = _currentStyle.copyWith(
        toolType: type,
        opacity: 1.0,
      );
    }
    notifyListeners();
  }

  /// Set the stroke color.
  void setColor(Color color) {
    _currentStyle = _currentStyle.copyWith(color: color);
    notifyListeners();
  }

  /// Set the stroke width.
  void setWidth(double width) {
    _currentStyle = _currentStyle.copyWith(width: width);
    notifyListeners();
  }

  /// Set the paper pattern.
  void setPaperPattern(PaperPattern pattern) {
    _paperPattern = pattern;
    notifyListeners();
  }

  // ─── Canvas Operations ──────────────────────────────

  /// Clear all strokes from the canvas.
  void clearCanvas() {
    _strokes.clear();
    _undoStack.clear();
    _activeStroke = null;
    notifyListeners();
  }

  /// Load strokes from serialized data.
  void loadStrokes(List<Map<String, dynamic>> data) {
    _strokes = data.map((d) => Stroke.fromJson(d)).toList();
    _undoStack.clear();
    _activeStroke = null;
    notifyListeners();
  }

  /// Export strokes as serializable data.
  List<Map<String, dynamic>> exportStrokes() {
    return _strokes.map((s) => s.toJson()).toList();
  }

  @override
  void dispose() {
    _strokes.clear();
    _undoStack.clear();
    super.dispose();
  }
}
