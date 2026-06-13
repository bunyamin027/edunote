import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_constants.dart';
import 'stroke.dart';
import 'stroke_point.dart';
import 'stroke_style.dart';
import 'canvas_painter.dart';
import 'lasso_tool.dart';
import 'smart_shape_detector.dart';

/// Core drawing engine that manages strokes, undo/redo, and state.
///
/// This is the central controller for the canvas. It maintains the list
/// of completed strokes, the active (in-progress) stroke, and the
/// undo/redo history stack.
class DrawingEngine extends ChangeNotifier {
  final _uuid = const Uuid();

  /// Strokes organized by page index.
  final Map<int, List<Stroke>> _pageStrokes = {};
  
  /// Gets strokes for a specific page.
  List<Stroke> getStrokesForPage(int pageIndex) {
    return List.unmodifiable(_pageStrokes[pageIndex] ?? []);
  }

  /// All strokes on the current page.
  List<Stroke> get strokes => getStrokesForPage(_currentPageIndex);

  /// Current page being annotated.
  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  /// Tool helpers
  final LassoTool lassoTool = LassoTool();
  final SmartShapeDetector shapeDetector = SmartShapeDetector();

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
  bool get canUndo => (_pageStrokes[_currentPageIndex]?.isNotEmpty ?? false);

  /// Whether there are actions that can be redone.
  bool get canRedo => _undoStack.isNotEmpty;

  /// Total number of strokes on current page.
  int get strokeCount => _pageStrokes[_currentPageIndex]?.length ?? 0;

  // ─── Page Navigation ────────────────────────────────
  
  void switchPage(int pageIndex) {
    if (_currentPageIndex == pageIndex) return;
    
    // Cancel any active drawing
    cancelStroke();
    _undoStack.clear(); // Clear undo stack on page switch
    
    _currentPageIndex = pageIndex;
    notifyListeners();
  }

  // ─── Drawing Lifecycle ──────────────────────────────

  /// Called when a pointer goes down (user starts drawing).
  void startStroke(double x, double y, {double pressure = 0.5, double tilt = 0.0}) {
    if (_currentStyle.toolType == ToolType.pan) return;

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

    if (_currentStyle.toolType == ToolType.lasso) {
      lassoTool.startSelection(point.offset);
    }

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
    
    if (_currentStyle.toolType == ToolType.lasso) {
      lassoTool.updateSelection(point.offset);
    }
    
    notifyListeners();
  }

  /// Called when the pointer goes up (user finishes drawing).
  void endStroke() {
    if (_activeStroke == null) return;

    _pageStrokes[_currentPageIndex] ??= [];

    // For eraser, remove intersecting strokes instead of adding
    if (_currentStyle.toolType == ToolType.eraser) {
      _eraseIntersectingStrokes(_activeStroke!);
    } else if (_currentStyle.toolType == ToolType.lasso) {
      lassoTool.endSelection(_pageStrokes[_currentPageIndex] ?? []);
    } else if (_currentStyle.toolType == ToolType.smartShape) {
      final shape = shapeDetector.detect(_activeStroke!.points);
      final newPoints = shapeDetector.geometrize(_activeStroke!.points, shape);
      final finalStroke = Stroke(
        id: _activeStroke!.id,
        style: _activeStroke!.style,
        points: newPoints,
      );
      _pageStrokes[_currentPageIndex]!.add(finalStroke.simplify(tolerance: 1.5));
    } else {
      // Simplify the stroke to reduce point count for performance
      final simplified = _activeStroke!.simplify(tolerance: 1.5);
      _pageStrokes[_currentPageIndex]!.add(simplified);
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
    
    final currentStrokes = _pageStrokes[_currentPageIndex];
    if (currentStrokes == null || currentStrokes.isEmpty) return;

    final eraserWidth = eraserStroke.style.width;
    final toRemove = <int>[];

    for (int i = 0; i < currentStrokes.length; i++) {
      if (_strokeIntersects(currentStrokes[i], eraserStroke, eraserWidth)) {
        toRemove.add(i);
      }
    }

    // Remove intersecting strokes (in reverse to maintain indices)
    for (final index in toRemove.reversed) {
      currentStrokes.removeAt(index);
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
    
    final currentStrokes = _pageStrokes[_currentPageIndex];
    if (currentStrokes == null || currentStrokes.isEmpty) return;

    final removed = currentStrokes.removeLast();
    _undoStack.add(removed);

    if (_undoStack.length > AppConstants.undoHistoryLimit) {
      _undoStack.removeAt(0);
    }

    notifyListeners();
  }

  /// Redo the last undone stroke.
  void redo() {
    if (!canRedo) return;

    _pageStrokes[_currentPageIndex] ??= [];
    final restored = _undoStack.removeLast();
    _pageStrokes[_currentPageIndex]!.add(restored);

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

  /// Set the stroke opacity.
  void setOpacity(double opacity) {
    _currentStyle = _currentStyle.copyWith(opacity: opacity);
    notifyListeners();
  }

  /// Set the paper pattern.
  void setPaperPattern(PaperPattern pattern) {
    _paperPattern = pattern;
    notifyListeners();
  }

  // ─── Canvas Operations ──────────────────────────────

  /// Clear all strokes from the current page.
  void clearCanvas() {
    _pageStrokes[_currentPageIndex]?.clear();
    _undoStack.clear();
    _activeStroke = null;
    notifyListeners();
  }

  /// Load strokes from serialized data for a specific page.
  void loadStrokes(int pageIndex, List<Map<String, dynamic>> data) {
    _pageStrokes[pageIndex] = data.map((d) => Stroke.fromJson(d)).toList();
    if (pageIndex == _currentPageIndex) {
      _undoStack.clear();
      _activeStroke = null;
      notifyListeners();
    }
  }

  /// Export strokes as serializable data for a specific page.
  List<Map<String, dynamic>> exportStrokes(int pageIndex) {
    return _pageStrokes[pageIndex]?.map((s) => s.toJson()).toList() ?? [];
  }

  @override
  void dispose() {
    _pageStrokes.clear();
    _undoStack.clear();
    super.dispose();
  }
}
