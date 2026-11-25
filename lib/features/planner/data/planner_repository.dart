import 'package:flutter/foundation.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/note_model.dart';

class PlannerRepository {
  final LocalStorageService _localStorage;

  PlannerRepository(this._localStorage);

  bool get isCloudSyncAvailable => SupabaseService.isReady;

  /// Loads cached notes immediately, then attempts to fetch fresh data from Supabase
  Future<List<NoteModel>> getNotes() async {
    // 1. Read local cache first for instant offline render
    final localMaps = _localStorage.getNotes();
    List<NoteModel> notes = localMaps.map((m) => NoteModel.fromMap(m)).toList();

    // 2. Try fetching from Supabase if online
    if (SupabaseService.isReady) {
      try {
        final remoteMaps = await SupabaseService.fetchNotes();
        if (remoteMaps != null) {
          // If remote returned notes, merge and update local cache
          final remoteNotes = remoteMaps.map((m) => NoteModel.fromMap(m)).toList();

          // Merge: remote notes take precedence, but keep locally created notes not yet synced
          final Map<String, NoteModel> merged = {};
          for (final n in notes) {
            merged[n.id] = n;
          }
          for (final rn in remoteNotes) {
            merged[rn.id] = rn;
          }

          notes = merged.values.toList();
          await _localStorage.saveNotes(notes.map((n) => n.toMap()).toList());
          await _localStorage.setLastSync(DateTime.now());
        }
      } catch (e) {
        debugPrint('Supabase fetch failed, continuing with local cache: $e');
      }
    }

    return notes;
  }

  /// Create: Saves note locally immediately, then inserts into Supabase
  Future<bool> addNote(NoteModel note, List<NoteModel> currentNotes) async {
    final updatedList = [note, ...currentNotes];
    await _localStorage.saveNotes(updatedList.map((n) => n.toMap()).toList());

    if (SupabaseService.isReady) {
      try {
        await SupabaseService.insertNote(note.toMap());
      } catch (e) {
        debugPrint('Supabase insert queued locally: $e');
      }
    }
    return true;
  }

  /// Update: Updates note locally immediately, then updates in Supabase
  Future<bool> updateNote(NoteModel note, List<NoteModel> currentNotes) async {
    final index = currentNotes.indexWhere((n) => n.id == note.id);
    if (index == -1) return false;

    final updatedList = List<NoteModel>.from(currentNotes);
    updatedList[index] = note;

    await _localStorage.saveNotes(updatedList.map((n) => n.toMap()).toList());

    if (SupabaseService.isReady) {
      try {
        await SupabaseService.updateNote(note.id, note.toMap());
      } catch (e) {
        debugPrint('Supabase update queued locally: $e');
      }
    }
    return true;
  }

  /// Toggle is_completed: Updates boolean locally and in Supabase
  Future<bool> toggleComplete(NoteModel note, List<NoteModel> currentNotes) async {
    final updated = note.copyWith(isCompleted: !note.isCompleted);
    final index = currentNotes.indexWhere((n) => n.id == note.id);
    if (index == -1) return false;

    final updatedList = List<NoteModel>.from(currentNotes);
    updatedList[index] = updated;

    await _localStorage.saveNotes(updatedList.map((n) => n.toMap()).toList());

    if (SupabaseService.isReady) {
      try {
        await SupabaseService.toggleCompleted(note.id, updated.isCompleted);
      } catch (e) {
        debugPrint('Supabase toggle queued locally: $e');
      }
    }
    return true;
  }

  /// Delete: Deletes note locally immediately, then deletes from Supabase
  Future<bool> deleteNote(String noteId, List<NoteModel> currentNotes) async {
    final updatedList = currentNotes.where((n) => n.id != noteId).toList();
    await _localStorage.saveNotes(updatedList.map((n) => n.toMap()).toList());

    if (SupabaseService.isReady) {
      try {
        await SupabaseService.deleteNote(noteId);
      } catch (e) {
        debugPrint('Supabase delete queued locally: $e');
      }
    }
    return true;
  }

  /// Syncs all locally cached notes up to Supabase (e.g. after user logs in)
  Future<void> syncLocalNotesToCloud() async {
    if (!SupabaseService.isReady) return;
    try {
      final localMaps = _localStorage.getNotes();
      for (final map in localMaps) {
        await SupabaseService.insertNote(map);
      }
    } catch (e) {
      debugPrint('Sync local to cloud note failed: $e');
    }
  }
}
