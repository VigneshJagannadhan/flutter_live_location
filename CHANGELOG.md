## 0.6.1 — 2026-03-04

### Bug Fixes

- fail fast with LocationServiceDisabledException when location services are disabled on initialize

## 0.6.0 — 2026-03-04

### Features

- initial release of flutter_live_location

### Bug Fixes

- workflow fixes
- Distance and time filters fixed
- critical bug fixes
- critical bug fixes
- write pub credentials to both paths and validate JSON structure
- harden pub.dev credentials write and add empty-secret guard
- publish before committing release to prevent false releases
- correct GitHub URLs and README import

## 0.5.0 — 2026-03-01

### Features

- initial release of flutter_live_location

### Bug Fixes

- Distance and time filters fixed
- critical bug fixes
- critical bug fixes
- write pub credentials to both paths and validate JSON structure
- harden pub.dev credentials write and add empty-secret guard
- publish before committing release to prevent false releases
- correct GitHub URLs and README import

## 0.4.0 — 2026-03-01

### Features

- initial release of flutter_live_location

### Bug Fixes

- critical bug fixes
- critical bug fixes
- write pub credentials to both paths and validate JSON structure
- harden pub.dev credentials write and add empty-secret guard
- publish before committing release to prevent false releases
- correct GitHub URLs and README import

## 0.3.0 — 2026-03-01

### Features

- initial release of flutter_live_location

### Bug Fixes

- write pub credentials to both paths and validate JSON structure
- harden pub.dev credentials write and add empty-secret guard
- publish before committing release to prevent false releases
- correct GitHub URLs and README import

## 0.2.0 — 2026-03-01

### Features

- initial release of flutter_live_location

### Bug Fixes

- correct GitHub URLs and README import

## 0.1.0 — 2026-03-01

### Features

- initial release of flutter_live_location

## 0.0.1

Initial release of `flutter_live_location`.

### Features

- Real-time location updates via a simple broadcast stream — foreground and background.
- Configurable `LocationConfig` with time interval, accuracy level, and background toggle.
- Five accuracy levels: `lowest`, `low`, `medium`, `high`, `best`.
- Auto-stop timer: tracking stops automatically after the duration passed to
  `startLocationUpdates`.
- Last known location cache via `LiveLocation.instance.lastKnownLocation`.
- Debug-mode logs for tracking start, stop, and permission-denied events.

### Android

- Uses `FusedLocationProviderClient` for battery-efficient location.
- Foreground service with a persistent notification for background tracking (Android 8+).
- Handles `ACCESS_BACKGROUND_LOCATION` (Android 10+), `FOREGROUND_SERVICE_LOCATION`
  (Android 12+), and `POST_NOTIFICATIONS` (Android 13+).
- WakeLock management to prevent CPU sleep during active tracking.

### iOS

- Uses `CLLocationManager` for location updates.
- Background location mode support with `allowsBackgroundLocationUpdates`.
- Significant-change mode support for low-power background awareness.
- Retain-cycle-safe delegate via weak references.

### Error handling

Nine typed exceptions: `LocationPermissionException`,
`LocationServiceDisabledException`, `LocationInitializationException`,
`LocationAlreadyInitializedException`, `LocationNotInitializedException`,
`LocationDisposedException`, `LocationConfigurationException`,
`LocationPlatformException`, `LocationPlatformNotSupportedException`.

### Platform support

| Platform | Minimum version |
|---|---|
| Android | API 21 (Android 5.0) |
| iOS | 11.0 |
