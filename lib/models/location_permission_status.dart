/// The permission status for location access.
///
/// Returned by [LiveLocation.checkPermission] and [LiveLocation.requestPermission].
enum LocationPermissionStatus {
  /// Location permission is granted.
  granted,

  /// Location permission has been denied but can still be requested again.
  ///
  /// On Android this means the user has not permanently denied the permission.
  /// On iOS this means the permission dialog has not yet been shown
  /// (`notDetermined`).
  denied,

  /// Location permission has been permanently denied.
  ///
  /// The user must navigate to the app's Settings page to grant it.
  /// On Android: denied and `shouldShowRequestPermissionRationale` is false.
  /// On iOS: the user explicitly denied the prompt.
  deniedForever,

  /// Location permission is restricted by the system.
  ///
  /// iOS only — typically due to parental controls or MDM policy.
  /// The user cannot change this status from within the app.
  restricted,
}
