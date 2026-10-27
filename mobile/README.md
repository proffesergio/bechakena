# Mobile app — build notes & optional cloud configuration

The mobile app **is** the Flutter project at the repository root; this folder
exists so the mobile build notes live where reviewers expect them. The source
is not duplicated here.

This is the **only mobile application** component; the other runnable part is
the static Next.js showcase in `site/`. There is no separate mobile admin app,
no server API and no backend/Edge Function source: owner/manager back-office
screens are part of the same Flutter app, and all writes go to the device-local
SQLite database. The optional Cloud Plan is roadmap-only. See
`../docs/SECURITY.md` for the local-only RBAC scope.

## Where things are

| Thing | Location |
|---|---|
| App source | repository root — `lib/`, `android/`, `ios/`, `web/` |
| Manifest & pinned lockfile | `pubspec.yaml`, `pubspec.lock` (repository root) |
| Optional cloud configuration (single file) | `lib/app/config.dart` |
| Android launcher icons | `android/app/src/main/res/mipmap-*/ic_launcher.png` |
| iOS app icons | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| PWA / web icons | `web/icons/` + `web/manifest.json` |

## Optional cloud API URL (not required)

The roadmap Cloud Plan would use one base URL from `lib/app/config.dart`, fed by
compile-time `--dart-define` values. No backend ships and no endpoint is called
in the offline build. No production URL or key is hard-coded; server-side
secrets would live only in the server/CI environment. With no defines the app is
100% offline, which is the default and fully supported mode.

```bash
flutter build apk --release \
  --dart-define=BECHAKENA_API_BASE_URL=https://your-server.example.com/functions/v1 \
  --dart-define=BECHAKENA_SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=BECHAKENA_SUPABASE_ANON_KEY=your-anon-key
```

(Complete reference: `.env.example` at the repository root.)

## Build the Android APK

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter build apk --release          # → build/app/outputs/flutter-apk/app-release.apk
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Build for iOS

Needs macOS + Xcode + an Apple developer account:

```bash
flutter build ipa --release          # see docs/BUILD.md §4 for signing details
```

## Replace the icons

Swap the launcher icons before shipping a client build: the Android mipmaps
above and the iOS `AppIcon.appiconset` (regenerate with any icon tooling —
keep the same file names). The web demo icons sit in `web/icons/`.
