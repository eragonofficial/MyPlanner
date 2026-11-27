import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/widgets/telegram_otp_dialog.dart';
import '../models/user_profile_model.dart';

class ProfileSettingsDialog extends StatefulWidget {
  final LocalStorageService? localStorage;
  final VoidCallback? onProfileUpdated;

  const ProfileSettingsDialog({
    super.key,
    this.localStorage,
    this.onProfileUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    LocalStorageService? localStorage,
    VoidCallback? onProfileUpdated,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ProfileSettingsDialog(
        localStorage: localStorage,
        onProfileUpdated: onProfileUpdated,
      ),
    );
  }

  @override
  State<ProfileSettingsDialog> createState() => _ProfileSettingsDialogState();
}

class _ProfileSettingsDialogState extends State<ProfileSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  LocalStorageService? _storage;
  UserProfileModel? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final storage = widget.localStorage ?? await LocalStorageService.create();
      _storage = storage;
      final fetched = await SupabaseService.fetchUserProfile(localStorage: storage);
      if (!mounted) return;

      setState(() {
        _profile = fetched;
        _nameController.text = fetched?.fullName ?? '';
        _phoneController.text = fetched?.phoneNumber ?? '';
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await SupabaseService.updateUserProfile(
        fullName: _nameController.text,
        phoneNumber: _phoneController.text,
        localStorage: _storage,
      );

      if (!mounted) return;
      setState(() {
        _profile = updated;
        _phoneController.text = updated.phoneNumber ?? '';
        _isSaving = false;
      });

      widget.onProfileUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            LocaleKeys.profileSavedSuccess.tr(),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _linkTelegram() async {
    await TelegramOtpDialog.launchAndShow(
      context,
      customTitle: LocaleKeys.profileLinkTelegramBtn.tr(),
      onVerifyCode: (code) async {
        await SupabaseService.linkTelegramAccountWithOtp(code: code);
      },
      onAuthSuccess: () async {
        await _loadProfile();
        widget.onProfileUpdated?.call();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              LocaleKeys.profileTelegramLinkedSuccess.tr(),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dialogBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textOnLight;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.textOnLightSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.textOnLightMuted;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final email = _profile?.email ?? SupabaseService.currentUserEmail ?? '-';
    final isTelegramLinked = _profile?.isTelegramLinked ??
        (SupabaseService.currentUserTelegramId != null);
    final tgUsername = _profile?.telegramUsername;
    final tgId = _profile?.telegramId ?? SupabaseService.currentUserTelegramId;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: dialogBorder, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryCyan),
                  ),
                )
              : Form(
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
                              Icons.manage_accounts_rounded,
                              color: AppColors.primaryCyan,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              LocaleKeys.profileSettingsTitle.tr(),
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
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accentRed.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.accentRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(fontSize: 12, color: textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Current Email Read-Only Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dialogBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: AppColors.primaryCyan,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LocaleKeys.email.tr(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: textMuted,
                                    ),
                                  ),
                                  Text(
                                    email,
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
                      const SizedBox(height: 16),

                      // Full Name Input
                      Text(
                        LocaleKeys.profileFullName.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputBg,
                          hintText: LocaleKeys.profileFullNameHint.tr(),
                          hintStyle: TextStyle(fontSize: 13, color: textMuted),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 19,
                            color: AppColors.primaryCyan,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dialogBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dialogBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryCyan,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Number Input (+998 E.164 formatting)
                      Text(
                        LocaleKeys.profilePhoneNumber.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputBg,
                          hintText: LocaleKeys.profilePhoneHint.tr(),
                          hintStyle: TextStyle(fontSize: 13, color: textMuted),
                          helperText: LocaleKeys.profilePhoneHelper.tr(),
                          helperMaxLines: 2,
                          helperStyle: TextStyle(fontSize: 11, color: textSecondary),
                          prefixIcon: const Icon(
                            Icons.phone_android_rounded,
                            size: 19,
                            color: AppColors.primaryGreen,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dialogBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dialogBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryGreen,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (!UserProfileModel.isValidPhone(val)) {
                            return LocaleKeys.profilePhoneInvalid.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Linked Telegram Status Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isTelegramLinked
                              ? AppColors.primaryGreen.withValues(alpha: 0.1)
                              : kTelegramBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isTelegramLinked
                                ? AppColors.primaryGreen.withValues(alpha: 0.4)
                                : kTelegramBlue.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  size: 18,
                                  color: isTelegramLinked
                                      ? AppColors.primaryGreen
                                      : kTelegramBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    LocaleKeys.profileTelegramStatus.tr(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isTelegramLinked
                                            ? AppColors.primaryGreen
                                            : AppColors.accentAmber)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isTelegramLinked
                                        ? LocaleKeys.profileTelegramLinked.tr()
                                        : LocaleKeys.profileTelegramNotLinked.tr(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isTelegramLinked
                                          ? AppColors.primaryGreen
                                          : AppColors.accentAmber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isTelegramLinked) ...[
                              const SizedBox(height: 8),
                              Text(
                                tgUsername != null && tgUsername.isNotEmpty
                                    ? '@${tgUsername.replaceFirst('@', '')} (ID: ${tgId ?? ''})'
                                    : 'Telegram ID: ${tgId ?? ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _linkTelegram,
                                icon: const Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  LocaleKeys.profileLinkTelegramBtn.tr(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kTelegramBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Footer Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: textSecondary,
                            ),
                            child: Text(LocaleKeys.cancel.tr()),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.save_rounded, size: 17),
                            label: Text(
                              LocaleKeys.save.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryCyan,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
