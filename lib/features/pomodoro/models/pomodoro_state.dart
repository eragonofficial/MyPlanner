import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';

enum PomodoroTimerMode {
  mode25_5(
    labelKey: LocaleKeys.mode25_5,
    focusMinutes: 25,
    breakMinutes: 5,
  ),
  mode50_10(
    labelKey: LocaleKeys.mode50_10,
    focusMinutes: 50,
    breakMinutes: 10,
  );

  final String labelKey;
  final int focusMinutes;
  final int breakMinutes;

  const PomodoroTimerMode({
    required this.labelKey,
    required this.focusMinutes,
    required this.breakMinutes,
  });

  int get focusSeconds => focusMinutes * 60;
  int get breakSeconds => breakMinutes * 60;
}

enum PomodoroPhase {
  focus(
    titleKey: LocaleKeys.stateFocus,
    color: AppColors.focusColor,
  ),
  breakTime(
    titleKey: LocaleKeys.stateBreak,
    color: AppColors.breakColor,
  );

  final String titleKey;
  final Color color;

  const PomodoroPhase({
    required this.titleKey,
    required this.color,
  });
}

enum AmbientSound {
  dengiz(
    labelKey: LocaleKeys.soundDengiz,
    icon: Icons.waves_rounded,
    keyName: 'dengiz',
    assetPath: 'assets/audio/dengiz/dengiz_long.mp3',
  ),
  hasharot(
    labelKey: LocaleKeys.soundHasharot,
    icon: Icons.nights_stay_rounded,
    keyName: 'hasharot',
    assetPath: 'assets/audio/hasharot/hasharot_long.m4a',
  ),
  ormon(
    labelKey: LocaleKeys.soundOrmon,
    icon: Icons.forest_rounded,
    keyName: 'ormon',
    assetPath: 'assets/audio/ormon/ormon_long.m4a',
  ),
  qushlar(
    labelKey: LocaleKeys.soundQushlar,
    icon: Icons.flutter_dash,
    keyName: 'qushlar',
    assetPath: 'assets/audio/qushlar/qushlar_long.mp3',
  ),
  sharshara(
    labelKey: LocaleKeys.soundSharshara,
    icon: Icons.water_drop_rounded,
    keyName: 'sharshara',
    assetPath: 'assets/audio/sharshara/sharshara_long.m4a',
  ),
  toglar(
    labelKey: LocaleKeys.soundToglar,
    icon: Icons.landscape_rounded,
    keyName: 'toglar',
    assetPath: 'assets/audio/toglar/toglar_long.m4a',
  ),
  yomgir(
    labelKey: LocaleKeys.soundYomgir,
    icon: Icons.cloudy_snowing,
    keyName: 'yomgir',
    assetPath: 'assets/audio/yomgir/yomgir_long.m4a',
  );

  final String labelKey;
  final IconData icon;
  final String keyName;
  final String assetPath;

  const AmbientSound({
    required this.labelKey,
    required this.icon,
    required this.keyName,
    required this.assetPath,
  });
}
