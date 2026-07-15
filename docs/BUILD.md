# BechaKena — Building installable apps for clients

How to turn the source into something you can hand a potential client and have
them **install and run**, on each platform. Product name/brand comes from
`lib/app/brand.dart`.

> **Fastest path (recommended):** push a `v*` git tag — GitHub Actions
> (`.github/workflows/release.yml`) builds the **Windows zip + Android APK**
> automatically and attaches them to a GitHub Release. See
> [§5 One-command release](#5-one-command-release-via-git-tag). The manual steps
> below are for when you want a *proper installer* (Windows `.exe` setup,
> `.deb`/AppImage) or are building on your own machine.

---

## 0. One-time setup (every platform)

Flutter isn't on `PATH` on this machine — prefix commands or add it once:

```bash
export PATH="$PATH:/home/billsbro/development/flutter/bin"
```

Then, from the repo root, **before any build**:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift/Riverpod codegen
flutter gen-l10n                                            # bn/en localizations
flutter analyze                                             # must be clean
flutter test                                                # 167 passing
```

Bump the version before a client build — edit `pubspec.yaml`:

```yaml
version: 1.0.0+1     # <marketing-version>+<build-number>; raise build-number every release
```

---

## 1. 🪟 Windows (primary shipping target)

### 1a. Build the release bundle

Requires **Visual Studio** with the *"Desktop development with C++"* workload
(the Flutter CLI, not VS Code). On a Windows machine:

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter build windows --release
```

Output folder (this **is** the app — self-contained, no Flutter needed to run):

```
build\windows\x64\runner\Release\
```

### 1b. Portable ZIP (simplest demo — no installer)

```powershell
Compress-Archive -Path build\windows\x64\runner\Release\* -DestinationPath BechaKena-windows.zip
```

Client unzips anywhere and double-clicks `bechakena.exe`. Good enough for a demo;
no admin rights, no install. **This is what CI produces.**

### 1c. Proper installer with Inno Setup (recommended for clients)

Install [Inno Setup](https://jrsoftware.org/isinfo.php) (free). Save this as
`installer/bechakena.iss`, then run **Inno Setup Compiler** on it:

```ini
[Setup]
AppName=BechaKena
AppVersion=1.0.0
DefaultDirName={autopf}\BechaKena
DefaultGroupName=BechaKena
OutputBaseFilename=BechaKena-Setup-1.0.0
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\BechaKena";        Filename: "{app}\bechakena.exe"
Name: "{commondesktop}\BechaKena"; Filename: "{app}\bechakena.exe"

[Run]
Filename: "{app}\bechakena.exe"; Description: "Launch BechaKena"; Flags: nowait postinstall skipifsilent
```

Produces `BechaKena-Setup-1.0.0.exe` — a familiar double-click installer with a
Start-menu + desktop shortcut. This is the artifact to hand a shop owner.

### 1d. MSIX (optional — Store-style install/auto-update)

```powershell
flutter pub add --dev msix
flutter pub run msix:create
```

Produces a signed `.msix`. Needs a code-signing cert (self-signed works for demos
but the client must trust it first). Inno Setup (1c) is simpler for one-off demos.

---

## 2. 🤖 Android (tablet / phone demo)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk` — sideload onto any
Android device (enable *Install unknown apps*). This is the easiest client demo:
email/USB the APK, tap to install.

> ⚠️ **Currently debug-signed.** Fine for demos, **not** for the Play Store and it
> shows an "unknown developer" warning. For a real release, create a keystore once:
>
> ```bash
> keytool -genkey -v -keystore ~/bechakena-release.jks -keyalg RSA \
>   -keysize 2048 -validity 10000 -alias bechakena
> ```
>
> Create `android/key.properties` (git-ignored — never commit it):
>
> ```properties
> storeFile=/home/billsbro/bechakena-release.jks
> storePassword=<your-store-password>
> keyPassword=<your-key-password>
> keyAlias=bechakena
> ```
>
> Then wire it into `android/app/build.gradle` `signingConfigs` / `buildTypes`
> (Flutter's [signing guide](https://docs.flutter.dev/deployment/android#signing-the-app)).
> Rebuild — the APK is now release-signed.

**For the Play Store** (not needed for client demos) build an app bundle instead:

```bash
flutter build appbundle --release   # build/app/outputs/bundle/release/app-release.aab
```

---

## 3. 🐧 Linux (dev machine / Linux clients)

Requires the desktop deps (already installed here):
`sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev`

```bash
flutter build linux --release
```

Self-contained bundle:

```
build/linux/x64/release/bundle/          # run ./bechakena inside it
```

Package it for a client:

- **Tarball (simplest):**
  ```bash
  tar -czf BechaKena-linux-x64.tar.gz -C build/linux/x64/release/bundle .
  ```
  Client extracts and runs `./bechakena`.
- **AppImage / .deb / Snap:** wrap the bundle with
  [`flutter_distributor`](https://github.com/leanflutter/flutter_distributor)
  (`dart pub global activate flutter_distributor`, then a `distribute_options.yaml`)
  for a one-file AppImage or a `.deb` package.

---

## 4. 🍎 iOS (requires a Mac + Apple Developer account)

**Cannot be built on this Linux machine** — Apple toolchain is macOS-only. On a Mac
with Xcode and a paid Apple Developer account:

```bash
flutter build ipa --release        # build/ios/ipa/*.ipa
```

Distribute the `.ipa` to demo devices via **TestFlight** (recommended) or an
**ad-hoc** provisioning profile (device UDIDs registered). There is no
"just sideload it" path on iOS like Android — a demo needs either TestFlight or the
device pre-registered in your developer account.

> **macOS desktop** is not configured (`macos/` folder doesn't exist). To add it:
> `flutter create --platforms=macos .`, then `flutter build macos --release`.

---

## 5. One-command release via git tag

The repo already automates the two most-demoed targets. From a clean, committed
tree:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions (`.github/workflows/release.yml`) then:
- builds `flutter build windows --release` → uploads **`BechaKena-windows-v1.0.0.zip`**
- builds `flutter build apk --release` → uploads **`BechaKena-v1.0.0.apk`**

Both land on the repo's **Releases** page — send clients the download links. (The
Windows artifact is the portable zip of §1b; for a polished installer use §1c
locally. iOS/Linux are not in CI.)

---

## Quick reference

| Platform | Build command | Client-ready artifact | Build host |
|---|---|---|---|
| Windows  | `flutter build windows --release` | Inno Setup `.exe` (§1c) or portable `.zip` (§1b) | Windows + VS C++ |
| Android  | `flutter build apk --release` | `app-release.apk` (sideload) | any (Linux/macOS/Win) |
| Linux    | `flutter build linux --release` | `.tar.gz` or AppImage/`.deb` | Linux + GTK deps |
| iOS      | `flutter build ipa --release` | `.ipa` via TestFlight/ad-hoc | **macOS + Xcode only** |

**For a first client showcase:** the **Windows Inno Setup installer (§1c)** for a
desktop shop, or the **Android APK (§2)** for a tablet — those two cover almost
every Bangladeshi shop/restaurant demo. Both build green from the current tree.
</content>
