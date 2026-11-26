import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_keys.dart';
import '../models/pomodoro_state.dart';
import 'glass_card.dart';

class AmbientSoundBar extends StatelessWidget {
  final Set<AmbientSound> activeSounds;
  final Function(AmbientSound) onToggleSound;
  final VoidCallback onClearAllSounds;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final bool isPaused;
  final bool Function(AmbientSound)? isSoundBuffering;

  const AmbientSoundBar({
    super.key,
    required this.activeSounds,
    required this.onToggleSound,
    required this.onClearAllSounds,
    required this.volume,
    required this.onVolumeChanged,
    this.isPaused = false,
    this.isSoundBuffering,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = activeSounds.isNotEmpty;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Title, active count badge, master volume slider, mute all
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.ambientTitle.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (hasActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryGreen, width: 0.8),
                      ),
                      child: Text(
                        '${activeSounds.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Volume Slider & Mute All Controls
              if (hasActive)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mute / Clear all button
                    IconButton(
                      icon: const Icon(
                        Icons.volume_off_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      tooltip: LocaleKeys.soundNone.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onClearAllSounds,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.volume_down_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
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

          const SizedBox(height: 12),

          // Horizontal scrollable multi-ambient sound buttons dock
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: AmbientSound.values.map((sound) {
                final isSelected = activeSounds.contains(sound);
                final isBuffering = isSoundBuffering != null && isSoundBuffering!(sound);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onToggleSound(sound),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGreen.withOpacity(0.2)
                            : AppColors.glassSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.glassBorder,
                          width: isSelected ? 1.4 : 0.8,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withOpacity(0.25),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sound.icon,
                            size: 18,
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sound.labelKey.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            if (isBuffering)
                              const SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryGreen,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPaused
                                      ? Colors.amber
                                      : AppColors.primaryGreen,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
