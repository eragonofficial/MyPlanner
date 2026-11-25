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
      ),
    ),
  );
}

class MyPlannerApp extends StatelessWidget {
  final PlannerController plannerController;
  final PomodoroController pomodoroController;

  const MyPlannerApp({
    super.key,
    required this.plannerController,
    required this.pomodoroController,
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
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final PlannerController plannerController;
  final PomodoroController pomodoroController;

  const MainShell({
    super.key,
    required this.plannerController,
    required this.pomodoroController,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MainModule _currentModule = MainModule.planner;

  @override
  void initState() {
    super.initState();
    SupabaseService.authStateChanges?.listen((data) {
      if (mounted) {
        widget.plannerController.syncWithCloud();
        setState(() {});
      }
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _switchModule(MainModule module) {
    setState(() {
      _currentModule = module;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.plannerController, widget.pomodoroController]),
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.darkBg,
          drawer: AppDrawer(
            currentModule: _currentModule,
            onSelectModule: _switchModule,
            totalTasks: widget.plannerController.allNotes.length,
            isPomodoroRunning: widget.pomodoroController.isRunning,
            isCloudOnline: widget.plannerController.isCloudSyncAvailable,
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
