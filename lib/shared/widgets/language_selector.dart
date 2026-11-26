import 'package:flutter/material.dart';
import 'language_dropdown_button.dart';

export 'language_dropdown_button.dart';

/// Legacy backwards-compatible wrapper that renders the modern LanguageDropdownButton
class QuickLanguagePills extends StatelessWidget {
  const QuickLanguagePills({super.key});

  @override
  Widget build(BuildContext context) {
    return const LanguageDropdownButton();
  }
}

/// Legacy backwards-compatible wrapper that renders the modern LanguageDropdownButton
class DrawerLanguageList extends StatelessWidget {
  const DrawerLanguageList({super.key});

  @override
  Widget build(BuildContext context) {
    return const LanguageDropdownButton(isExpanded: true);
  }
}
