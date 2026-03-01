# live_location

A Flutter plugin for **real-time location tracking** with configurable update intervals and distance
filters — supporting both **foreground and background** tracking on Android and iOS.

---

## Why live_location?

Most location packages require a lot of boilerplate and confusing setup. `live_location` gets you
streaming GPS updates in **under 10 lines of code**:

```dart
await LiveLocation.initialize(
  config: LocationConfig(
    timeIntervalSeconds: 2,
    accuracy: LocationAccuracy.high,
    enableBackground: false,
  ),
);

LiveLocation.instance.foregroundLocationStream.listen((location) {
  print('${location.latitude}, ${location.longitude}');
});

await LiveLocation.instance.startLocationUpdates(Duration(minutes: 5));
```

That's it. No manual channel setup, no confusing callbacks — just a clean Dart stream.

---

## Features

- Real-time location updates via a simple broadcast stream
- Configurable time interval and distance filter
- Foreground and background tracking
- Android foreground service (required by Android OS for background location)
- iOS background location mode support
- Structured error handling with typed exceptions
- Automatically stops tracking after a configurable duration
- Zero dependencies beyond Flutter and `plugin_platform_interface`

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_live_location: ^0.0.1
  permission_handler: ^12.0.1  # Recommended for handling permissions
```

Then run:

```
flutter pub get
```

---

## Platform Setup

### Android

The plugin's `AndroidManifest.xml` already declares all required permissions automatically.
However, if you enable **background tracking**, also add the following to your **app's**
`android/app/src/main/AndroidManifest.xml` inside the `<manifest>` tag:

```xml
<!-- Required for foreground and background location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Background location — Android 10+ -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Foreground service — Android 9+ -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- Foreground service type — Android 12+ -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<!-- Notification permission — Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

> **Note:** You do not need to register the `LocationService` — the plugin handles that internally.

---

### iOS

Open `ios/Runner/Info.plist` and add the following keys. The values are the messages shown
to the user in the permission dialog — customise them for your app:

```xml
<!-- Required for foreground location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to show you live updates.</string>

<!-- Required only if you enable background tracking -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs your location in the background to keep tracking.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs your location in the background to keep tracking.</string>
```

If you use background tracking, also enable the **Background Modes** capability in Xcode:

1. Open `Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Click **+ Capability** and add **Background Modes**.
4. Check **Location updates**.

---

## Handling Permissions

> This is the part most developers get stuck on. Follow these steps and you will have no
> permission issues.

The recommended approach is to use the
[`permission_handler`](https://pub.dev/packages/permission_handler) package alongside this plugin.

### Step 1 — Add permission_handler

```yaml
dependencies:
  permission_handler: ^12.0.1
```

### Step 2 — Android minimum SDK

In your `android/app/build.gradle`, make sure `minSdk` is at least **21**:

```gradle
android {
    defaultConfig {
        minSdk 21
    }
}
```

### Step 3 — Request foreground permission

Call this before `startLocationUpdates`:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestLocationPermission() async {
  PermissionStatus status = await Permission.location.status;

  if (status.isGranted) return true;

  // Ask the user
  status = await Permission.location.request();

  if (status.isGranted) return true;

  if (status.isPermanentlyDenied) {
    // User selected "Don't ask again" — send them to Settings
    await openAppSettings();
  }

  return false;
}
```

### Step 4 — Request background permission (optional)

Only required when you set `enableBackground: true`:

```dart
Future<bool> requestBackgroundPermission() async {
  // Foreground must be granted first
  final foreground = await requestLocationPermission();
  if (!foreground) return false;

  PermissionStatus status = await Permission.locationAlways.status;
  if (status.isGranted) return true;

  status = await Permission.locationAlways.request();
  return status.isGranted;
}
```

### Step 5 — Android 13+ notification permission

Background tracking shows a foreground service notification on Android. Android 13 requires
you to explicitly request notification permission:

```dart
if (await Permission.notification.isDenied) {
  await Permission.notification.request();
}
```

### Putting it all together

```dart
Future<void> startTrackingWithPermissions() async {
  final hasPermission = await requestLocationPermission();
  if (!hasPermission) {
    print('Location permission denied.');
    return;
  }

  // Android 13+ — request notification permission for the foreground service
  await Permission.notification.request();

  await LiveLocation.instance.startLocationUpdates(Duration(minutes: 10));
}
```

---

## Quick Start

### 1 — Initialize (once, at app startup)

Call `initialize` before anything else — the best place is inside `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LiveLocation.initialize(
    config: LocationConfig(
      timeIntervalSeconds: 2,       // Minimum seconds between updates
      accuracy: LocationAccuracy.high,
      enableBackground: false,      // Set true for background tracking
    ),
  );

  runApp(const MyApp());
}
```

### 2 — Listen to the stream

Set up your listener *before* you start tracking so you don't miss any updates:

```dart
LiveLocation.instance.foregroundLocationStream.listen((location) {
  print('Lat: ${location.latitude}, Lng: ${location.longitude}');
  print('Accuracy: ${location.accuracy} m');
});
```

### 3 — Start tracking

```dart
// Track for 10 minutes, then stop automatically
await LiveLocation.instance.startLocationUpdates(Duration(minutes: 10));
```

### 4 — Stop tracking manually

```dart
await LiveLocation.instance.stopLocationUpdates();
```

### 5 — Clean up

Call `dispose` when you no longer need location updates (e.g., in a widget's `dispose`):

```dart
@override
void dispose() {
  LiveLocation.instance.dispose();
  super.dispose();
}
```

---

## Background Tracking

To receive location updates when the app is in the background:

```dart
await LiveLocation.initialize(
  config: LocationConfig(
    timeIntervalSeconds: 5,
    accuracy: LocationAccuracy.medium,  // Medium/low saves battery
    enableBackground: true,
  ),
);

// Background updates arrive on this stream
LiveLocation.instance.backgroundLocationStream.listen((location) {
  print('Background: ${location.latitude}, ${location.longitude}');
});
```

> **Android:** The plugin automatically starts a foreground service with a persistent
> notification when background tracking is active. This is required by the Android OS —
> you cannot do silent background location on Android.

> **iOS:** Make sure you have added the `NSLocationAlwaysAndWhenInUseUsageDescription` key
> to `Info.plist` and enabled the **Location updates** background mode in Xcode (see
> Platform Setup above).

---

## Configuration Reference

### LocationConfig

| Parameter | Type | Description |
|---|---|---|
| `timeIntervalSeconds` | `int` | Minimum seconds between location updates. Must be > 0. |
| `accuracy` | `LocationAccuracy` | Desired GPS accuracy level. |
| `enableBackground` | `bool` | Whether to continue tracking when the app is backgrounded. |

### LocationAccuracy

| Value | Approx. accuracy | Battery usage | Best for |
|---|---|---|---|
| `lowest` | ~3500 m | Minimal | City-level awareness |
| `low` | ~500 m | Low | Neighbourhood-level |
| `medium` | ~100 m | Moderate | General navigation |
| `high` | ~5–50 m | High | Turn-by-turn, delivery |
| `best` | ~0–5 m | Very high | Sub-metre precision |

---

## API Reference

### Initialisation

```dart
// Call once at app startup
await LiveLocation.initialize(config: LocationConfig(...));

// Access the singleton after initialisation
LiveLocation.instance
```

### Tracking control

```dart
// Start — auto-stops after the given duration
await LiveLocation.instance.startLocationUpdates(Duration(minutes: 10));

// Stop manually at any time
await LiveLocation.instance.stopLocationUpdates();

// Dispose and reset — call in widget dispose()
await LiveLocation.instance.dispose();
```

### Streams

```dart
// Foreground updates (app is visible)
LiveLocation.instance.foregroundLocationStream  // Stream<LocationUpdate>

// Background updates (app is in the background, requires enableBackground: true)
LiveLocation.instance.backgroundLocationStream  // Stream<LocationUpdate>
```

### LocationUpdate fields

| Field | Type | Description |
|---|---|---|
| `latitude` | `double` | Latitude in degrees |
| `longitude` | `double` | Longitude in degrees |
| `altitude` | `double?` | Altitude in metres above sea level |
| `accuracy` | `double?` | Horizontal accuracy radius in metres |
| `heading` | `double?` | Direction of travel in degrees (0–360) |
| `speed` | `double?` | Speed in metres per second |
| `timestampMs` | `int` | Unix timestamp in milliseconds |

### State properties

```dart
LiveLocation.instance.isInitialized     // bool
LiveLocation.instance.isTracking        // bool
LiveLocation.instance.lastKnownLocation // LocationUpdate?
```

---

## Error Handling

All plugin errors extend `LocationException`. Handle the specific types you care about:

```dart
try {
  await LiveLocation.instance.startLocationUpdates(Duration(minutes: 5));
} on LocationPermissionException {
  print('Please grant location permission first.');
} on LocationServiceDisabledException {
  print('Enable location services in device Settings.');
} on LocationNotInitializedException {
  print('Call LiveLocation.initialize() first.');
} on LocationDisposedException {
  print('Plugin disposed. Call initialize() again.');
} on LocationException catch (e) {
  print('Location error: $e');
}
```

| Exception | When thrown |
|---|---|
| `LocationPermissionException` | Location permission not granted |
| `LocationServiceDisabledException` | Device location services are off |
| `LocationInitializationException` | `initialize()` failed |
| `LocationAlreadyInitializedException` | `initialize()` called more than once |
| `LocationNotInitializedException` | Method called before `initialize()` |
| `LocationDisposedException` | Method called after `dispose()` |
| `LocationConfigurationException` | Invalid config values |
| `LocationPlatformException` | Unexpected native platform error |

---

## Complete Example

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:live_location/live_location.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LiveLocation.initialize(
    config: LocationConfig(
      timeIntervalSeconds: 2,
      accuracy: LocationAccuracy.high,
      enableBackground: false,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  LocationUpdate? _lastLocation;
  bool _isTracking = false;
  StreamSubscription<LocationUpdate>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = LiveLocation.instance.foregroundLocationStream.listen(
      (location) => setState(() => _lastLocation = location),
    );
  }

  Future<void> _start() async {
    final status = await Permission.location.request();
    if (!status.isGranted) return;

    await LiveLocation.instance.startLocationUpdates(Duration(minutes: 5));
    setState(() => _isTracking = true);
  }

  Future<void> _stop() async {
    await LiveLocation.instance.stopLocationUpdates();
    setState(() => _isTracking = false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    LiveLocation.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Live Location Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isTracking ? 'Tracking: ON' : 'Tracking: OFF',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 16),
              if (_lastLocation != null) ...[
                Text('Lat: ${_lastLocation!.latitude.toStringAsFixed(6)}'),
                Text('Lng: ${_lastLocation!.longitude.toStringAsFixed(6)}'),
                Text('Accuracy: ${_lastLocation!.accuracy?.toStringAsFixed(1)} m'),
              ] else
                const Text('Waiting for location...'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isTracking ? _stop : _start,
                child: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## FAQ

**Q: I'm not receiving any location updates.**

Make sure you have:
1. Called `initialize()` at app startup before anything else.
2. Set up your stream listener *before* calling `startLocationUpdates()`.
3. Granted location permission (see the Handling Permissions section).
4. Turned on location services on the device.

---

**Q: Background tracking stopped on Android after a few minutes.**

Android kills background processes aggressively. Check:
- `enableBackground: true` is set in `LocationConfig`.
- The user has not restricted background activity for your app in Battery settings.
- `ACCESS_BACKGROUND_LOCATION` is declared in `AndroidManifest.xml`.

---

**Q: No location in the iOS Simulator.**

Use the built-in simulation: **Features → Location** in the Simulator menu and pick a
preset or enter custom coordinates.

---

**Q: Can I re-initialize with different settings?**

Yes — dispose first, then initialize again:

```dart
await LiveLocation.instance.dispose();
await LiveLocation.initialize(config: newConfig);
```

---

**Q: Does this plugin store or transmit my location data?**

No. Location data is streamed directly to your listeners and is never stored, logged (in
release builds), or sent anywhere by the plugin.

---

## Author

Created by **Vignesh Jagannadhan (Vignesh K)**.

---

## License

MIT — see the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening
a pull request.
