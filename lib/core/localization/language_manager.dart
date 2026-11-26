import 'package:flutter/material.dart';
import 'locale_keys.dart';

class LanguageManager {
  static const String path = 'assets/translations';

  static const Locale uzLatn = Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Latn');
  static const Locale uzCyrl = Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl');
  static const Locale ru = Locale('ru');
  static const Locale en = Locale('en');
  static const Locale ko = Locale('ko');

  static const Locale fallbackLocale = en;

  static const List<Locale> supportedLocales = [
    uzLatn,
    uzCyrl,
    ru,
    en,
    ko,
  ];

  static final List<LanguageItem> languages = [
    const LanguageItem(
      locale: uzLatn,
      titleKey: LocaleKeys.langUzLatn,
      code: 'uz-Latn',
      flag: '🇺🇿',
      shortName: 'UZ (Latn)',
      nativeName: "O'zbekcha (Lotin)",
    ),
    const LanguageItem(
      locale: uzCyrl,
      titleKey: LocaleKeys.langUzCyrl,
      code: 'uz-Cyrl',
      flag: '🇺🇿',
      shortName: 'ЎЗ (Кир)',
      nativeName: 'Ўзбекча (Кирилл)',
    ),
    const LanguageItem(
      locale: ru,
      titleKey: LocaleKeys.langRu,
      code: 'ru',
      flag: '🇷🇺',
      shortName: 'RU',
      nativeName: 'Русский',
    ),
    const LanguageItem(
      locale: en,
      titleKey: LocaleKeys.langEn,
      code: 'en',
      flag: '🇺🇸',
      shortName: 'EN',
      nativeName: 'English',
    ),
    const LanguageItem(
      locale: ko,
      titleKey: LocaleKeys.langKo,
      code: 'ko',
      flag: '🇰🇷',
      shortName: 'KO',
      nativeName: '한국어',
    ),
  ];

  static LanguageItem getLanguageItem(Locale locale) {
    return languages.firstWhere(
      (item) =>
          item.locale.languageCode == locale.languageCode &&
          item.locale.scriptCode == locale.scriptCode,
      orElse: () => languages[3], // Default English
    );
  }
}

class LanguageItem {
  final Locale locale;
  final String titleKey;
  final String code;
  final String flag;
  final String shortName;
  final String nativeName;

  const LanguageItem({
    required this.locale,
    required this.titleKey,
    required this.code,
    required this.flag,
    required this.shortName,
    required this.nativeName,
  });
}
