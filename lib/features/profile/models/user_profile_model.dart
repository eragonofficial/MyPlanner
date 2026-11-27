class UserProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final int? telegramId;
  final String? telegramUsername;
  final String? avatarUrl;
  final DateTime? updatedAt;

  const UserProfileModel({
    required this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.telegramId,
    this.telegramUsername,
    this.avatarUrl,
    this.updatedAt,
  });

  bool get isTelegramLinked => telegramId != null;

  /// Normalizes raw phone inputs into E.164 format (e.g. +998901234567).
  static String? normalizePhoneE164(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length == 9) {
      return '+998$digits';
    }
    return '+$digits';
  }

  /// Empty phone is allowed (optional), otherwise requires valid E.164 digits.
  static bool isValidPhone(String? raw) {
    if (raw == null || raw.trim().isEmpty) return true;
    final normalized = normalizePhoneE164(raw);
    if (normalized == null) return false;
    return RegExp(r'^\+[1-9]\d{8,14}$').hasMatch(normalized);
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final rawTelegramId = json['telegram_id'];
    int? parsedTelegramId;
    if (rawTelegramId is int) {
      parsedTelegramId = rawTelegramId;
    } else if (rawTelegramId is num) {
      parsedTelegramId = rawTelegramId.toInt();
    } else if (rawTelegramId is String) {
      parsedTelegramId = int.tryParse(rawTelegramId);
    }

    return UserProfileModel(
      id: (json['id'] as String?) ?? '',
      fullName: (json['full_name'] as String?)?.trim().isNotEmpty == true
          ? (json['full_name'] as String).trim()
          : null,
      email: (json['email'] as String?)?.trim().isNotEmpty == true
          ? (json['email'] as String).trim()
          : null,
      phoneNumber: normalizePhoneE164(json['phone_number'] as String?),
      telegramId: parsedTelegramId,
      telegramUsername:
          (json['telegram_username'] as String?)?.trim().isNotEmpty == true
              ? (json['telegram_username'] as String).trim()
              : null,
      avatarUrl: (json['avatar_url'] as String?)?.trim().isNotEmpty == true
          ? (json['avatar_url'] as String).trim()
          : null,
      updatedAt: json['updated_at'] is String
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'telegram_id': telegramId,
      'telegram_username': telegramUsername,
      'avatar_url': avatarUrl,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
