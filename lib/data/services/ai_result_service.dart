import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/ai_result_model.dart';

/// Service for saving, loading, and deleting AI-generated results.
class AiResultService {
  final Box _box;

  AiResultService(this._box);

  /// Save an AI result.
  Future<void> saveResult(AiResultModel result) async {
    await _box.put(result.id, result.toJson());
  }

  /// Get all AI results for a folder.
  List<AiResultModel> getResultsForFolder(String folderId) {
    try {
      return _box.values
          .whereType<Map>()
          .map((data) =>
              AiResultModel.fromJson(Map<String, dynamic>.from(data)))
          .where((r) => r.folderId == folderId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading AI results: $e');
      return [];
    }
  }

  /// Get a single result by ID.
  AiResultModel? getResultById(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return AiResultModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Update an AI result (e.g. move to different folder).
  Future<void> updateResult(AiResultModel result) async {
    await _box.put(result.id, result.toJson());
  }

  /// Delete a result.
  Future<void> deleteResult(String id) async {
    await _box.delete(id);
  }

  /// Delete all results for a folder.
  Future<void> deleteResultsForFolder(String folderId) async {
    final results = getResultsForFolder(folderId);
    for (final result in results) {
      await _box.delete(result.id);
    }
  }
}
