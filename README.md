# My Planner & Pomodoro ("Study With Me")

A modern, offline-first Android mobile application built with Flutter combining a personal time-planner and a Pomodoro focus timer with deep dark glassmorphism aesthetic, 5-language localization, guest mode with lazy authentication, and Supabase cloud synchronization.

---

## 🚀 Key Features

### 1. 🔓 Guest Mode & Lazy Authentication
- **Open Access on Launch**:
  - The app never forces login on launch. Unauthenticated users immediately land in **My Planner** and **Pomodoro** with full access to browse all period tabs (**Daily**, **Weekly**, **Monthly**, **Yearly**) and the **365-Day Dashboard**.
  - In Guest Mode, sample demo notes and preview badges let users interactively explore the UI.
- **Action Guard ("Register First" Modal)**:
  - Any write action (adding a task `+`, editing, deleting, or toggling completion) by unauthenticated users triggers a frosted glass modal sheet: *"Please register or sign in first to save and manage your plans"* with a direct *"Sign Up / Log In"* CTA.

### 2. 🔐 Multi-Method Authentication Screen
- Accessible from both the Action Guard prompt and the left `NavigationDrawer`.
- Supported authentication providers via `supabase_flutter`:
  - **Email & Password**: Toggle between Sign In and Sign Up with validation.
  - **Google Sign-In**: "Continue with Google" OAuth button.
  - **Phone Number (SMS OTP)**: Phone number input with country code picker (defaulting to `+998`), "Send Code" via Supabase OTP, and 6-digit SMS verification code entry.

### 3. ☁️ Supabase Cloud Integration & Notifications
- **Connected Database**:
  - **URL**: `https://mrwwmackzhsscsozcoay.supabase.co`
  - **Table**: `public.notes` with full CRUD support (`title`, `description`, `period_type`, `target_date`, `priority`, `is_completed`, `reminder_time`, `user_id`).
  - Safe fallback for offline mode using `shared_preferences`.
- **Scheduled Notifications**:
  - Optional task reminder time picker (`TimeOfDay` + date).
  - Background notifications via `flutter_local_notifications` with reboot receivers.

### 4. 📊 Yearly (365-Day) Analytics & Activity Heatmap
- Dedicated Dashboard accessible via top summary card, AppBar, and Navigation Drawer.
- Year selector (e.g. 2025, 2026, 2027).
- 365-day overview with completion percentage and active streak counter (`🔥 X days streak`).
- Period breakdown cards (Daily, Weekly, Monthly, Yearly).
- 52-week GitHub-style contribution heatmap with interactive tap inspection.

### 5. 🌐 Multi-Language Localization (`easy_localization`)
- **5 Supported Languages**:
  - Uzbek Latin (`uz-Latn`)
  - Uzbek Cyrillic (`uz-Cyrl`)
  - Russian (`ru`)
  - English (`en`)
  - Korean (`ko`)
- Strictly zero hardcoded strings in widgets; all text localized across JSON files in `assets/translations/`.

---

## 🛠 Running the Project

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on connected Android device or emulator
flutter run
```
