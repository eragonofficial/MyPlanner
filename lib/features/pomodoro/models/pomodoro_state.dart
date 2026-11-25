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
  none(
    labelKey: LocaleKeys.soundNone,
    icon: Icons.volume_off_rounded,
    keyName: 'none',
  ),
  forest(
    labelKey: LocaleKeys.soundForest,
    icon: Icons.forest_rounded,
    keyName: 'forest',
  ),
  rain(
    labelKey: LocaleKeys.soundRain,
    icon: Icons.water_drop_rounded,
    keyName: 'rain',
  ),
  ocean(
    labelKey: LocaleKeys.soundOcean,
    icon: Icons.waves_rounded,
    keyName: 'ocean',
  ),
  wind(
    labelKey: LocaleKeys.soundWind,
    icon: Icons.air_rounded,
    keyName: 'wind',
  );

  final String labelKey;
  final IconData icon;
  final String keyName;

  const AmbientSound({
    required this.labelKey,
    required this.icon,
    required this.keyName,
  });
}
