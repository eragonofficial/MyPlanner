import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/language_manager.dart';

class QuickLanguagePills extends StatelessWidget {
  const QuickLanguagePills({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: LanguageManager.languages.map((lang) {
          final isSelected = currentLocale.languageCode == lang.locale.languageCode &&
              currentLocale.scriptCode == lang.locale.scriptCode;

          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                context.setLocale(lang.locale);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryCyan.withOpacity(0.25)
                    : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primaryCyan : AppColors.glassBorder,
                  width: isSelected ? 1.2 : 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang.flag, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    lang.shortName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DrawerLanguageList extends StatelessWidget {
  const DrawerLanguageList({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return Column(
      children: LanguageManager.languages.map((lang) {
        final isSelected = currentLocale.languageCode == lang.locale.languageCode &&
            currentLocale.scriptCode == lang.locale.scriptCode;

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          leading: Text(lang.flag, style: const TextStyle(fontSize: 20)),
          title: Text(
            lang.titleKey.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primaryCyan : AppColors.textPrimary,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_rounded, color: AppColors.primaryCyan, size: 20)
              : null,
          onTap: () {
            context.setLocale(lang.locale);
            Navigator.of(context).pop();
          },
        );
      }).toList(),
    );
  }
}
