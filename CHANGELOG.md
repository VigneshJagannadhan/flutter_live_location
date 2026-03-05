## 0.7.0 — 2026-03-05

### Features

- add first-class permission API without requiring permission_handler

## 0.6.2 — 2026-03-05

### Bug Fixes

- throw LocationPermissionException when startTracking is called without permission instead of silently succeeding

## 0.6.1 — 2026-03-04

### Bug Fixes

- Fail fast with `LocationServiceDisabledException` when location services are disabled on `initialize()`

## 0.6.0 — 2026-03-04

### Bug Fixes

- Fixed release workflow to correctly detect version bumps when no prior tag existed

## 0.5.0 — 2026-03-01

### Bug Fixes

- Distance filter (`distanceFilterMeters`) and time interval now correctly wired to native Android (`setMinUpdateDistanceMeters`) and iOS (`CLLocationManager.distanceFilter`)

## 0.4.0 — 2026-03-01

### Bug Fixes

- Fixed iOS potential deadlock caused by `DispatchQueue.main.sync` in `CLLocationManager` callback; replaced with `NSLock` + `NotificationCenter` lifecycle observers
- Fixed Dart layer violation where the platform channel layer incorrectly imported and called back into the public API singleton; replaced with upward callback properties on `LiveLocationPlatform`

## 0.3.0 — 2026-03-01

### Bug Fixes

- Fixed pub.dev publish credential handling to write to both `~/.pub-cache/credentials.json` and `~/.config/dart/pub-credentials.json`
- Added JSON structure validation of `PUB_CREDENTIALS` secret before publishing
- Fixed release workflow ordering: publish to pub.dev before committing release tag, preventing false GitHub releases on publish failure

## 0.2.0 — 2026-03-01

### Bug Fixes

- Corrected GitHub URLs from `vignesh-jagannadhan` to `VigneshJagannadhan`
- Fixed README import path

## 0.1.0 — 2026-03-01

### Features

- Initial release of `flutter_live_location`
- Real-time location updates via a broadcast stream — foreground and background
- Configurable `LocationConfig` with time interval, accuracy level, and background toggle
- Five accuracy levels: `lowest`, `low`, `medium`, `high`, `best`
- Auto-stop timer: tracking stops automatically after the configured duration
- Last known location cache via `LiveLocation.instance.lastKnownLocation`
- Debug-mode logs for tracking start, stop, and permission-denied events

### Android

- Uses `FusedLocationProviderClient` for battery-efficient location
- Foreground service with a persistent notification for background tracking (Android 8+)
- Handles `ACCESS_BACKGROUND_LOCATION` (Android 10+), `FOREGROUND_SERVICE_LOCATION` (Android 12+), and `POST_NOTIFICATIONS` (Android 13+)
- WakeLock management to prevent CPU sleep during active tracking

### iOS

- Uses `CLLocationManager` for location updates
- Background location mode support with `allowsBackgroundLocationUpdates`
- Significant-change mode support for low-power background awareness
- Retain-cycle-safe delegate via weak references

### Error Handling

- Nine typed exceptions: `LocationPermissionException`, `LocationServiceDisabledException`, `LocationInitializationException`, `LocationAlreadyInitializedException`, `LocationNotInitializedException`, `LocationDisposedException`, `LocationConfigurationException`, `LocationPlatformException`, `LocationPlatformNotSupportedException`

### Platform Support

| Platform | Minimum version |
|---|---|
| Android | API 21 (Android 5.0) |
| iOS | 11.0 |
