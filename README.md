# Flosy

Flosy is a cross-platform Flutter mobile app demonstrating a production-ready mobile architecture: Firebase-backed authentication and sync, offline-first local persistence, biometric security, multimedia (image + audio) handling, PDF export/printing, and on-device ML inference using TFLite.

## Key features
- Firebase Authentication and Cloud Firestore sync
- Offline persistence with `sqflite` and automatic sync when online
- Biometric login (`local_auth`) and encrypted storage (`flutter_secure_storage`)
- Image picking and camera integration
- Audio recording and playback (record, visualize, play)
- PDF generation and printing
- On-device ML inference using `tflite_flutter`
- Localization (`easy_localization`) and responsive UI (`flutter_screenutil`)

## Tech stack
- Flutter & Dart
- State management: `flutter_bloc`, `equatable`
- Backend: `firebase_core`, `firebase_auth`, `cloud_firestore`
- Local: `sqflite`, `shared_preferences`, `flutter_secure_storage`
- Media: `image_picker`, `audioplayers`, `flutter_sound`
- ML: `tflite_flutter`
- Other: `pdf`, `printing`, `local_auth`, `connectivity_plus`, `flutter_dotenv`

## Quick start

1. Install Flutter (≥ stable channel) and set up Android/iOS toolchains.
2. Clone repo and install packages:
```bash
git clone <repo-url>
cd flosy
flutter pub get
```

3. Configure Firebase:
- Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective platform folders.
- Create the required Firebase projects/services (Auth, Firestore).

4. Configure environment:
- Copy `api.env.example` → `api.env` and add keys (if present).
- (Optional) Add TFLite models into `assets/models/`.

5. Run the app:
```bash
flutter run
```

## Project structure (high level)
- `lib/` — Flutter app source (screens, blocs, repositories, models)
- `assets/` — images, icons, translations, TFLite models
- `android/`, `ios/` — platform-specific configs
- `pubspec.yaml` — dependencies & assets (reviewed)

## Notes & integration tips
- Biometric login requires `local_auth` setup and proper Android/iOS permissions (manifest entries present).
- Offline sync: data is persisted locally via `sqflite`; Firestore sync is triggered when connectivity resumes (uses `connectivity_plus`).
- TFLite models must be exported to TensorFlow Lite format and placed under `assets/models/`; update `pubspec.yaml` assets accordingly.
- PDF generation uses the `pdf` package — check printing permissions on Android.
