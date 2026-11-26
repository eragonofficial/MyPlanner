import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_manager.dart';
import '../../core/localization/locale_keys.dart';

/// Reusable dropdown button to switch between the 5 supported languages.
/// Works cleanly on both Android mobile and Web across Dark and Light modes.
class LanguageDropdownButton extends StatefulWidget {
  final bool isExpanded;
  final bool showChevron;
  final EdgeInsetsGeometry? padding;

  const LanguageDropdownButton({
    super.key,
    this.isExpanded = false,
    this.showChevron = true,
    this.padding,
  });

  @override
  State<LanguageDropdownButton> createState() => _LanguageDropdownButtonState();
}

class _LanguageDropdownButtonState extends State<LanguageDropdownButton> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = context.locale;

    final bgColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.85)
        : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textPrimary : AppColors.textOnLight;
    const iconColor = AppColors.primaryCyan;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: isDark ? const Color(0xFF161B26) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.4),
        ),
      ),
      child: PopupMenuButton<LanguageItem>(
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        tooltip: LocaleKeys.languages.tr(),
        onOpened: () {
          setState(() => _isOpen = true);
        },
        onCanceled: () {
          setState(() => _isOpen = false);
        },
        onSelected: (LanguageItem item) {
          setState(() => _isOpen = false);
          context.setLocale(item.locale);
        },
        itemBuilder: (BuildContext ctx) {
          return LanguageManager.languages.map((item) {
            final isSelected = currentLocale.languageCode == item.locale.languageCode &&
                currentLocale.scriptCode == item.locale.scriptCode;

            return PopupMenuItem<LanguageItem>(
              value: item,
              padding: EdgeInsets.zero,
              height: 44,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.primaryCyan.withValues(alpha: 0.18)
                          : AppColors.primaryCyan.withValues(alpha: 0.12))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primaryCyan.withValues(alpha: 0.5),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      item.flag,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.nativeName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primaryCyan
                              : (isDark ? AppColors.textPrimary : AppColors.textOnLight),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryCyan,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }).toList();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _isOpen
                ? (isDark
                    ? AppColors.primaryCyan.withValues(alpha: 0.15)
                    : AppColors.primaryCyan.withValues(alpha: 0.1))
                : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen ? AppColors.primaryCyan : borderColor,
              width: _isOpen ? 1.4 : 1.0,
            ),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: AppColors.primaryCyan.withValues(alpha: 0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: _isOpen ? AppColors.primaryCyan : iconColor,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    LocaleKeys.languages.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isOpen ? AppColors.primaryCyan : textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              if (widget.showChevron) ...[
                if (!widget.isExpanded) const SizedBox(width: 5),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _isOpen
                        ? AppColors.primaryCyan
                        : (isDark
                            ? AppColors.textSecondary
                            : AppColors.textOnLightSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
