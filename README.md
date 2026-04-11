# Flosy

Flosy is a Flutter personal finance app focused on Android and iOS. It combines local-first transaction tracking with optional Firebase sync, budgeting, monthly analytics, PDF export, biometric login, voice-based transaction capture through Groq, and an AI insights screen powered by a bundled TFLite model.

## What is in the app

- Email/password authentication with Firebase Auth
- Splash flow with optional biometric re-entry
- Home dashboard with balance, income, expenses, and recent transactions
- Local-first transaction add/edit/delete backed by SQLite
- Optional cloud sync to Cloud Firestore
- Voice shortcut that records audio and converts it into a transaction
- Budget planning by category with monthly progress tracking
- Monthly analytics with charts and category breakdowns
- AI insights screen for spending predictions and summary insights
- Settings for theme, language, currency, profile image, sync, PDF export, and data clearing

## Tech stack

- Flutter and Dart
- `flutter_bloc` for state management
- `sqflite` + `shared_preferences` for local persistence
- `firebase_auth`, `firebase_core`, and `cloud_firestore` for backend services
- `local_auth` + `flutter_secure_storage` for biometric login support
- `easy_localization` for English and Arabic localization
- `tflite_flutter` for on-device predictions
- Groq API for voice transcription and transaction extraction
- `pdf` and `printing` for transaction export

## Project map

- `lib/main.dart`: app bootstrap, dotenv loading, localization, Firebase init, SQLite init
- `lib/features/auth/`: login, register, password reset, auth cubit
- `lib/features/home/`: dashboard, transactions, charts, local DB service, Groq voice flow
- `lib/features/budget/`: budget models and screens
- `lib/features/ai_insights/`: TFLite-based predictions and insight UI
- `lib/features/settings/`: preferences, sync, biometric toggle, PDF export, profile editing
- `assets/translations/`: English and Arabic strings
- `assets/models/`: bundled TFLite model and normalization parameters
- `ml_model/`: Python training script for regenerating the ML model
- `codemagic.yaml`: Codemagic workflow for building an iOS IPA

## Getting started

### 1. Prerequisites

- Flutter stable
- Dart SDK compatible with `^3.8.1`
- Android Studio and/or Xcode for mobile builds
- A Groq API key if you want the voice-to-transaction feature
- A Firebase project only if you plan to replace the current mobile Firebase config

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Create `api.env`

Create `api.env` in the project root:

```env
GROQ_API_KEY=your_groq_api_key_here
```

The app loads this file at startup from `lib/main.dart`. In CI, `codemagic.yaml` builds the same file from the `API_ENV` environment variable.

### 4. Firebase notes

The repo already contains generated Firebase options for Android and iOS in `lib/firebase_options.dart`, plus an Android `google-services.json`.

If you want to connect the app to your own Firebase project:

1. Enable Email/Password authentication.
2. Create Firestore and apply your rules/indexes as needed.
3. Re-run FlutterFire configuration for Android and iOS.
4. Replace the checked-in Firebase config with your own values.

### 5. Run the app

```bash
flutter run
```

## AI and ML

### Voice transaction capture

The microphone shortcut on the home balance card opens a recording flow that:

1. Records audio on-device.
2. Sends the file to Groq for transcription.
3. Uses Groq again to extract structured transaction data.
4. Saves the parsed transaction locally and can sync it to Firestore later.

This feature requires internet access and a valid `GROQ_API_KEY`.

### On-device AI insights

The home header includes a button that opens `AiInsightsScreen`. That screen uses the bundled TFLite model in `assets/models/expense_predictor.tflite` to estimate future category spending and generate summary insights from local transaction history.

Retraining the model is optional. If you want to regenerate it:

```bash
pip install -r ml_model/requirements.txt
python ml_model/train_model.py
```

This script writes:

- `assets/models/expense_predictor.tflite`
- `assets/models/norm_params.json`

## Notes for contributors

- The app is currently mobile-focused. Flutter folders for web and desktop exist, but `DefaultFirebaseOptions.currentPlatform` is only configured for Android and iOS.
- Cloud sync is opt-in from Settings. Offline use relies on the local SQLite database.
- The analytics tab in bottom navigation opens `DetailedChartScreen`. The separate AI insights screen is launched from the home header button.
- PDF export is implemented from Settings and uses platform-specific save/share behavior.
- The Google sign-in row in the login screen is currently a placeholder and is not wired to a real sign-in flow.
- `test/widget_test.dart` is still the default Flutter smoke test and does not cover the actual app behavior yet.

## Useful commands

```bash
flutter analyze
flutter test
flutter run
```
