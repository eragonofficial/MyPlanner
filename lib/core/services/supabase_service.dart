import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class SupabaseService {
  static bool _isInitialized = false;

  static bool get isReady => _isInitialized && SupabaseConstants.isConfigured;

  static SupabaseClient? get client {
    if (!isReady) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Auth getters
  static User? get currentUser => client?.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
  static String? get currentUserId => currentUser?.id;
  static String? get currentUserEmail => currentUser?.email;
  static String? get currentUserPhone => currentUser?.phone;

  static String? get currentUserDisplayName {
    if (currentUserEmail != null && currentUserEmail!.isNotEmpty) {
      return currentUserEmail;
    }
    if (currentUserPhone != null && currentUserPhone!.isNotEmpty) {
      return currentUserPhone;
    }
    return currentUser?.id;
  }

  static Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  static Future<void> initialize() async {
    if (!SupabaseConstants.isConfigured) {
      _isInitialized = false;
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        anonKey: SupabaseConstants.supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      _isInitialized = false;
      debugPrint('Supabase initialization failed: $e');
    }
  }

  // Auth Methods
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final supabase = client;
    if (supabase == null) {
      throw Exception('Supabase is not initialized');
    }
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final supabase = client;
    if (supabase == null) {
      throw Exception('Supabase is not initialized');
    }
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<bool> signInWithGoogle() async {
    final supabase = client;
    if (supabase == null) {
      throw Exception('Supabase is not initialized');
    }
    return await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.myplanner://login-callback',
    );
  }

  static Future<void> sendEmailOtp(String email) async {
    final supabase = client;
    if (supabase == null) {
      throw Exception('Supabase is not initialized');
    }
    await supabase.auth.signInWithOtp(
      email: email,
    );
  }

  static Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final supabase = client;
    if (supabase == null) {
      throw Exception('Supabase is not initialized');
    }
    return await supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  static Future<void> sendPhoneOtp(String phone) async {
    final supabase = client;
    if (supabase == null) {
      throw Exception('Supabase is not initialized');
    }
    await supabase.auth.signInWithOtp(
      phone: phone,
    );
  }

  static Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    final supabase = client;
    if (supabase == null) {
      throw Exception('Supabase is not initialized');
    }
    return await supabase.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  static Future<void> signOut() async {
    final supabase = client;
    if (supabase == null) return;
    await supabase.auth.signOut();
  }

  // Fetch all notes from Supabase (with user_id filter if authenticated)
  static Future<List<Map<String, dynamic>>?> fetchNotes() async {
    final supabase = client;
    if (supabase == null) return null;

    try {
      var query = supabase.from(SupabaseConstants.tableNameNotes).select();

      if (isAuthenticated && currentUserId != null) {
        query = query.or('user_id.eq.$currentUserId,user_id.is.null');
      }

      final response = await query.order(SupabaseConstants.colCreatedAt, ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase fetch error: $e');
      // If table doesn't have user_id column yet, retry plain query
      try {
        final fallbackResponse = await supabase
            .from(SupabaseConstants.tableNameNotes)
            .select()
            .order(SupabaseConstants.colCreatedAt, ascending: false);
        return List<Map<String, dynamic>>.from(fallbackResponse);
      } catch (err) {
        debugPrint('Supabase fallback fetch error: $err');
        return null;
      }
    }
  }

  // Insert note into Supabase
  static Future<bool> insertNote(Map<String, dynamic> noteData) async {
    final supabase = client;
    if (supabase == null) return false;

    try {
      final payload = Map<String, dynamic>.from(noteData);
      if (isAuthenticated && currentUserId != null) {
        payload[SupabaseConstants.colUserId] = currentUserId;
      }

      await supabase.from(SupabaseConstants.tableNameNotes).insert(payload);
      return true;
    } catch (e) {
      debugPrint('Supabase insert error: $e');
      // If user_id or reminder_time column doesn't exist, try inserting without them
      try {
        final fallbackPayload = Map<String, dynamic>.from(noteData)
          ..remove(SupabaseConstants.colUserId)
          ..remove(SupabaseConstants.colReminderTime);
        await supabase.from(SupabaseConstants.tableNameNotes).insert(fallbackPayload);
        return true;
      } catch (err) {
        debugPrint('Supabase fallback insert error: $err');
        return false;
      }
    }
  }

  // Update note in Supabase
  static Future<bool> updateNote(String id, Map<String, dynamic> noteData) async {
    final supabase = client;
    if (supabase == null) return false;

    try {
      final payload = Map<String, dynamic>.from(noteData);
      if (isAuthenticated && currentUserId != null) {
        payload[SupabaseConstants.colUserId] = currentUserId;
      }

      await supabase
          .from(SupabaseConstants.tableNameNotes)
          .update(payload)
          .eq(SupabaseConstants.colId, id);
      return true;
    } catch (e) {
      debugPrint('Supabase update error: $e');
      try {
        final fallbackPayload = Map<String, dynamic>.from(noteData)
          ..remove(SupabaseConstants.colUserId)
          ..remove(SupabaseConstants.colReminderTime);
        await supabase
            .from(SupabaseConstants.tableNameNotes)
            .update(fallbackPayload)
            .eq(SupabaseConstants.colId, id);
        return true;
      } catch (err) {
        debugPrint('Supabase fallback update error: $err');
        return false;
      }
    }
  }

  // Toggle note completion in Supabase
  static Future<bool> toggleCompleted(String id, bool isCompleted) async {
    final supabase = client;
    if (supabase == null) return false;

    try {
      await supabase
          .from(SupabaseConstants.tableNameNotes)
          .update({
            SupabaseConstants.colIsCompleted: isCompleted,
            SupabaseConstants.colUpdatedAt: DateTime.now().toIso8601String(),
          })
          .eq(SupabaseConstants.colId, id);
      return true;
    } catch (e) {
      debugPrint('Supabase toggle error: $e');
      return false;
    }
  }

  // Delete note from Supabase
  static Future<bool> deleteNote(String id) async {
    final supabase = client;
    if (supabase == null) return false;

    try {
      await supabase
          .from(SupabaseConstants.tableNameNotes)
          .delete()
          .eq(SupabaseConstants.colId, id);
      return true;
    } catch (e) {
      debugPrint('Supabase delete error: $e');
      return false;
    }
  }
}
