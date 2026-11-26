import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Email & OTP
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  String? _sentEmail;

  // Countdown timer for Resend Code
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _countdownSeconds = 0);
      } else {
        if (mounted) setState(() => _countdownSeconds--);
      }
    });
  }

  void _onSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
    widget.onAuthSuccess?.call();
    Navigator.of(context).pop(true);
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.signInWithGoogle();
      // On web/redirect flow, authStateChanges handles the session
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendEmailOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.sendEmailOtp(email);
      setState(() {
        _otpSent = true;
        _sentEmail = email;
      });
      _startCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.darkBgSecondary,
            content: Text(
              LocaleKeys.codeSentTo.tr(args: [email]),
              style: const TextStyle(color: AppColors.primaryCyan),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() => _errorMessage = LocaleKeys.invalidOtp.tr());
      return;
    }

    if (_sentEmail == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.verifyEmailOtp(
        email: _sentEmail!,
        token: otp,
      );
      _onSuccess(LocaleKeys.signInSuccess.tr());
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(
          LocaleKeys.authTitle.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header logo & title
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryCyan, AppColors.primaryGreen],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: Colors.black, size: 32),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                LocaleKeys.authSubtitle.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.accentRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Google Sign-In Button (Prominent at top)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitGoogle,
                icon: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                label: Text(
                  LocaleKeys.authGoogleButton.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBgSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.glassBorder),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Divider "or continue with"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.glassBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      LocaleKeys.orDivider.tr(),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.glassBorder)),
                ],
              ),

              const SizedBox(height: 18),

              // Email 6-digit OTP Section
              _otpSent ? _buildOtpVerificationSection() : _buildEmailInputSection(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInputSection() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.email.tr(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
              hintText: LocaleKeys.emailHint.tr(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return LocaleKeys.requiredField.tr();
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                return LocaleKeys.invalidEmail.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: _isLoading ? null : _sendEmailOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                  )
                : Text(
                    LocaleKeys.sendCode.tr(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationSection() {
    final canResend = _countdownSeconds == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sent email info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _sentEmail ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _countdownTimer?.cancel();
                      setState(() {
                        _otpSent = false;
                        _otpController.clear();
                        _errorMessage = null;
                        _countdownSeconds = 0;
                      });
                    },
                    child: Text(
                      LocaleKeys.changeEmail.tr(),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                LocaleKeys.codeSentTo.tr(args: [_sentEmail ?? '']),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          LocaleKeys.enterOtp.tr(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            hintText: '123456',
            hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), letterSpacing: 8),
          ),
        ),
        const SizedBox(height: 18),

        // Verify Code Button
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyEmailOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                )
              : Text(
                  LocaleKeys.verifyCode.tr(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 12),

        // Resend Code with 60-second countdown
        Center(
          child: canResend
              ? TextButton(
                  onPressed: _isLoading ? null : _sendEmailOtp,
                  child: Text(
                    LocaleKeys.resendCode.tr(),
                    style: const TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                )
              : Text(
                  LocaleKeys.resendCodeIn.tr(args: ['$_countdownSeconds']),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
        ),
      ],
    );
  }
}
