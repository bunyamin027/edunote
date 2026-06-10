import 'package:flutter/gestures.dart';

/// Utility for handling stylus vs touch input differentiation.
///
/// Provides palm rejection logic: when a stylus is detected,
/// finger touches are ignored for drawing (but can still pan/zoom).
class InputHandler {
  /// Whether a stylus is currently being used.
  bool _stylusActive = false;
  bool get isStylusActive => _stylusActive;

  /// Whether we've ever detected a stylus in this session.
  bool _stylusDetected = false;
  bool get wasStylusDetected => _stylusDetected;

  /// Number of active touch pointers (for multi-touch detection).
  int _activeTouchCount = 0;
  int get activeTouchCount => _activeTouchCount;

  /// Determines if this pointer event should be used for drawing.
  ///
  /// Returns `true` if the event is from a stylus, or from a finger
  /// when no stylus has been detected.
  bool shouldDraw(PointerEvent event) {
    if (event is PointerDownEvent) {
      _activeTouchCount++;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _activeTouchCount = (_activeTouchCount - 1).clamp(0, 10);
    }

    final isStylus = event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;

    if (isStylus) {
      _stylusActive = true;
      _stylusDetected = true;
      return true;
    }

    // If stylus was detected, reject finger input for drawing
    // (fingers are used for pan/zoom instead)
    if (_stylusDetected) {
      return false;
    }

    // No stylus detected — allow finger drawing
    // But reject multi-touch (2+ fingers = pan/zoom gesture)
    return _activeTouchCount <= 1;
  }

  /// Extracts pressure from pointer event.
  /// Returns 0.5 for non-pressure-sensitive devices.
  double getPressure(PointerEvent event) {
    if (event.pressureMin == event.pressureMax) {
      return 0.5; // Device doesn't support pressure
    }
    return event.pressure.clamp(0.0, 1.0);
  }

  /// Extracts tilt from pointer event (radians).
  double getTilt(PointerEvent event) {
    return event.tilt;
  }

  /// Whether this is an inverted stylus (eraser end of pen).
  bool isEraserEnd(PointerEvent event) {
    return event.kind == PointerDeviceKind.invertedStylus;
  }

  /// Reset state when drawing session ends.
  void reset() {
    _stylusActive = false;
    _activeTouchCount = 0;
  }

  /// Full reset (also forgets stylus detection).
  void fullReset() {
    _stylusActive = false;
    _stylusDetected = false;
    _activeTouchCount = 0;
  }
}
