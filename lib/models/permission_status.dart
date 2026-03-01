/// Permission status for location access.
enum PermissionStatus {
  /// Permission not yet requested from user
  notRequested,

  /// Permission granted for location access while app is in use
  whileInUse,

  /// Permission granted for location access always (foreground and background)
  always,

  /// Permission denied by user
  denied,

  /// Permission restricted (OS level, e.g., parental controls)
  restricted,

  /// Permission status cannot be determined
  unknown,
}
