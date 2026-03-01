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

  /// Creates a location tracking configuration.
  ///
  /// All parameters except those with defaults must be provided.
  /// The configuration is immutable and cannot be changed after creation.
  const LocationConfig({
    required this.timeIntervalSeconds,
    required this.accuracy,
    required this.enableBackground,
  }) : assert(timeIntervalSeconds > 0, 'timeIntervalSeconds must be > 0');

  @override
  String toString() =>
      'LocationConfig('
      'interval: ${timeIntervalSeconds}s, '
      'accuracy: $accuracy, '
      'background: $enableBackground'
      ')';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationConfig &&
          runtimeType == other.runtimeType &&
          timeIntervalSeconds == other.timeIntervalSeconds &&
          accuracy == other.accuracy &&
          enableBackground == other.enableBackground;

  @override
  int get hashCode =>
      timeIntervalSeconds.hashCode ^
      accuracy.hashCode ^
      enableBackground.hashCode;
}
