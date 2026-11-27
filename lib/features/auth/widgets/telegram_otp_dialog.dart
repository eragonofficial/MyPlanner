import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/supabase_service.dart';

const Color kTelegramBlue = Color(0xFF2AABEE);

/// Shared branded Telegram sign-in button used on AuthScreen and AuthGuardModal.
class TelegramSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const TelegramSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: const Icon(Icons.send_rounded, size: 19, color: Colors.white),
      label: Text(
        LocaleKeys.authTelegramButton.tr(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: kTelegramBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kTelegramBlue.withValues(alpha: 0.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

/// Opens `@my_planner_uz_bot` in Telegram and shows a 6-digit OTP verification dialog.
class TelegramOtpDialog extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const TelegramOtpDialog({super.key, this.onAuthSuccess});

  static Future<void> _openTelegramBot() async {
    final uri = Uri.parse(SupabaseConstants.telegramBotUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: ignore if platform cannot auto-launch; dialog has a retry button
    }
  }

  static Future<bool?> launchAndShow(
    BuildContext context, {
    VoidCallback? onAuthSuccess,
  }) async {
    // Trigger launch immediately inside the user's tap gesture
    _openTelegramBot();

    if (!context.mounted) return false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => TelegramOtpDialog(onAuthSuccess: onAuthSuccess),
    );
  }

  @override
  State<TelegramOtpDialog> createState() => _TelegramOtpDialogState();
}

class _TelegramOtpDialogState extends State<TelegramOtpDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorText = LocaleKeys.invalidOtp.tr());
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      await SupabaseService.verifyTelegramOtp(code: code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onAuthSuccess?.call();
    } on AuthException catch (e) {
      if (!mounted) return;
      final lower = e.message.toLowerCase();
      setState(() {
        _errorText = (lower.contains('invalid') || lower.contains('expired'))
            ? LocaleKeys.telegramOtpInvalid.tr()
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dialogBorder =
        isDark ? kTelegramBlue.withValues(alpha: 0.45) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textOnLight;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.textOnLightSecondary;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: dialogBorder, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                      color: kTelegramBlue.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kTelegramBlue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: kTelegramBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      LocaleKeys.telegramOtpTitle.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                    onPressed:
                        _isVerifying ? null : () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Instructions box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kTelegramBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: kTelegramBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      LocaleKeys.telegramOtpSubtitle.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: TelegramOtpDialog._openTelegramBot,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(
                        LocaleKeys.telegramOpenBot.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTelegramBlue,
                        side: BorderSide(
                          color: kTelegramBlue.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 6-Digit OTP Input
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _submitCode(),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  counterText: '',
                  hintText: LocaleKeys.otpHint.tr(),
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textOnLightMuted,
                    fontSize: 16,
                    letterSpacing: 4,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: dialogBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: kTelegramBlue, width: 1.6),
                  ),
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentRed.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: AppColors.accentRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: TextStyle(fontSize: 12, color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Cancel / Verify buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isVerifying ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                    ),
                    child: Text(LocaleKeys.cancel.tr()),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isVerifying ? null : _submitCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTelegramBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            LocaleKeys.verifyCode.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
