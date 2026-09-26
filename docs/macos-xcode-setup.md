# macOS / Xcode Setup (iOS builds)

iOS builds must run on a Mac with Xcode - this cannot be done from the
Windows machine (PDF section 15). This document is the handover checklist
so any macOS machine can build `panditindia-customer` / `panditindia-pandit`
without rediscovery.

## 1. Prerequisites

| Tool | Minimum | Check |
| ---- | ------- | ----- |
| macOS | 13 (Ventura) or newer |  |
| Xcode | 16+ (App Store or `xcode-select`) | `xcodebuild -version` |
| Command line tools | matched to Xcode | `xcode-select -p` |
| CocoaPods | 1.15+ | `pod --version` |
| Flutter | 3.47.5 stable | `flutter --version` |

One-time:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstlaunch
flutter doctor --android-licenses   # if the Android SDK is also installed
flutter doctor                      # "No issues found" for iOS toolchain
```

## 2. Get the code

```bash
git clone https://github.com/dasaradha631/panditindia-customer.git
cd panditindia-customer
flutter pub get
```

## 3. Bundle identifiers

Already configured in the repo:

| App | Display name | Bundle id |
| --- | ------------ | --------- |
| Customer | PanditIndia | `com.panditindia.app` |
| Pandit | PanditIndia Pandit | `com.panditindia.pandit` |

If you need to change them: Xcode → Runner.xcproj → Target Runner →
General → Identity. Keep `CFBundleDisplayName` in sync (`ios/Runner/Info.plist`).

## 4. First build

```bash
# Simulator (no signing needed)
flutter build ios --simulator --debug

# Or open the IDE workflow
open ios/Runner.xcworkspace
# Product ▸ Run (⌘R), pick a simulator
```

Command-line device build:

```bash
flutter devices                 # note the device id
flutter run -d <device-id>
```

## 5. Code signing (device / TestFlight / App Store)

1. Xcode → Settings → Accounts → sign in with the Apple Developer team.
2. Runner target → Signing & Capabilities → pick the Team;
   "Automatically manage signing" ON.
3. Bundle id must match a registered App ID / provisioning profile.
4. Physical device: trust the developer certificate on the device
   (Settings → General → VPN & Device Management).

For CI use an App Store Connect key or certificates exported to a keychain.

## 6. Icons, splash and permissions

- App icon: `ios/Runner/Assets.xcassets/AppIcon.appiconset` (all sizes in
  `assets/images/icon.png` - generate with `flutter_launcher_icons` when the
  final art lands).
- Permission strings live in `ios/Runner/Info.plist` - add before shipping:
  `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `NSLocationWhenInUseUsageDescription`, `NSUserNotificationsUsageDescription`.

## 7. Run configuration / dart-defines

```bash
# Production API
flutter run --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://api.panditindia.com/v1 \
  --dart-define=USE_MOCK_API=false

# Development against mocks (default)
flutter run
```

## 8. Before every commit

```bash
flutter analyze
flutter test
```

## 9. Common failures

| Symptom | Fix |
| ------- | --- |
| `libxcrun` / `xcode-select` errors | Re-run the `sudo xcode-select -s ...` step |
| `No development certificates` | Signing & Capabilities → manage signing, or reset: `security delete-identity -c "Apple Development"` |
| Pods out of sync | `cd ios && pod install --repo-update` |
| Simulator not listed | Xcode → Settings → Platforms → add iOS runtime |
| `flutter doctor` shows Xcode "out of date" | Run `sudo xcodebuild -runFirstlaunch` |
