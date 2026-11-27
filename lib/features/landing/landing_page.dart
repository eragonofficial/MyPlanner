import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import 'widgets/aurora_particle_background.dart';
import 'widgets/interactive_glass_card.dart';
import 'widgets/interactive_try_live_widget.dart';
import 'widgets/shimmer_cta_button.dart';
import '../../../shared/widgets/pulsing_badge.dart';
import '../../../shared/widgets/language_dropdown_button.dart';
import '../../../shared/widgets/app_brand_logo.dart';
import '../feedback/widgets/feedback_dialog.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback onSignInPressed;

  const LandingPage({super.key, required this.onSignInPressed});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _sandboxKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  void _scrollToSection(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    }
  }

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
                          Container(
                            key: _sandboxKey,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: InteractiveTryLiveWidget(
                              onStartPlanning: widget.onSignInPressed,
                            ),
                          ),

                          const SizedBox(height: 64),

                          // 3D Tilt Feature Showcase Cards
                          KeyedSubtree(
                            key: _featuresKey,
                            child: _buildFeatureShowcase(context, isDesktop),
                          ),

                          const SizedBox(height: 64),

                          // Bottom Call to Action Banner
                          _buildBottomCta(context),

                          const SizedBox(height: 48),

                          // Footer
                          _buildFooter(context),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showFeedbackText = screenWidth >= 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary.withValues(alpha: 0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Row(
            children: [
              // Brand Logo & Title
              const AppBrandLogo(size: 36),
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

              // Feedback Button
              if (showFeedbackText)
                TextButton.icon(
                  onPressed: () => FeedbackDialog.show(context),
                  icon: const Icon(
                    Icons.rate_review_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  label: Text(
                    LocaleKeys.feedbackTitle.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: () => FeedbackDialog.show(context),
                  tooltip: LocaleKeys.feedbackTitle.tr(),
                  icon: const Icon(
                    Icons.rate_review_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(width: 8),

              // Language Selector Dropdown Button
              const LanguageDropdownButton(),

              const SizedBox(width: 12),

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
        ),
      ),
    );
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

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.primaryCyan, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LocaleKeys.footerPrivacy.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          LocaleKeys.footerPrivacyDesc.tr(),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSupportContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: AppColors.primaryGreen, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LocaleKeys.footerContactTitle.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactDetailRow(
              icon: Icons.send_rounded,
              color: AppColors.primaryCyan,
              label: LocaleKeys.footerTelegramSupport.tr(),
              value: '@my_planner_support',
            ),
            const SizedBox(height: 12),
            _buildContactDetailRow(
              icon: Icons.email_outlined,
              color: AppColors.primaryGreen,
              label: LocaleKeys.footerEmailContact.tr(),
              value: 'support@my-planner.uz',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              FeedbackDialog.show(context);
            },
            icon: const Icon(Icons.rate_review_outlined, size: 16),
            label: Text(
              LocaleKeys.feedbackTitle.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetailRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color ?? AppColors.textSecondary,
                  fontWeight: color != null ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    final brandColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBrandLogo(size: 32),
            const SizedBox(width: 10),
            Text(
              LocaleKeys.appName.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          LocaleKeys.footerTagline.tr(),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.code_rounded, size: 14, color: AppColors.primaryCyan),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  LocaleKeys.footerCreatedBy.tr(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final linksColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.footerQuickLinks.tr(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        _buildFooterLink(
          icon: Icons.auto_awesome_outlined,
          label: LocaleKeys.footerFeatures.tr(),
          onTap: () => _scrollToSection(_featuresKey),
        ),
        _buildFooterLink(
          icon: Icons.timer_outlined,
          label: LocaleKeys.landingSandboxPomodoro.tr(),
          onTap: () => _scrollToSection(_sandboxKey),
        ),
        _buildFooterLink(
          icon: Icons.shield_outlined,
          label: LocaleKeys.footerPrivacy.tr(),
          onTap: () => _showPrivacyDialog(context),
        ),
      ],
    );

    final supportColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.footerContactTitle.tr(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        _buildFooterLink(
          icon: Icons.send_rounded,
          label: '${LocaleKeys.footerTelegramSupport.tr()} (@my_planner_support)',
          onTap: () => _showSupportContactDialog(context),
        ),
        _buildFooterLink(
          icon: Icons.email_outlined,
          label: '${LocaleKeys.footerEmailContact.tr()} (support@my-planner.uz)',
          onTap: () => _showSupportContactDialog(context),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => FeedbackDialog.show(context),
          icon: const Icon(Icons.rate_review_outlined, size: 16),
          label: Text(
            LocaleKeys.feedbackTitle.tr(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryCyan,
            side: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary.withValues(alpha: 0.85),
        border: const Border(
          top: BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: brandColumn),
                    const SizedBox(width: 32),
                    Expanded(flex: 3, child: linksColumn),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: supportColumn),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    brandColumn,
                    const SizedBox(height: 24),
                    linksColumn,
                    const SizedBox(height: 24),
                    supportColumn,
                  ],
                ),
              const SizedBox(height: 28),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '© 2026 ${LocaleKeys.appName.tr()}. ${LocaleKeys.footerRights.tr()}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const Text(
                      'https://my-planner.uz',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryCyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
