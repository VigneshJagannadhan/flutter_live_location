/// Location accuracy levels for GPS updates.
///
/// Higher accuracy levels consume more battery but provide more precise locations.
enum LocationAccuracy {
  /// ~3500m accuracy, low battery consumption
  lowest,

  /// ~500m accuracy, moderate battery consumption
  low,

  /// ~100m accuracy, balanced battery consumption
  medium,

  /// ~5-50m accuracy, high battery consumption
  high,

  /// ~0-5m accuracy, very high battery consumption
  best,
}
