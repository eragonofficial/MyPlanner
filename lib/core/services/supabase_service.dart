import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../../features/profile/models/user_profile_model.dart';
import 'local_storage_service.dart';

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
    final fullName = currentUser?.userMetadata?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final username = currentUser?.userMetadata?['username'] as String? ??
        currentUser?.userMetadata?['telegram_username'] as String?;
    if (username != null && username.trim().isNotEmpty) {
      return '@${username.trim().replaceFirst('@', '')}';
    }
    if (currentUserEmail != null && currentUserEmail!.isNotEmpty) {
      return currentUserEmail;
    }
    if (currentUserPhone != null && currentUserPhone!.isNotEmpty) {
      return currentUserPhone;
    }
    return currentUser?.id;
  }

  static int? get currentUserTelegramId {
    final raw = currentUser?.userMetadata?['telegram_id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static Future<UserProfileModel?> fetchUserProfile({
    LocalStorageService? localStorage,
  }) async {
    final user = currentUser;
    final supabase = client;
    if (user == null) return null;

    final meta = user.userMetadata ?? {};
    final cachedJson = localStorage?.getUserProfile(userId: user.id);
    final cachedProfile =
        cachedJson != null ? UserProfileModel.fromJson(cachedJson) : null;

    // Fallback constructed from live Auth user metadata + cached values
    final fallbackProfile = UserProfileModel(
      id: user.id,
      fullName: (meta['full_name'] as String?) ??
          (meta['name'] as String?) ??
          cachedProfile?.fullName,
      email: user.email ?? cachedProfile?.email,
      phoneNumber: UserProfileModel.normalizePhoneE164(
        (meta['phone_number'] as String?) ??
            user.phone ??
            cachedProfile?.phoneNumber,
      ),
      telegramId: currentUserTelegramId ?? cachedProfile?.telegramId,
      telegramUsername: (meta['telegram_username'] as String?) ??
          (meta['username'] as String?) ??
          cachedProfile?.telegramUsername,
      avatarUrl: (meta['avatar_url'] as String?) ??
          (meta['picture'] as String?) ??
          cachedProfile?.avatarUrl,
      updatedAt: cachedProfile?.updatedAt,
    );

    if (supabase == null) return fallbackProfile;

    try {
      final row = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (row != null) {
        final merged = UserProfileModel(
          id: user.id,
          fullName: (row['full_name'] as String?) ?? fallbackProfile.fullName,
          email: (row['email'] as String?) ?? fallbackProfile.email,
          phoneNumber: UserProfileModel.normalizePhoneE164(
                row['phone_number'] as String?,
              ) ??
              fallbackProfile.phoneNumber,
          telegramId: UserProfileModel.fromJson(row).telegramId ??
              fallbackProfile.telegramId,
          telegramUsername: (row['telegram_username'] as String?) ??
              fallbackProfile.telegramUsername,
          avatarUrl: (row['avatar_url'] as String?) ?? fallbackProfile.avatarUrl,
          updatedAt: row['updated_at'] is String
              ? DateTime.tryParse(row['updated_at'] as String)
              : null,
        );
        await localStorage?.saveUserProfile(merged.toJson(), userId: user.id);
        return merged;
      }
    } catch (e) {
      debugPrint('fetchUserProfile note: $e');
    }

    await localStorage?.saveUserProfile(fallbackProfile.toJson(), userId: user.id);
    return fallbackProfile;
  }

  static Future<UserProfileModel> updateUserProfile({
    required String fullName,
    String? phoneNumber,
    LocalStorageService? localStorage,
  }) async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) {
      throw Exception('User must be signed in to update profile');
    }

    final cleanName = fullName.trim();
    final normalizedPhone = UserProfileModel.normalizePhoneE164(phoneNumber);
    final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
    meta['full_name'] = cleanName.isNotEmpty ? cleanName : null;
    meta['phone_number'] = normalizedPhone;

    // 1. Update Auth user metadata
    await supabase.auth.updateUser(UserAttributes(data: meta));

    // 2. Upsert into public.profiles
    final profilePayload = <String, dynamic>{
      'id': user.id,
      'full_name': cleanName.isNotEmpty ? cleanName : null,
      'email': user.email,
      'phone_number': normalizedPhone,
      'telegram_id': currentUserTelegramId,
      'telegram_username': (meta['telegram_username'] as String?) ??
          (meta['username'] as String?),
      'avatar_url': (meta['avatar_url'] as String?) ?? (meta['picture'] as String?),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('profiles').upsert(profilePayload);
    } catch (e) {
      debugPrint('profiles upsert warning: $e');
      // Surface uniqueness conflicts clearly to caller
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique') || msg.contains('duplicate')) {
        throw Exception('This phone number is already linked to another account.');
      }
    }

    final updated = UserProfileModel.fromJson(profilePayload);
    await localStorage?.saveUserProfile(updated.toJson(), userId: user.id);
    return updated;
  }

  static Future<Map<String, dynamic>> linkTelegramAccountWithOtp({
    required String code,
  }) async {
    final supabase = client;
    final session = supabase?.auth.currentSession;
    final user = currentUser;
    if (supabase == null || session == null || user == null) {
      throw const AuthException('User must be signed in to link Telegram');
    }

    final response = await http
        .post(
          Uri.parse(SupabaseConstants.telegramOtpFunctionUrl),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConstants.supabaseAnonKey,
            'Authorization': 'Bearer ${session.accessToken}',
          },
          body: jsonEncode({
            'code': code.trim(),
            'link_user_id': user.id,
          }),
        )
        .timeout(const Duration(seconds: 15));

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || data['linked'] != true) {
      throw AuthException(
        (data['error'] as String?) ?? 'Invalid or expired Telegram code',
      );
    }

    // Refresh session so updated user_metadata (telegram_id / username / phone) takes effect immediately
    try {
      await supabase.auth.refreshSession();
    } catch (_) {}

    return data;
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

  static Future<AuthResponse> verifyTelegramOtp({required String code}) async {
    final supabase = client;
    if (supabase == null) {
      throw Exception('Supabase is not initialized');
    }

    final response = await http
        .post(
          Uri.parse(SupabaseConstants.telegramOtpFunctionUrl),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConstants.supabaseAnonKey,
            'Authorization': 'Bearer ${SupabaseConstants.supabaseAnonKey}',
          },
          body: jsonEncode({'code': code.trim()}),
        )
        .timeout(const Duration(seconds: 15));

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    final refreshToken = data['refresh_token'] as String? ??
        (data['session'] is Map ? data['session']['refresh_token'] as String? : null);

    if (response.statusCode != 200 || refreshToken == null || refreshToken.isEmpty) {
      throw AuthException(
        (data['error'] as String?) ?? 'Invalid or expired Telegram code',
      );
    }

    return await supabase.auth.setSession(refreshToken);
  }

  static Future<void> signOut() async {
    final supabase = client;
    if (supabase == null) return;
    await supabase.auth.signOut();
  }

  // Update user profile/metadata (e.g. daily reminder settings)
  static Future<void> syncUserReminderPreferences({
    required bool enabled,
    required String time,
    String? message,
  }) async {
    final supabase = client;
    if (supabase == null || !isAuthenticated) return;
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'daily_reminder_enabled': enabled,
            'daily_reminder_time': time,
            if (message != null && message.isNotEmpty) 'daily_reminder_message': message,
          },
        ),
      );
    } catch (e) {
      debugPrint('Supabase reminder preferences sync error: $e');
    }
  }

  // Realtime subscription
  static RealtimeChannel? _realtimeChannel;

  static void subscribeToNotes(VoidCallback onRemoteChange) {
    if (!isReady || client == null) return;
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = client!
          .channel('public:${SupabaseConstants.tableNameNotes}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: SupabaseConstants.tableNameNotes,
            callback: (payload) {
              debugPrint('Supabase realtime change event: ${payload.eventType}');
              onRemoteChange();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Supabase realtime subscription notice: $e');
    }
  }

  static void unsubscribeRealtime() {
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    } catch (_) {}
  }

  // Fetch all notes from Supabase (Single Source of Truth filtered by user_id)
  static Future<List<Map<String, dynamic>>?> fetchNotes() async {
    final supabase = client;
    if (supabase == null) return null;

    try {
      var query = supabase.from(SupabaseConstants.tableNameNotes).select();

      if (isAuthenticated && currentUserId != null) {
        // Query strictly for authenticated user or legacy unassigned notes
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

  // Safe Upsert Note: inserts if new, updates if exists (prevents primary key duplication)
  static Future<bool> upsertNote(Map<String, dynamic> noteData) async {
    final supabase = client;
    if (supabase == null) return false;

    try {
      final payload = Map<String, dynamic>.from(noteData);
      if (isAuthenticated && currentUserId != null) {
        payload[SupabaseConstants.colUserId] = currentUserId;
      }

      await supabase
          .from(SupabaseConstants.tableNameNotes)
          .upsert(payload, onConflict: SupabaseConstants.colId);
      return true;
    } catch (e) {
      debugPrint('Supabase upsert error: $e');
      try {
        final fallbackPayload = Map<String, dynamic>.from(noteData)
          ..remove(SupabaseConstants.colUserId)
          ..remove(SupabaseConstants.colReminderTime);
        await supabase
            .from(SupabaseConstants.tableNameNotes)
            .upsert(fallbackPayload, onConflict: SupabaseConstants.colId);
        return true;
      } catch (err) {
        debugPrint('Supabase fallback upsert error: $err');
        return false;
      }
    }
  }

  // Insert note into Supabase (calls upsert for zero data loss)
  static Future<bool> insertNote(Map<String, dynamic> noteData) async {
    return await upsertNote(noteData);
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
