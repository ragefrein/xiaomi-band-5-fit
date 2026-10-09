# Setup — turn this overlay into a runnable Flutter app

This folder is an **overlay** (source files), not a full Flutter project.

```bash
# 1. Create a fresh Flutter project
flutter create --org com.example --project-name miband5_app my_band_app
cd my_band_app

# 2. Copy this overlay over it
cp ../miband5_app/pubspec.yaml .
rm -rf lib && cp -r ../miband5_app/lib lib
cp -r ../miband5_app/test test

# 3. Install deps
flutter pub get
```

## Android — permissions
Open `android/app/src/main/AndroidManifest.xml` and add the `<uses-permission>`
lines from `docs/AndroidManifest_permissions.xml` (inside `<manifest>`, before
`<application>`).

## Android — min SDK
In `android/app/build.gradle` (or `build.gradle.kts`) set:
```gradle
defaultConfig {
    minSdkVersion 21   // flutter_blue_plus needs >= 21
}
```

## iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connect to your Mi Band 5</string>
```

## Run
BLE does **not** work on emulators/simulators — use a physical phone:
```bash
flutter run
```
