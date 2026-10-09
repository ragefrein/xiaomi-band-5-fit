# Mi Band 5 — Custom Flutter App (starter)

Personal companion app for a Xiaomi Mi Band 5, talking directly over BLE using
the Huami protocol (no Zepp cloud). Protocol values are ported from Gadgetbridge.

## What is implemented
- BLE scan for the band by MAC
- Connect + discover services + MTU bump
- **3-step Huami authentication** (challenge/response, AES-128-ECB)
- Auth key stored in secure storage

## What is NOT implemented yet (next milestones)
- Fetch activity/steps/sleep data (char 00000005)
- Live heart rate (HR service 180D + HR control point)
- Local database + dashboard

## Prerequisites
- Flutter SDK (3.3+)
- A **physical Android/iOS device** (BLE does not work on emulators)
- Your band's **auth key** (16 bytes) and **MAC address** — obtained via huafetcher

## Setup
```bash
flutter pub get
# Android: make sure minSdkVersion >= 21 in android/app/build.gradle
flutter run
```

Add the permissions from `android/app/src/main/AndroidManifest.xml` into your
real manifest (this file is a snippet/reference).

For iOS, add to `ios/Runner/Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connect to your Mi Band</string>
```

## Auth protocol (Mi Band 5)
| Step | Send (hex) | Band responds |
|------|------------|---------------|
| 1 | `01 08` + key(16B) | `10 01 01` |
| 2 | `02 08` | `10 02 01` + 16 random bytes |
| 3 | `03 08` + AES128ECB(random, key) | `10 03 01` = success |

If auth fails after a firmware update, try the "New Auth Protocol" variant
(Gadgetbridge device setting) — byte order differs slightly.

## License note
Protocol knowledge comes from Gadgetbridge (AGPLv3). If you distribute this app,
you must comply with AGPLv3. Personal use is fine.
