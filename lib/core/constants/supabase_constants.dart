class SupabaseConstants {
  static const String supabaseUrl = 'https://mrwwmackzhsscsozcoay.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_l9WwCJFgNKn-ePTyLDSONw_k7ilN8Hs';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id');

  // Database Table and Column names
  static const String tableNameNotes = 'notes';
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colTitle = 'title';
  static const String colDescription = 'description';
  static const String colPeriodType = 'period_type';
  static const String colTargetDate = 'target_date';
  static const String colPriority = 'priority';
  static const String colIsCompleted = 'is_completed';
  static const String colReminderTime = 'reminder_time';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
}
