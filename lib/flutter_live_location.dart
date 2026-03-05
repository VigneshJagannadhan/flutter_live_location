/// The flutter_live_location plugin.
///
/// This plugin provides real-time location tracking with configurable
/// distance filters and time intervals, supporting both foreground and
/// background tracking on Android and iOS.

library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'exceptions/location_exceptions.dart';
import 'live_location_platform_interface.dart';
import 'models/location_config.dart';
import 'models/location_permission_status.dart';
import 'models/location_update.dart';

// Export public API
export 'models/location_accuracy.dart';
export 'models/location_config.dart';
export 'models/location_permission_status.dart';
export 'models/location_update.dart';
export 'exceptions/location_exceptions.dart';

/// Main API for the live location tracking plugin.
///
/// This is a singleton that manages location tracking lifecycle.
///
/// Usage:
/// ```dart
/// // 1. Initialize once at app startup
/// await LiveLocation.initialize(
///   config: LocationConfig(
///     timeIntervalSeconds: 2,
///     accuracy: LocationAccuracy.high,
///     enableBackground: true,
///   ),
/// );
///
/// // 2. Listen to updates
/// LiveLocation.instance.foregroundLocationStream.listen((location) {
///   print('Location: ${location.latitude}, ${location.longitude}');
/// });
///
/// // 3. Start tracking for 5 minutes
/// await LiveLocation.instance.startLocationUpdates(Duration(minutes: 5));
///
/// // 4. Stop when done (optional, auto-stops after 5 mins)
/// await LiveLocation.instance.stopLocationUpdates();
///
/// // 5. Cleanup at app shutdown
/// await LiveLocation.instance.dispose();
/// ```
class LiveLocation {
  // Private singleton instance
  static LiveLocation? _instance;

  // Platform interface
  final LiveLocationPlatform _platform = LiveLocationPlatform.instance;

  // Broadcast streams for foreground and background locations
  late StreamController<LocationUpdate> _foregroundStreamController;
  late StreamController<LocationUpdate> _backgroundStreamController;

  // State management
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _isTracking = false;

  // Configuration and timing
  late final LocationConfig _config;
  Timer? _autoStopTimer;

  // Cache last known location
  LocationUpdate? _lastKnownLocation;

  /// Gets the singleton instance.
  ///
  /// Throws [LocationNotInitializedException] if not initialized.
  static LiveLocation get instance {
    if (_instance == null) {
      throw LocationNotInitializedException();
    }
    return _instance!;
  }

  /// Initializes the plugin with the given configuration.
  ///
  /// This must be called exactly once before using any other methods.
  ///
  /// Throws [LocationAlreadyInitializedException] if already initialized.
  /// Throws [LocationInitializationException] on platform errors.
  /// Throws [LocationConfigurationException] if config is invalid.
  static Future<void> initialize({required LocationConfig config}) async {
    if (_instance != null) {
      throw LocationAlreadyInitializedException(
        message:
            'LiveLocation already initialized. Call dispose() first to '
            're-initialize with different config.',
      );
    }

    try {
      _instance = LiveLocation._internal(config);
      await _instance!._initializePlatform();
    } catch (e) {
      _instance = null;
      if (e is LocationException) {
        rethrow;
      }
      throw LocationInitializationException(
        message: 'Initialization failed: $e',
      );
    }
  }

  // Private constructor
  LiveLocation._internal(LocationConfig config) : _config = config {
    _initializeStreams();
  }

  /// Initializes the broadcast stream controllers.
  void _initializeStreams() {
    _foregroundStreamController = StreamController<LocationUpdate>.broadcast(
      onListen: _onStreamListened,
      onCancel: _onStreamCancelled,
    );

    _backgroundStreamController = StreamController<LocationUpdate>.broadcast(
      onListen: _onStreamListened,
      onCancel: _onStreamCancelled,
    );
  }

  /// Initializes the platform-specific implementation.
  Future<void> _initializePlatform() async {
    try {
      // Call platform initialization
      await _platform.initialize(config: _config);
      _isInitialized = true;

      // Set up native event listeners
      _setupPlatformListeners();
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationPlatformException(
        message: 'Platform initialization failed',
        code: e.toString(),
      );
    }
  }

  /// Wires the platform interface callbacks to this instance's stream controllers.
  ///
  /// The platform channel layer calls [onForegroundLocation] and
  /// [onBackgroundLocation] when native events arrive. By setting these here —
  /// in the public API layer — we keep the method channel layer free of any
  /// reference to this class, eliminating the circular dependency.
  void _setupPlatformListeners() {
    _platform.onForegroundLocation = _onForegroundLocation;
    _platform.onBackgroundLocation = _onBackgroundLocation;
  }

  void _onForegroundLocation(LocationUpdate location) {
    if (_isDisposed) return;
    _lastKnownLocation = location;
    _foregroundStreamController.add(location);
  }

  void _onBackgroundLocation(LocationUpdate location) {
    if (_isDisposed) return;
    _lastKnownLocation = location;
    _backgroundStreamController.add(location);
  }

  /// Called when a stream gets its first listener.
  void _onStreamListened() {
    if (!_isTracking) {
      // Start native location updates when first listener subscribes
      _platformInstance.onStreamListened();
    }
  }

  /// Called when a stream loses all listeners.
  void _onStreamCancelled() {
    // Check if any stream still has listeners
    // If not, we can stop native updates for battery optimization
    _platformInstance.onStreamCancelled();
  }

  /// Stream of foreground location updates.
  ///
  /// Emits location updates based on configured time interval.
  /// Multiple listeners are supported (broadcast stream).
  Stream<LocationUpdate> get foregroundLocationStream =>
      _foregroundStreamController.stream;

  /// Stream of background location updates.
  ///
  /// Only emits if [LocationConfig.enableBackground] is true.
  /// Multiple listeners are supported (broadcast stream).
  Stream<LocationUpdate> get backgroundLocationStream =>
      _backgroundStreamController.stream;

  /// Gets the last known location, or null if none received yet.
  LocationUpdate? get lastKnownLocation => _lastKnownLocation;

  /// Whether the plugin is currently initialized.
  bool get isInitialized => _isInitialized;

  /// Whether location tracking is currently active.
  bool get isTracking => _isTracking;

  /// Returns the current location permission status without prompting the user.
  ///
  /// Throws [LocationNotInitializedException] if not initialized.
  Future<LocationPermissionStatus> checkPermission() async {
    _checkInitializedAndNotDisposed();
    return _platform.checkPermission();
  }

  /// Requests location permission from the user.
  ///
  /// Shows the system permission dialog if the status is not permanently
  /// denied. Returns the resulting [LocationPermissionStatus].
  ///
  /// Throws [LocationNotInitializedException] if not initialized.
  Future<LocationPermissionStatus> requestPermission() async {
    _checkInitializedAndNotDisposed();
    return _platform.requestPermission();
  }

  /// Returns true if the device's location services are currently enabled.
  ///
  /// Location services can be disabled globally in device Settings regardless
  /// of whether the app has permission. Check this before starting tracking.
  ///
  /// Throws [LocationNotInitializedException] if not initialized.
  Future<bool> checkLocationServiceEnabled() async {
    _checkInitializedAndNotDisposed();
    return _platform.checkLocationServiceEnabled();
  }

  /// Starts location tracking for the specified duration.
  ///
  /// Location updates continue until [duration] elapses, then auto-stop occurs.
  /// Can be called while already tracking to update duration.
  ///
  /// Throws [LocationNotInitializedException] if not initialized.
  /// Throws [LocationDisposedException] if already disposed.
  Future<void> startLocationUpdates(Duration duration) async {
    _checkInitializedAndNotDisposed();

    try {
      if (!_isTracking) {
        // Start native location updates
        await _platform.startNativeTracking(_config);
        _isTracking = true;
        if (kDebugMode) {
          debugPrint('[LiveLocation] Location updates started.');
        }
      }

      // Cancel existing auto-stop timer if any
      _autoStopTimer?.cancel();

      // Schedule auto-stop after duration
      _autoStopTimer = Timer(duration, () async {
        await stopLocationUpdates();
      });
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationPlatformException(
        message: 'Failed to start location updates',
        code: e.toString(),
      );
    }
  }

  /// Stops location tracking immediately.
  ///
  /// Cancels the auto-stop timer if active.
  /// Streams remain open for re-subscription.
  ///
  /// Throws [LocationNotInitializedException] if not initialized.
  /// Throws [LocationDisposedException] if already disposed.
  Future<void> stopLocationUpdates() async {
    _checkInitializedAndNotDisposed();

    try {
      // Cancel auto-stop timer
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      if (_isTracking) {
        // Stop native location updates
        await _platform.stopNativeTracking();
        _isTracking = false;
        if (kDebugMode) {
          debugPrint('[LiveLocation] Location updates stopped.');
        }
      }
    } catch (e) {
      throw LocationPlatformException(
        message: 'Failed to stop location updates',
        code: e.toString(),
      );
    }
  }

  /// Disposes the plugin and cleans up all resources.
  ///
  /// After calling dispose, the singleton is reset and [initialize] can be
  /// called again.
  ///
  /// Throws [LocationNotInitializedException] if not initialized.
  Future<void> dispose() async {
    if (!_isInitialized) {
      throw LocationNotInitializedException();
    }

    try {
      // Stop tracking if active
      if (_isTracking) {
        await stopLocationUpdates();
      }

      // Cancel auto-stop timer
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      // Close streams
      await _foregroundStreamController.close();
      await _backgroundStreamController.close();

      // Detach callbacks before platform dispose so a stale reference to this
      // instance cannot receive events after the singleton has been reset.
      _platform.onForegroundLocation = null;
      _platform.onBackgroundLocation = null;

      // Call platform dispose
      await _platform.dispose();

      // Reset state
      _isInitialized = false;
      _isDisposed = true;
      _lastKnownLocation = null;

      // Reset singleton
      _instance = null;
    } catch (e) {
      throw LocationPlatformException(
        message: 'Failed to dispose plugin',
        code: e.toString(),
      );
    }
  }

  /// Checks if plugin is initialized and not disposed.
  void _checkInitializedAndNotDisposed() {
    if (!_isInitialized) {
      throw LocationNotInitializedException();
    }
    if (_isDisposed) {
      throw LocationDisposedException();
    }
  }

  /// Reference to platform interface (for internal use).
  static LiveLocationPlatform get _platformInstance =>
      LiveLocationPlatform.instance;
}
