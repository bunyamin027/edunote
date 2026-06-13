import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../canvas/engine/input_handler.dart';

enum GestureIntent { draw, panZoom, ignore }

/// Arbitrates complex gesture interactions between the canvas and viewport.
/// Provides advanced palm rejection and stylus detection logic.
class GestureArbitrator {
  final InputHandler inputHandler;
  
  // State
  int _activePointers = 0;
  bool _isStylusActive = false;
  bool _isInPalmRejectionZone = false;

  GestureArbitrator(this.inputHandler);

  /// Called on PointerDownEvent to classify the intent of the gesture
  GestureIntent classifyGesture(PointerDownEvent event, Size screenSize) {
    _activePointers++;
    
    // Check if it's a stylus
    if (event.kind == PointerDeviceKind.stylus || 
        event.kind == PointerDeviceKind.invertedStylus) {
      _isStylusActive = true;
      return GestureIntent.draw; // Stylus always draws
    }

    // Check for edge palm touch
    if (_isPalmTouch(event, screenSize)) {
      _isInPalmRejectionZone = true;
      return GestureIntent.ignore;
    }

    // If stylus was ever used, fingers ONLY pan/zoom
    if (inputHandler.wasStylusDetected || _isStylusActive) {
      return GestureIntent.panZoom;
    }

    // If no stylus, single finger draws, multi-finger pans
    if (_activePointers == 1) {
      return GestureIntent.draw;
    } else {
      return GestureIntent.panZoom;
    }
  }

  void handlePointerUp(PointerEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers == 0) {
      _isInPalmRejectionZone = false;
      // We don't reset _isStylusActive here because we want to maintain
      // the "stylus mode" logic even between strokes
    }
  }

  /// Rejects touches that start very close to the edges (likely palm)
  bool _isPalmTouch(PointerDownEvent event, Size screenSize) {
    const double edgeThreshold = 30.0;
    
    // Only apply palm rejection to large surface areas (if available via radius)
    if (event.radiusMajor > 20.0) return true;

    final pos = event.position;
    return (pos.dx < edgeThreshold) || 
           (pos.dx > screenSize.width - edgeThreshold) ||
           (pos.dy > screenSize.height - edgeThreshold); // Bottom edge usually rests on palm
  }
}
