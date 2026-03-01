import 'dart:math' as math;

/// Represents a single location update with coordinates and metadata.
///
/// This immutable model contains latitude, longitude, altitude, accuracy,
/// and the timestamp when the location was captured.
class LocationUpdate {
  /// Latitude in degrees [-90, 90]
  final double latitude;

  /// Longitude in degrees [-180, 180]
  final double longitude;

  /// Altitude in meters above sea level
  final double? altitude;

  /// Horizontal accuracy in meters (lower is better)
  final double? accuracy;

  /// Heading/bearing in degrees [0, 360)
  final double? heading;

  /// Speed in meters per second
  final double? speed;

  /// Unix timestamp in milliseconds when location was captured
  final int timestampMs;

  /// Creates a location update.
  ///
  /// [latitude] and [longitude] are required.
  /// [timestampMs] defaults to current time if not provided.
  const LocationUpdate({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.heading,
    this.speed,
    int? timestampMs,
  }) : timestampMs = timestampMs ?? 0;

  /// Calculates distance in meters to another location using Haversine formula.
  ///
  /// Returns the great-circle distance between this location and [other].
  double distanceTo(LocationUpdate other) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);

    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  @override
  String toString() =>
      'LocationUpdate(lat: $latitude, lon: $longitude, alt: $altitude, '
      'acc: $accuracy, heading: $heading, speed: $speed, time: $timestampMs)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationUpdate &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          altitude == other.altitude &&
          accuracy == other.accuracy &&
          heading == other.heading &&
          speed == other.speed &&
          timestampMs == other.timestampMs;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      altitude.hashCode ^
      accuracy.hashCode ^
      heading.hashCode ^
      speed.hashCode ^
      timestampMs.hashCode;
}
