import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/supabase_service.dart';
import '../services/feedback_service.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const FeedbackDialog(),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  String _category = 'suggestion'; // suggestion | bug | other
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = SupabaseService.currentUser;
    if (user != null) {
      final email = user.email ?? '';
      final fullName = user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          '';
      if (fullName.isNotEmpty && email.isNotEmpty) {
        _emailController.text = '$fullName ($email)';
      } else if (email.isNotEmpty) {
        _emailController.text = email;
      } else if (fullName.isNotEmpty) {
        _emailController.text = fullName;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'suggestion':
        return LocaleKeys.feedbackCatSuggestion.tr();
      case 'bug':
        return LocaleKeys.feedbackCatBug.tr();
      case 'other':
      default:
        return LocaleKeys.feedbackCatOther.tr();
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'suggestion':
        return Icons.lightbulb_outline_rounded;
      case 'bug':
        return Icons.bug_report_outlined;
      case 'other':
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final emailOrLogin = _emailController.text.trim();
    final message = _messageController.text.trim();

    if (emailOrLogin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.feedbackErrorEmail.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.feedbackErrorEmpty.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await FeedbackService.submitFeedback(
      userEmail: emailOrLogin,
      category: _category,
      rating: _rating,
      message: message,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.of(context).pop(); // Close feedback dialog

    // Show Thank You Success Dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.feedbackSuccessTitle.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              LocaleKeys.feedbackSuccessMsg.tr(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthenticated = SupabaseService.isAuthenticated;

    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dialogBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textOnLight;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textOnLightSecondary;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: dialogBorder, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        color: AppColors.primaryCyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleKeys.feedbackTitle.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            LocaleKeys.feedbackSubtitle.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // User Identity (Automatic when signed in, or custom field when signed out)
                if (isAuthenticated) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryCyan.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 18,
                          color: AppColors.primaryCyan,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.feedbackSender.tr(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textMuted : AppColors.textOnLightMuted,
                                ),
                              ),
                              Text(
                                _emailController.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    LocaleKeys.feedbackEmailOrLogin.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      hintText: LocaleKeys.feedbackEmailHint.tr(),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMuted : AppColors.textOnLightMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.alternate_email_rounded,
                        size: 18,
                        color: AppColors.primaryCyan,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return LocaleKeys.feedbackErrorEmail.tr();
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Category Selector
                Text(
                  LocaleKeys.feedbackCategory.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['suggestion', 'bug', 'other'].map((cat) {
                    final isSelected = _category == cat;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryCyan.withValues(alpha: 0.18)
                                : inputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryCyan : inputBorder,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(cat),
                                size: 18,
                                color: isSelected ? AppColors.primaryCyan : textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getCategoryLabel(cat),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.primaryCyan : textPrimary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Rating Stars (1 to 5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.feedbackRating.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isActive = starValue <= _rating;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = starValue),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isActive
                                  ? const Color(0xFFFBBF24)
                                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                              size: 26,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message Text Field
                Text(
                  LocaleKeys.feedbackMessage.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 3,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    hintText: LocaleKeys.feedbackMessageHint.tr(),
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMuted : AppColors.textOnLightMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return LocaleKeys.feedbackErrorEmpty.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // Action Buttons (Cancel / Submit)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        LocaleKeys.cancel.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  LocaleKeys.feedbackSubmitting.tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.send_rounded, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  LocaleKeys.feedbackSubmit.tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
