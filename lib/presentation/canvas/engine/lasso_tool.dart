import 'package:flutter/material.dart';
import 'stroke.dart';

/// Helper class for managing lasso selection and manipulation.
class LassoTool {
  final Path selectionPath = Path();
  final List<Stroke> selectedStrokes = [];
  
  Rect? _selectionBounds;
  bool _isSelecting = false;
  
  bool get isSelecting => _isSelecting;
  Rect? get selectionBounds => _selectionBounds;
  bool get hasSelection => selectedStrokes.isNotEmpty;

  /// Start drawing the lasso path
  void startSelection(Offset point) {
    _isSelecting = true;
    selectionPath.reset();
    selectionPath.moveTo(point.dx, point.dy);
    selectedStrokes.clear();
    _selectionBounds = null;
  }

  /// Continue drawing the lasso path
  void updateSelection(Offset point) {
    if (!_isSelecting) return;
    selectionPath.lineTo(point.dx, point.dy);
  }

  /// Finish the lasso path and find enclosed strokes
  void endSelection(List<Stroke> currentStrokes) {
    if (!_isSelecting) return;
    _isSelecting = false;
    
    // Close the loop
    selectionPath.close();
    
    selectedStrokes.clear();
    double left = double.infinity, top = double.infinity;
    double right = double.negativeInfinity, bottom = double.negativeInfinity;

    for (final stroke in currentStrokes) {
      if (stroke.isContainedIn(selectionPath)) {
        selectedStrokes.add(stroke);
        
        final bounds = stroke.boundingBox;
        if (bounds.left < left) left = bounds.left;
        if (bounds.top < top) top = bounds.top;
        if (bounds.right > right) right = bounds.right;
        if (bounds.bottom > bottom) bottom = bounds.bottom;
      }
    }

    if (selectedStrokes.isNotEmpty) {
      // Create a combined bounding box for all selected strokes
      _selectionBounds = Rect.fromLTRB(left - 5, top - 5, right + 5, bottom + 5);
    } else {
      _selectionBounds = null;
    }
  }

  /// Clear the current selection
  void clearSelection() {
    selectionPath.reset();
    selectedStrokes.clear();
    _selectionBounds = null;
    _isSelecting = false;
  }
}
