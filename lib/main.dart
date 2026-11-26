import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/constants/app_colors.dart';
import 'core/localization/language_manager.dart';
import 'core/localization/locale_keys.dart';
import 'core/services/audio_player_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/landing/landing_page.dart';
import 'features/planner/controllers/planner_controller.dart';
import 'features/planner/data/planner_repository.dart';
import 'features/planner/screens/planner_screen.dart';
import 'features/planner/screens/yearly_dashboard_screen.dart';
import 'features/pomodoro/controllers/pomodoro_controller.dart';
import 'features/pomodoro/screens/pomodoro_screen.dart';
import 'shared/widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Fix status bar styling for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Core Services
  final localStorage = await LocalStorageService.create();
  await SupabaseService.initialize();
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  final audioPlayer = AudioPlayerService();

  // Initialize Repositories and Controllers
  final plannerRepository = PlannerRepository(localStorage);
  final plannerController = PlannerController(plannerRepository);
  final pomodoroController = PomodoroController(audioPlayer);

  runApp(
    EasyLocalization(
      supportedLocales: LanguageManager.supportedLocales,
      path: LanguageManager.path,
      fallbackLocale: LanguageManager.fallbackLocale,
      startLocale: LanguageManager.en,
      child: MyPlannerApp(
        plannerController: plannerController,
        pomodoroController: pomodoroController,
        localStorage: localStorage,
      ),
    ),
  );
}

class MyPlannerApp extends StatelessWidget {
  final PlannerController plannerController;
  final PomodoroController pomodoroController;
  final LocalStorageService localStorage;

  const MyPlannerApp({
    super.key,
    required this.plannerController,
    required this.pomodoroController,
    required this.localStorage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: LocaleKeys.appName.tr(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: MainShell(
        plannerController: plannerController,
        pomodoroController: pomodoroController,
        localStorage: localStorage,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final PlannerController plannerController;
  final PomodoroController pomodoroController;
  final LocalStorageService localStorage;

  const MainShell({
    super.key,
    required this.plannerController,
    required this.pomodoroController,
    required this.localStorage,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MainModule _currentModule = MainModule.planner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Cross-Platform Realtime Subscription (Web + Android)
    SupabaseService.subscribeToNotes(() {
      if (mounted) {
        widget.plannerController.syncWithCloud();
      }
    });

    // Auth State Changes (Safe Guest-to-Account merge on login)
    SupabaseService.authStateChanges?.listen((data) {
      if (mounted) {
        widget.plannerController.handleAuthChanged();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SupabaseService.unsubscribeRealtime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Automatic background sync pull on app resume
    if (state == AppLifecycleState.resumed) {
      widget.plannerController.syncWithCloud();
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openAuthScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          onAuthSuccess: () {
            widget.plannerController.handleAuthChanged();
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  void _switchModule(MainModule module) {
    setState(() {
      _currentModule = module;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Website Behavior (kIsWeb): Unauthenticated users see the modern Landing Page
    if (kIsWeb && !SupabaseService.isAuthenticated) {
      return LandingPage(
        onSignInPressed: () => _openAuthScreen(context),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([widget.plannerController, widget.pomodoroController]),
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.darkBg,
          drawer: AppDrawer(
            currentModule: _currentModule,
            onSelectModule: _switchModule,
            activePeriod: widget.plannerController.activePeriod,
            onSelectPeriod: (period) {
              widget.plannerController.setPeriodType(period);
            },
            totalTasks: widget.plannerController.allNotes.length,
            getPeriodCount: (type) => widget.plannerController.getCountForPeriod(type),
            isPomodoroRunning: widget.pomodoroController.isRunning,
            isCloudOnline: widget.plannerController.isCloudSyncAvailable,
            syncStatus: widget.plannerController.syncStatus,
            onSyncNow: () => widget.plannerController.syncWithCloud(showLoading: true),
            onSignOut: () => widget.plannerController.handleSignOut(),
            localStorage: widget.localStorage,
            onAuthChanged: () {
              widget.plannerController.syncWithCloud();
              setState(() {});
            },
            onOpenDashboard: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => YearlyDashboardScreen(
                    controller: widget.plannerController,
                  ),
                ),
              );
            },
          ),
          body: IndexedStack(
            index: _currentModule == MainModule.planner ? 0 : 1,
            children: [
              PlannerScreen(
                controller: widget.plannerController,
                onOpenDrawer: _openDrawer,
              ),
              PomodoroScreen(
                controller: widget.pomodoroController,
                onOpenDrawer: _openDrawer,
              ),
            ],
          ),
        );
      },
    );
  }
}
