import 'location_accuracy.dart';

/// Immutable configuration for location tracking.
///
/// All fields are final and cannot be changed after initialization.
/// This ensures predictable behavior throughout the plugin lifecycle.
class LocationConfig {
  /// Minimum time interval in seconds between emissions.
  /// Default: 2 seconds
  final int timeIntervalSeconds;

  /// Desired accuracy level for location updates.
  ///
  /// Higher accuracy consumes more battery. Choose based on use case.
  /// Default: [LocationAccuracy.high]
  final LocationAccuracy accuracy;

  /// Whether to enable background location tracking.
  ///
  /// When true, location updates continue even when app is backgrounded.
  /// Requires appropriate permissions and may consume significant battery.
  /// Default: false
  final bool enableBackground;

  /// Minimum distance in metres the device must move before an update is emitted.
  ///
  /// Set to 0 to disable distance filtering and rely on [timeIntervalSeconds]
  /// alone. On both platforms the value is forwarded to the native location
  /// provider, so the OS itself suppresses unnecessary wake-ups.
  /// Default: 0
  final double distanceFilterMeters;

  /// Creates a location tracking configuration.
  ///
  /// All parameters except those with defaults must be provided.
  /// The configuration is immutable and cannot be changed after creation.
  const LocationConfig({
    required this.timeIntervalSeconds,
    required this.accuracy,
    required this.enableBackground,
    this.distanceFilterMeters = 0,
  }) : assert(timeIntervalSeconds > 0, 'timeIntervalSeconds must be > 0'),
       assert(distanceFilterMeters >= 0, 'distanceFilterMeters must be >= 0');

  @override
  String toString() =>
      'LocationConfig('
      'interval: ${timeIntervalSeconds}s, '
      'accuracy: $accuracy, '
      'distance: ${distanceFilterMeters}m, '
      'background: $enableBackground'
      ')';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationConfig &&
          runtimeType == other.runtimeType &&
          timeIntervalSeconds == other.timeIntervalSeconds &&
          accuracy == other.accuracy &&
          enableBackground == other.enableBackground &&
          distanceFilterMeters == other.distanceFilterMeters;

  @override
  int get hashCode =>
      timeIntervalSeconds.hashCode ^
      accuracy.hashCode ^
      enableBackground.hashCode ^
      distanceFilterMeters.hashCode;
}
