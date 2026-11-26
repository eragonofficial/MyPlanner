import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/localization/locale_keys.dart';
import 'widgets/aurora_particle_background.dart';
import 'widgets/interactive_glass_card.dart';
import 'widgets/interactive_try_live_widget.dart';
import 'widgets/shimmer_cta_button.dart';
import '../../../shared/widgets/pulsing_badge.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback onSignInPressed;

  const LandingPage({super.key, required this.onSignInPressed});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: AuroraParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Floating Glass Navigation Bar
              _buildNavbar(context),

              // Scrollable SaaS Showcase Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Hero Section
                          _buildHeroSection(context, isDesktop),

                          const SizedBox(height: 24),

                          // "Try It Live" Mini-Sandbox Interactive Widget
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: InteractiveTryLiveWidget(
                              onStartPlanning: widget.onSignInPressed,
                            ),
                          ),

                          const SizedBox(height: 64),

                          // 3D Tilt Feature Showcase Cards
                          _buildFeatureShowcase(context, isDesktop),

                          const SizedBox(height: 64),

                          // Bottom Call to Action Banner
                          _buildBottomCta(context),

                          const SizedBox(height: 48),

                          // Footer
                          _buildFooter(context),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary.withValues(alpha: 0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo & Title with Gradient Aura
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
                  color: AppColors.primaryCyan.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
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
            onPressed: widget.onSignInPressed,
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
        vertical: isDesktop ? 36 : 24,
      ),
      child: Column(
        children: [
          // Glowing Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
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

          // Main Headline with Gradient Shimmer
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.textPrimary,
                Colors.white,
                AppColors.primaryCyan.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              LocaleKeys.landingHeroTitle.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 44 : 30,
                fontWeight: FontWeight.w900,
                height: 1.2,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Subtitle / Mission statement
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
          const SizedBox(height: 28),

          // Primary Shimmer CTA Buttons
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ShimmerCtaButton(
                onPressed: widget.onSignInPressed,
                label: LocaleKeys.landingGetStarted.tr(),
                icon: Icons.rocket_launch_rounded,
                primaryColor: AppColors.primaryGreen,
                textColor: Colors.black,
              ),
              OutlinedButton.icon(
                onPressed: widget.onSignInPressed,
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
                crossAxisSpacing: 22,
                mainAxisSpacing: 22,
                childAspectRatio: 1.85,
              ),
              itemCount: features.length,
              itemBuilder: (context, i) => _buildFeatureCard(features[i]),
            )
          : Column(
              children: features
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _buildFeatureCard(f),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildFeatureCard(_FeatureData feature) {
    return InteractiveGlassCard(
      accentColor: feature.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulsingBadge(
            glowColor: feature.color,
            maxScale: 1.05,
            duration: const Duration(milliseconds: 2400),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: feature.color.withValues(alpha: 0.35)),
              ),
              child: Icon(feature.icon, color: feature.color, size: 26),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            feature.titleKey.tr(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.descKey.tr(),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
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
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryCyan.withValues(alpha: 0.16),
            AppColors.primaryGreen.withValues(alpha: 0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.primaryGreen, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.landingHeroTitle.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 22),
          ShimmerCtaButton(
            onPressed: widget.onSignInPressed,
            label: LocaleKeys.landingStartFreeCta.tr(),
            icon: Icons.rocket_launch_rounded,
            primaryColor: AppColors.primaryCyan,
            textColor: Colors.black,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Text(
      '${LocaleKeys.appName.tr()} • 2026 • Linear / Notion / Framer inspired',
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
