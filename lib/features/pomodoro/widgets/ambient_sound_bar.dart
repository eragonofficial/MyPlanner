import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../models/pomodoro_state.dart';
import 'glass_card.dart';

class AmbientSoundBar extends StatelessWidget {
  final AmbientSound activeSound;
  final Function(AmbientSound) onSelectSound;
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const AmbientSoundBar({
    super.key,
    required this.activeSound,
    required this.onSelectSound,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.nature_people_rounded,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    LocaleKeys.ambientTitle.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (activeSound != AmbientSound.none)
                Row(
                  children: [
                    const Icon(Icons.volume_down_rounded, size: 16, color: AppColors.textMuted),
                    SizedBox(
                      width: 80,
                      height: 20,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 2,
                          activeTrackColor: AppColors.primaryGreen,
                          inactiveTrackColor: AppColors.glassSurfaceLight,
                          thumbColor: AppColors.primaryGreen,
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: onVolumeChanged,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: AmbientSound.values.map((sound) {
              final isSelected = activeSound == sound;
              return GestureDetector(
                onTap: () => onSelectSound(sound),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen.withOpacity(0.2)
                        : AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryGreen : AppColors.glassBorder,
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sound.icon,
                        size: 20,
                        color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sound.labelKey.tr(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primaryGreen : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
