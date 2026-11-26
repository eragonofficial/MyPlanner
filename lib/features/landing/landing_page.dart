import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/localization/locale_keys.dart';

class LandingPage extends StatelessWidget {
  final VoidCallback onSignInPressed;

  const LandingPage({super.key, required this.onSignInPressed});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildNavbar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Hero Section
                    _buildHeroSection(context, isDesktop),

                    const SizedBox(height: 48),

                    // Feature Showcase Cards
                    _buildFeatureShowcase(context, isDesktop),

                    const SizedBox(height: 60),

                    // Bottom Call to Action Banner
                    _buildBottomCta(context),

                    const SizedBox(height: 36),

                    // Footer
                    _buildFooter(context),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.darkBgSecondary,
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo & Title
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryCyan, AppColors.primaryGreen],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.timer_rounded, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            LocaleKeys.appName.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),

          const Spacer(),

          // 5-Language Switcher Pills
          _buildLanguageBar(context),

          const SizedBox(width: 14),

          // Sign In CTA Button
          ElevatedButton.icon(
            onPressed: onSignInPressed,
            icon: const Icon(Icons.login_rounded, size: 16),
            label: Text(
              LocaleKeys.signIn.tr(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageBar(BuildContext context) {
    final currentLocale = context.locale;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: LanguageManager.languages.map((item) {
          final isSelected = currentLocale.languageCode == item.locale.languageCode &&
              currentLocale.scriptCode == item.locale.scriptCode;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () {
                context.setLocale(item.locale);
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryCyan.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryCyan : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.flag, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      _getLanguageShortCode(item.code),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getLanguageShortCode(String code) {
    switch (code) {
      case 'uz-Latn':
        return 'UZ-L';
      case 'uz-Cyrl':
        return 'ЎЗ-К';
      case 'ru':
        return 'RU';
      case 'en':
        return 'EN';
      case 'ko':
        return 'KO';
      default:
        return code.toUpperCase();
    }
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 960),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 20,
        vertical: isDesktop ? 54 : 32,
      ),
      child: Column(
        children: [
          // Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryCyan, size: 14),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.landingHeroBadge.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Headline
          Text(
            LocaleKeys.landingHeroTitle.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 40 : 28,
              fontWeight: FontWeight.w900,
              height: 1.25,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),

          // Subtitle / Mission
          Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              LocaleKeys.landingHeroSubtitle.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // CTA Buttons
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onSignInPressed,
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text(
                  LocaleKeys.landingGetStarted.tr(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onSignInPressed,
                icon: const Icon(Icons.account_circle_outlined, size: 18),
                label: Text(
                  LocaleKeys.signIn.tr(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryCyan,
                  side: const BorderSide(color: AppColors.primaryCyan),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureShowcase(BuildContext context, bool isDesktop) {
    final features = [
      _FeatureData(
        icon: Icons.calendar_month_rounded,
        color: AppColors.primaryCyan,
        titleKey: LocaleKeys.landingFeaturePlanningTitle,
        descKey: LocaleKeys.landingFeaturePlanningDesc,
      ),
      _FeatureData(
        icon: Icons.insights_rounded,
        color: AppColors.primaryGreen,
        titleKey: LocaleKeys.landingFeatureDashboardTitle,
        descKey: LocaleKeys.landingFeatureDashboardDesc,
      ),
      _FeatureData(
        icon: Icons.timer_rounded,
        color: AppColors.accentAmber,
        titleKey: LocaleKeys.landingFeaturePomodoroTitle,
        descKey: LocaleKeys.landingFeaturePomodoroDesc,
      ),
      _FeatureData(
        icon: Icons.cloud_sync_rounded,
        color: AppColors.accentIndigo,
        titleKey: LocaleKeys.landingFeatureSyncTitle,
        descKey: LocaleKeys.landingFeatureSyncDesc,
      ),
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 1040),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: isDesktop
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.8,
              ),
              itemCount: features.length,
              itemBuilder: (context, i) => _buildFeatureCard(features[i]),
            )
          : Column(
              children: features
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildFeatureCard(f),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildFeatureCard(_FeatureData feature) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.icon, color: feature.color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            feature.titleKey.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feature.descKey.tr(),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 880),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryCyan.withValues(alpha: 0.15),
            AppColors.primaryGreen.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.primaryGreen, size: 36),
          const SizedBox(height: 14),
          Text(
            LocaleKeys.landingHeroTitle.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onSignInPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              LocaleKeys.landingGetStarted.tr(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Text(
      '${LocaleKeys.appName.tr()} • 2026',
      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final Color color;
  final String titleKey;
  final String descKey;

  _FeatureData({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.descKey,
  });
}
