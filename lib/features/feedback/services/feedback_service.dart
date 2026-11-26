import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/supabase_service.dart';

class FeedbackService {
  static const String webhookUrl =
      'https://script.google.com/macros/s/AKfycbxtAlYt0QOBySViyXgeObDzLrc-y-e6UQryYsVAkwdDTbhJ2xEYpQyoyd92j2Fa2_psqg/exec';

  /// Safe cross-platform platform name ('web', 'android', 'ios', etc.)
  static String get currentPlatform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'other';
    }
  }

  /// Sends feedback to Google Sheets via Google Apps Script Webhook
  /// and mirrors to Supabase `feedback` table for dual reliability.
  static Future<bool> submitFeedback({
    required String userEmail,
    required String category,
    required int rating,
    required String message,
  }) async {
    final payload = {
      'user_email': userEmail.trim(),
      'category': category.trim(),
      'rating': rating,
      'message': message.trim(),
      'platform': currentPlatform,
    };

    bool sheetsSuccess = false;

    // 1. Post to Google Sheets Webhook
    try {
      final uri = Uri.parse(webhookUrl);
      // 'text/plain;charset=utf-8' prevents CORS preflight OPTIONS blocking on Web
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'text/plain;charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      // Google Apps Script usually returns 200 or 302
      if (response.statusCode >= 200 && response.statusCode < 400) {
        sheetsSuccess = true;
      } else {
        debugPrint('Google Sheets webhook returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Google Sheets webhook request error: $e');
    }

    // 2. Dual Reliability: Mirror to Supabase `feedback` table if configured
    try {
      if (SupabaseService.client != null) {
        await SupabaseService.client!.from('feedback').insert({
          'user_id': SupabaseService.currentUser?.id,
          'user_email': userEmail.trim(),
          'category': category.trim(),
          'rating': rating,
          'message': message.trim(),
          'platform': currentPlatform,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Supabase table might not exist yet; Google Sheets is the primary destination
      debugPrint('Supabase feedback insert note: $e');
    }

    return sheetsSuccess;
  }
}
