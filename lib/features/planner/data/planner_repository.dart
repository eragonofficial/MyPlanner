import 'package:flutter/foundation.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/note_model.dart';

enum SyncOutcome {
  synced,
  offline,
  error,
}

class PlannerRepository {
  final LocalStorageService _localStorage;

  PlannerRepository(this._localStorage);

  LocalStorageService get localStorage => _localStorage;

  bool get isCloudSyncAvailable => SupabaseService.isReady;

  /// Loads cached notes for authenticated user immediately; returns empty for unauthenticated users
  List<NoteModel> loadInitialNotes() {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];
    final localMaps = _localStorage.getNotes(userId: userId);
    return localMaps.map((m) => NoteModel.fromMap(m)).toList();
  }

  /// Core bulletproof sync engine (Strictly authenticated users only):
  /// 1. Flushes any offline queued mutations for this user.
  /// 2. Treats Supabase as Single Source of Truth, refreshing user-scoped local cache.
  Future<({List<NoteModel> notes, SyncOutcome outcome})> syncCloudAndLocal() async {
    final userId = SupabaseService.currentUserId;

    // Unauthenticated users cannot store or sync plans
    if (!SupabaseService.isReady || !SupabaseService.isAuthenticated || userId == null) {
      return (
        notes: <NoteModel>[],
        outcome: SyncOutcome.offline,
      );
    }

    try {
      // Step 1: Flush pending offline mutations queue for this authenticated user
      final pendingMutations = _localStorage.getPendingMutations(userId: userId);
      if (pendingMutations.isNotEmpty) {
        debugPrint('Flushing ${pendingMutations.length} pending offline mutations for $userId...');
        bool allFlushed = true;
        for (final item in pendingMutations) {
          final action = item['action'];
          if (action == 'upsert') {
            final ok = await SupabaseService.upsertNote(Map<String, dynamic>.from(item['data']));
            if (!ok) allFlushed = false;
          } else if (action == 'delete') {
            final ok = await SupabaseService.deleteNote(item['id'].toString());
            if (!ok) allFlushed = false;
          }
        }
        if (allFlushed) {
          await _localStorage.clearPendingMutations(userId: userId);
        }
      }

      // Step 2: Fetch from Supabase as Single Source of Truth
      final remoteMaps = await SupabaseService.fetchNotes();
      if (remoteMaps != null) {
        final remoteNotes = remoteMaps.map((m) => NoteModel.fromMap(m)).toList();

        // Update user-scoped offline cache
        await _localStorage.saveNotes(
          remoteNotes.map((n) => n.toMap()).toList(),
          userId: userId,
        );
        await _localStorage.setLastSync(DateTime.now());

        return (notes: remoteNotes, outcome: SyncOutcome.synced);
      } else {
        // Network failure: fallback to user-scoped offline cache safely
        final cached = _localStorage.getNotes(userId: userId);
        return (
          notes: cached.map((m) => NoteModel.fromMap(m)).toList(),
          outcome: SyncOutcome.offline,
        );
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
      final cached = _localStorage.getNotes(userId: userId);
      return (
        notes: cached.map((m) => NoteModel.fromMap(m)).toList(),
        outcome: SyncOutcome.error,
      );
    }
  }

  /// Create: Requires authenticated user; saves to user cache and upserts to Supabase
  Future<bool> addNote(NoteModel note, List<NoteModel> currentNotes) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return false;

    final updatedList = [note, ...currentNotes];
    await _localStorage.saveNotes(updatedList.map((n) => n.toMap()).toList(), userId: userId);

    if (SupabaseService.isReady && SupabaseService.isAuthenticated) {
      final success = await SupabaseService.upsertNote(note.toMap());
      if (!success) {
        await _localStorage.addPendingMutation({
          'action': 'upsert',
          'data': note.toMap(),
        }, userId: userId);
      }
    }
    return true;
  }

  /// Update: Requires authenticated user; updates user cache and upserts to Supabase
  Future<bool> updateNote(NoteModel note, List<NoteModel> currentNotes) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return false;

    final index = currentNotes.indexWhere((n) => n.id == note.id);
    if (index == -1) return false;

    final updatedList = List<NoteModel>.from(currentNotes);
    updatedList[index] = note;

    await _localStorage.saveNotes(updatedList.map((n) => n.toMap()).toList(), userId: userId);

    if (SupabaseService.isReady && SupabaseService.isAuthenticated) {
      final success = await SupabaseService.upsertNote(note.toMap());
      if (!success) {
        await _localStorage.addPendingMutation({
          'action': 'upsert',
          'data': note.toMap(),
        }, userId: userId);
      }
    }
    return true;
  }

  /// Toggle is_completed: Requires authenticated user
  Future<bool> toggleComplete(NoteModel note, List<NoteModel> currentNotes) async {
    final updated = note.copyWith(isCompleted: !note.isCompleted);
    return await updateNote(updated, currentNotes);
  }

  /// Delete: Requires authenticated user; deletes from user cache and Supabase
  Future<bool> deleteNote(String noteId, List<NoteModel> currentNotes) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return false;

    final updatedList = currentNotes.where((n) => n.id != noteId).toList();
    await _localStorage.saveNotes(updatedList.map((n) => n.toMap()).toList(), userId: userId);

    if (SupabaseService.isReady && SupabaseService.isAuthenticated) {
      final success = await SupabaseService.deleteNote(noteId);
      if (!success) {
        await _localStorage.addPendingMutation({
          'action': 'delete',
          'id': noteId,
        }, userId: userId);
      }
    }
    return true;
  }

  /// Safe sign-out: Clears only local user cache on this device without touching Supabase
  Future<void> clearUserLocalCacheOnSignOut(String userId) async {
    await _localStorage.clearUserNotes(userId);
  }
}
