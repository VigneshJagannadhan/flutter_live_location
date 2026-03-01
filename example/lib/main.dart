import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_live_location/flutter_live_location.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the plugin once at startup
  try {
    await LiveLocation.initialize(
      config: LocationConfig(
        timeIntervalSeconds: 1,
        accuracy: LocationAccuracy.high,
        enableBackground: true,
      ),
    );
  } catch (e) {
    debugPrint('Failed to initialize plugin: $e');
  }

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
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  StreamSubscription<LocationUpdate>? _locationForegroundSubscription;
  StreamSubscription<LocationUpdate>? _locationBackgroundSubscription;

  @override
  void initState() {
    super.initState();
    _setupLocationListener();
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    try {
      final status = await Permission.location.status;
      setState(() {
        _permissionStatus = status;
      });
    } catch (e) {
      debugPrint('Error checking initial permission: $e');
    }
  }

  void _setupLocationListener() {
    _locationForegroundSubscription = LiveLocation
        .instance
        .foregroundLocationStream
        .listen(
          (location) {
            log(
              "Live Location Foreground Updates : ${location.latitude} ${location.longitude}",
            );
            setState(() {
              _lastLocation = location;
            });
          },
          onError: (error) {
            debugPrint('Location stream error: $error');
          },
        );

    _locationBackgroundSubscription = LiveLocation
        .instance
        .backgroundLocationStream
        .listen(
          (location) {
            log(
              "Live Location Background Updates : ${location.latitude} ${location.longitude}",
            );
            setState(() {
              _lastLocation = location;
            });
          },
          onError: (error) {
            debugPrint('Location stream error: $error');
          },
        );
  }

  Future<void> _startTracking() async {
    try {
      // Ensure permission granted using permission_handler
      if (!_permissionStatus.isGranted) {
        final status = await Permission.location.request();
        setState(() {
          _permissionStatus = status;
        });
        if (!status.isGranted) {
          debugPrint('Permission denied, cannot start tracking');
          return;
        }
      }

      await LiveLocation.instance.startLocationUpdates(Duration(minutes: 1));
      setState(() {
        _isTracking = true;
      });
    } catch (e) {
      debugPrint('Error starting tracking: $e');
    }
  }

  Future<void> _stopTracking() async {
    try {
      await LiveLocation.instance.stopLocationUpdates();
      setState(() {
        _isTracking = false;
      });
    } catch (e) {
      debugPrint('Error stopping tracking: $e');
    }
  }

  @override
  void dispose() {
    _locationForegroundSubscription?.cancel();
    _locationBackgroundSubscription?.cancel();
    LiveLocation.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissionText = 'Permission: ${_permissionStatus.name}';
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Live Location')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                permissionText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _isTracking ? 'Tracking: ON' : 'Tracking: OFF',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              if (_lastLocation != null) ...[
                Text('Latitude: ${_lastLocation!.latitude.toStringAsFixed(6)}'),
                Text(
                  'Longitude: ${_lastLocation!.longitude.toStringAsFixed(6)}',
                ),
                Text(
                  'Accuracy: ${_lastLocation!.accuracy?.toStringAsFixed(2)} m',
                ),
              ] else ...[
                const Text('No location data yet'),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final status = await Permission.location.request();
                  setState(() {
                    _permissionStatus = status;
                  });
                },
                child: const Text('Request Permission'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isTracking ? _stopTracking : _startTracking,
                child: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
