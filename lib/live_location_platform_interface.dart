import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'live_location_method_channel.dart';
import 'models/location_config.dart';
import 'models/location_update.dart';

/// Abstract platform interface for live location tracking.
///
/// Platform-specific implementations (Android, iOS) must extend this class
/// and implement all abstract methods.
abstract class LiveLocationPlatform extends PlatformInterface {
  /// Constructs a LiveLocationPlatform.
  LiveLocationPlatform() : super(token: _token);

  static final Object _token = Object();

  static LiveLocationPlatform _instance = MethodChannelLiveLocation();

  /// The default instance of [LiveLocationPlatform] to use.
  ///
  /// Defaults to [MethodChannelLiveLocation].
  static LiveLocationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LiveLocationPlatform] when
  /// they register themselves.
  static set instance(LiveLocationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ---------------------------------------------------------------------------
  // Upward data callbacks
  //
  // Set by the public API layer (LiveLocation) during initialization so that
  // the platform channel layer can push location events upward without
  // importing or referencing the public API class.
  // ---------------------------------------------------------------------------

  /// Invoked by the platform channel layer when a foreground location arrives.
  ///
  /// The public API layer sets this during [initialize] via
  /// [LiveLocation._setupPlatformListeners]. Platform implementations must
  /// call this instead of reaching directly into the public API singleton.
  void Function(LocationUpdate)? onForegroundLocation;

  /// Invoked by the platform channel layer when a background location arrives.
  ///
  /// The public API layer sets this during [initialize] via
  /// [LiveLocation._setupPlatformListeners]. Platform implementations must
  /// call this instead of reaching directly into the public API singleton.
  void Function(LocationUpdate)? onBackgroundLocation;

  /// Initializes the platform-specific implementation.
  ///
  /// Called after Dart initialization to set up native resources.
  Future<void> initialize({required LocationConfig config}) async {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Starts native location tracking with the given configuration.
  Future<void> startNativeTracking(LocationConfig config) async {
    throw UnimplementedError('startNativeTracking() has not been implemented.');
  }

  /// Stops native location tracking.
  Future<void> stopNativeTracking() async {
    throw UnimplementedError('stopNativeTracking() has not been implemented.');
  }

  /// Called when a listener subscribes to the location stream.
  ///
  /// Used to optimize battery by starting updates only when needed.
  void onStreamListened() {
    throw UnimplementedError('onStreamListened() has not been implemented.');
  }

  /// Called when all listeners unsubscribe from the location stream.
  ///
  /// Used to optimize battery by stopping updates when not needed.
  void onStreamCancelled() {
    throw UnimplementedError('onStreamCancelled() has not been implemented.');
  }

  /// Disposes the platform-specific resources.
  Future<void> dispose() async {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
