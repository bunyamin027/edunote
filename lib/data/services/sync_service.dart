import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_constants.dart';
import '../models/notebook_model.dart';
import '../models/folder_model.dart';
import 'auth_service.dart';

/// Handles synchronization between Local Hive DB and Supabase PostgreSQL.
/// Employs an offline-first strategy.
class SyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService;
  
  // Hive Boxes
  final Box _notebookBox = Hive.box(AppConstants.notebooksBox);
  final Box _folderBox = Hive.box(AppConstants.foldersBox);

  SyncService(this._authService);

  /// Run a full synchronization (Upload local changes, Download remote changes)
  Future<void> syncAll() async {
    final user = _authService.currentUser;
    if (user == null) {
      debugPrint('Sync aborted: No authenticated user.');
      return;
    }

    try {
      debugPrint('Starting cloud sync...');
      await _uploadFolders(user.id);
      await _uploadNotebooks(user.id);
      debugPrint('Cloud sync completed successfully.');
    } catch (e) {
      debugPrint('Sync error: $e');
      // Intentionally not rethrowing to prevent app crashes during background sync
    }
  }

  Future<void> _uploadFolders(String userId) async {
    final folders = _folderBox.values.cast<FolderModel>().toList();
    if (folders.isEmpty) return;

    final folderData = folders.map((f) => {
      'id': f.id,
      'user_id': userId,
      'name': f.name,
      'color_index': f.colorIndex,
      'parent_id': f.parentId,
      'created_at': f.createdAt.toIso8601String(),
      'updated_at': f.updatedAt.toIso8601String(),
    }).toList();

    // Upsert into Supabase (Merge by id)
    await _supabase
        .from('folders')
        .upsert(folderData, onConflict: 'id');
  }

  Future<void> _uploadNotebooks(String userId) async {
    final notebooks = _notebookBox.values.cast<NotebookModel>().toList();
    if (notebooks.isEmpty) return;

    final notebookData = notebooks.map((n) => {
      'id': n.id,
      'user_id': userId,
      'name': n.name,
      'cover_index': n.coverIndex,
      'folder_id': n.folderId,
      'created_at': n.createdAt.toIso8601String(),
      'updated_at': n.updatedAt.toIso8601String(),
    }).toList();

    // Upsert into Supabase (Merge by id)
    await _supabase
        .from('notebooks')
        .upsert(notebookData, onConflict: 'id');
  }
  
  /// TODO: Methods for downloading from Supabase and resolving conflicts.
  /// For this MVP, we prioritize uploading local data as a backup.
}
