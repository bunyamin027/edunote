import 'dart:math';
import 'package:flutter/material.dart';
import 'stroke_point.dart';

enum DetectedShape { line, rectangle, circle, triangle, arrow, none }

/// Detects geometric intent from freehand strokes.
class SmartShapeDetector {
  /// Analyzes points to detect if they approximate a primitive shape
  DetectedShape detect(List<StrokePoint> points) {
    if (points.length < 5) return DetectedShape.none;
    
    // Quick heuristic: ratio of path length to bounding box diagonal
    double pathLength = 0;
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
      
      if (i > 0) {
        final prev = points[i-1];
        pathLength += sqrt(pow(p.x - prev.x, 2) + pow(p.y - prev.y, 2));
      }
    }
    
    final dx = maxX - minX;
    final dy = maxY - minY;
    final diag = sqrt(dx*dx + dy*dy);
    
    // If it's very long and thin, and path length is close to distance between endpoints
    final distEndpoints = sqrt(
      pow(points.last.x - points.first.x, 2) + 
      pow(points.last.y - points.first.y, 2)
    );
    
    if (pathLength / distEndpoints < 1.15) {
      return DetectedShape.line;
    }
    
    // If endpoints are close (closed loop)
    if (distEndpoints < diag * 0.2) {
      final bboxPerimeter = 2 * (dx + dy);
      final bboxArea = dx * dy;
      
      // Circle heuristic: path length ≈ π * diameter
      final r = (dx + dy) / 4;
      final expectedCircumference = 2 * pi * r;
      if ((pathLength - expectedCircumference).abs() / expectedCircumference < 0.15) {
        return DetectedShape.circle;
      }
      
      // Rectangle heuristic: path length ≈ bounding box perimeter
      if ((pathLength - bboxPerimeter).abs() / bboxPerimeter < 0.15) {
        return DetectedShape.rectangle;
      }
    }
    
    return DetectedShape.none;
  }

  /// Replaces freehand points with idealized geometric points
  List<StrokePoint> geometrize(List<StrokePoint> original, DetectedShape shape) {
    if (original.isEmpty || shape == DetectedShape.none) return original;
    
    final int timestamp = original.last.timestamp;
    
    switch (shape) {
      case DetectedShape.line:
        return [
          StrokePoint(x: original.first.x, y: original.first.y, timestamp: timestamp),
          StrokePoint(x: original.last.x, y: original.last.y, timestamp: timestamp),
        ];
        
      case DetectedShape.rectangle:
        double minX = double.infinity, maxX = double.negativeInfinity;
        double minY = double.infinity, maxY = double.negativeInfinity;
        for (final p in original) {
          if (p.x < minX) minX = p.x;
          if (p.x > maxX) maxX = p.x;
          if (p.y < minY) minY = p.y;
          if (p.y > maxY) maxY = p.y;
        }
        return [
          StrokePoint(x: minX, y: minY, timestamp: timestamp),
          StrokePoint(x: maxX, y: minY, timestamp: timestamp),
          StrokePoint(x: maxX, y: maxY, timestamp: timestamp),
          StrokePoint(x: minX, y: maxY, timestamp: timestamp),
          StrokePoint(x: minX, y: minY, timestamp: timestamp), // Close path
        ];
        
      case DetectedShape.circle:
        double minX = double.infinity, maxX = double.negativeInfinity;
        double minY = double.infinity, maxY = double.negativeInfinity;
        for (final p in original) {
          if (p.x < minX) minX = p.x;
          if (p.x > maxX) maxX = p.x;
          if (p.y < minY) minY = p.y;
          if (p.y > maxY) maxY = p.y;
        }
        
        final cx = (minX + maxX) / 2;
        final cy = (minY + maxY) / 2;
        final r = ((maxX - minX) + (maxY - minY)) / 4;
        
        final circlePoints = <StrokePoint>[];
        // Generate 36 points for the circle
        for (int i = 0; i <= 36; i++) {
          final angle = i * (pi * 2) / 36;
          circlePoints.add(StrokePoint(
            x: cx + r * cos(angle),
            y: cy + r * sin(angle),
            timestamp: timestamp,
          ));
        }
        return circlePoints;
        
      default:
        return original;
    }
  }
}
