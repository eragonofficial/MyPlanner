# Permanent Project Architecture & Cross-Platform Rules (My Planner & Pomodoro)

1. **Cross-Platform Safety (Android + Web):** Always ensure every new feature, widget, service, and package works safely on **both Android and Web** (`kIsWeb`). Never use `dart:io` directly without platform checks, and wrap native-only plugins (`flutter_local_notifications`, `just_audio`, background alarms, file pickers) in safe platform guards (`if (!kIsWeb)`) or web-compatible fallbacks so `flutter build web --release` and `flutter build appbundle --release` never fail or crash.
2. **5-Language Localization (`easy_localization`):** Every user-facing string must be added to all 5 translation files (`assets/translations/uz-Latn.json`, `uz-Cyrl.json`, `ru.json`, `en.json`, `ko.json`) — never hardcode text in Dart widgets.
3. **Offline-First + Supabase Sync:** Keep `shared_preferences` local caching working for Guest Mode and offline usage alongside Supabase (`notes` table) synchronization.
4. **Verification:** Always run `flutter analyze` after making changes to verify zero compilation errors.
