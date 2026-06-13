import 'package:flutter/material.dart';

/// Manages viewport transforms (pan/zoom) and coordinates.
class ViewportController extends ChangeNotifier {
  final TransformationController _transformController = TransformationController();
  TransformationController get transformController => _transformController;

  Size _viewportSize = Size.zero;
  Size _documentSize = Size.zero;
  Size get documentSize => _documentSize;
  
  double _minScale = 0.5;
  double _maxScale = 5.0;
  
  double get minScale => _minScale;
  double get maxScale => _maxScale;

  void initialize(Size viewportSize, Size documentSize) {
    _viewportSize = viewportSize;
    _documentSize = documentSize;
    
    // Fit to width by default
    if (documentSize.width > 0 && viewportSize.width > 0) {
      final initialScale = viewportSize.width / documentSize.width;
      _minScale = initialScale * 0.5;
      _maxScale = initialScale * 8.0;
      
      final matrix = Matrix4.identity()..scale(initialScale);
      _transformController.value = matrix;
    }
  }

  void updateViewportSize(Size newViewportSize) {
    if (_viewportSize == newViewportSize) return;
    
    final oldWidth = _viewportSize.width > 0 ? _viewportSize.width : newViewportSize.width;
    _viewportSize = newViewportSize;
    
    // If we have a valid document, update min/max scale and re-clamp
    if (_documentSize.width > 0 && newViewportSize.width > 0) {
      final initialScale = newViewportSize.width / _documentSize.width;
      _minScale = initialScale * 0.5;
      _maxScale = initialScale * 8.0;
      
      // Optionally, we could adjust current scale to keep the same relative zoom
      // but usually just clamping to new bounds is enough.
      _transformController.value = _clampMatrix(_transformController.value);
    }
  }

  /// The current scale (zoom level).
  double get scale => _transformController.value.getMaxScaleOnAxis();

  /// The visible rectangle in document coordinates.
  Rect get visibleRect {
    if (_viewportSize.isEmpty || _documentSize.isEmpty) return Rect.zero;
    
    final Matrix4 inverse = Matrix4.inverted(_transformController.value);
    final Offset topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final Offset bottomRight = MatrixUtils.transformPoint(
      inverse, 
      Offset(_viewportSize.width, _viewportSize.height)
    );
    
    return Rect.fromPoints(topLeft, bottomRight).intersect(
      Rect.fromLTWH(0, 0, _documentSize.width, _documentSize.height)
    );
  }

  void panBy(Offset delta) {
    final Matrix4 matrix = _transformController.value.clone();
    matrix.translate(delta.dx, delta.dy);
    _transformController.value = _clampMatrix(matrix);
  }

  void zoomBy(double scaleFactor, Offset focalPoint) {
    final double currentScale = scale;
    double newScale = (currentScale * scaleFactor).clamp(_minScale, _maxScale);
    double actualScaleFactor = newScale / currentScale;

    final Matrix4 matrix = _transformController.value.clone();
    // Translate to focal point, scale, then translate back
    matrix.translate(focalPoint.dx, focalPoint.dy);
    matrix.scale(actualScaleFactor, actualScaleFactor);
    matrix.translate(-focalPoint.dx, -focalPoint.dy);
    
    _transformController.value = _clampMatrix(matrix);
  }

  /// Clamps the matrix to keep the document within viewport bounds.
  Matrix4 _clampMatrix(Matrix4 matrix) {
    if (_viewportSize.isEmpty || _documentSize.isEmpty) return matrix;

    final double currentScale = matrix.getMaxScaleOnAxis();
    final double scaledDocWidth = _documentSize.width * currentScale;
    final double scaledDocHeight = _documentSize.height * currentScale;

    double dx = matrix.getTranslation().x;
    double dy = matrix.getTranslation().y;

    // Clamp X
    if (scaledDocWidth < _viewportSize.width) {
      // Center horizontally if document is smaller than viewport
      dx = (_viewportSize.width - scaledDocWidth) / 2;
    } else {
      dx = dx.clamp(_viewportSize.width - scaledDocWidth, 0.0);
    }

    // Clamp Y
    if (scaledDocHeight < _viewportSize.height) {
      // Top align if document is smaller than viewport
      dy = 0; 
    } else {
      dy = dy.clamp(_viewportSize.height - scaledDocHeight, 0.0);
    }

    return Matrix4.identity()
      ..translate(dx, dy)
      ..scale(currentScale);
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }
}
