import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/annotation_model.dart';
import '../../presentation/canvas/engine/stroke.dart';

/// Repository for handling annotation CRUD operations via SQLite (Drift).
class AnnotationRepository {
  final AppDatabase _db;

  AnnotationRepository(this._db);

  /// Get all annotations for a specific page.
  Future<List<Annotation>> getAnnotationsForPage(String fileId, int pageIndex) {
    return (_db.select(_db.annotations)
          ..where((a) => a.fileId.equals(fileId))
          ..where((a) => a.pageIndex.equals(pageIndex))
          ..orderBy([
            (a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  /// Query annotations that intersect with a specific rectangle (e.g. for Lasso or rendering culling).
  Future<List<Annotation>> queryRect(String fileId, int pageIndex, Rect rect) {
    return (_db.select(_db.annotations)
          ..where((a) => a.fileId.equals(fileId))
          ..where((a) => a.pageIndex.equals(pageIndex))
          ..where((a) => 
            // Simple bounding box intersection (AABB)
            a.boundsLeft.isSmallerOrEqualValue(rect.right) &
            a.boundsRight.isBiggerOrEqualValue(rect.left) &
            a.boundsTop.isSmallerOrEqualValue(rect.bottom) &
            a.boundsBottom.isBiggerOrEqualValue(rect.top)
          ))
        .get();
  }

  /// Save a single annotation.
  Future<void> saveAnnotation(AnnotationsCompanion annotation) {
    return _db.into(_db.annotations).insertOnConflictUpdate(annotation);
  }

  /// Delete a single annotation by ID.
  Future<void> deleteAnnotation(String id) {
    return (_db.delete(_db.annotations)..where((a) => a.id.equals(id))).go();
  }

  /// Delete all annotations for a file.
  Future<void> deleteAllForFile(String fileId) {
    return (_db.delete(_db.annotations)..where((a) => a.fileId.equals(fileId))).go();
  }

  // ─── Helper Mappers ──────────────────────────────────────

  /// Converts a memory `Stroke` object to a DB `AnnotationsCompanion`.
  AnnotationsCompanion strokeToDb(String fileId, int pageIndex, Stroke stroke) {
    // Calculate bounding box for spatial queries
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;
    
    // Account for stroke width
    final padding = stroke.style.width / 2;

    for (final p in stroke.points) {
      if (p.x < left) left = p.x;
      if (p.x > right) right = p.x;
      if (p.y < top) top = p.y;
      if (p.y > bottom) bottom = p.y;
    }

    return AnnotationsCompanion.insert(
      id: Value(stroke.id),
      fileId: fileId,
      pageIndex: pageIndex,
      type: AnnotationType.fromToolType(stroke.style.toolType).value,
      data: jsonEncode(stroke.toJson()),
      boundsLeft: left - padding,
      boundsTop: top - padding,
      boundsRight: right + padding,
      boundsBottom: bottom + padding,
    );
  }

  /// Converts a DB `Annotation` back to a memory `Stroke` object.
  Stroke? dbToStroke(Annotation annotation) {
    try {
      final map = jsonDecode(annotation.data) as Map<String, dynamic>;
      return Stroke.fromJson(map);
    } catch (e) {
      debugPrint('Error decoding stroke: $e');
      return null;
    }
  }
}
