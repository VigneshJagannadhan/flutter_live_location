/// Base exception for all live location plugin errors.
abstract class LocationException implements Exception {
  /// Human-readable error message
  final String message;

  LocationException(this.message);

  @override
  String toString() => message;
}

/// Thrown when location services are not available or disabled on the device.
///
/// User should enable location services in device settings.
class LocationServiceDisabledException extends LocationException {
  LocationServiceDisabledException({
    String message = 'Location services are disabled',
  }) : super(message);
}

/// Thrown when required location permission is not granted.
///
/// User should grant the permission in app settings or via permission dialog.
class LocationPermissionException extends LocationException {
  LocationPermissionException({
    String message = 'Location permission not granted',
  }) : super(message);
}

/// Thrown when plugin initialization fails.
///
/// This may indicate invalid configuration, native platform error,
/// or double initialization attempt.
class LocationInitializationException extends LocationException {
  LocationInitializationException({
    String message = 'Failed to initialize live location plugin',
  }) : super(message);
}

/// Thrown when attempting to initialize the plugin multiple times.
///
/// The plugin uses a singleton pattern and can only be initialized once.
/// Call [dispose] before re-initializing if needed.
class LocationAlreadyInitializedException extends LocationException {
  LocationAlreadyInitializedException({
    String message = 'Live location plugin already initialized',
  }) : super(message);
}

/// Thrown when platform channel communication fails.
///
/// This indicates a native platform error or communication breakdown.
class LocationPlatformException extends LocationException {
  /// The platform-specific error code
  final String? code;

  LocationPlatformException({required String message, this.code})
    : super(message);

  @override
  String toString() => code != null ? '$message (code: $code)' : message;
}

/// Thrown when an operation is attempted before initialization.
///
/// Call [LiveLocation.initialize] first.
class LocationNotInitializedException extends LocationException {
  LocationNotInitializedException({
    String message = 'Live location plugin not initialized',
  }) : super(message);
}

/// Thrown when an operation is attempted after disposal.
///
/// After calling [dispose], create a new instance by calling [initialize] again.
class LocationDisposedException extends LocationException {
  LocationDisposedException({
    String message = 'Live location plugin has been disposed',
  }) : super(message);
}

/// Thrown when invalid configuration is provided.
///
/// Check that all required configuration parameters are valid.
class LocationConfigurationException extends LocationException {
  LocationConfigurationException({required String message}) : super(message);
}

/// Thrown when an unsupported operation is requested on the current platform.
///
/// Some features may not be available on all platforms.
class LocationPlatformNotSupportedException extends LocationException {
  LocationPlatformNotSupportedException({
    String message = 'Operation not supported on this platform',
  }) : super(message);
}
