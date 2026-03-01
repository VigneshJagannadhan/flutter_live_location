import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'exceptions/location_exceptions.dart';
import 'live_location_platform_interface.dart';
import 'models/location_config.dart';
import 'models/location_update.dart';

/// MethodChannel implementation of LiveLocationPlatform.
///
/// This uses platform channels to communicate with native code on Android and iOS.
class MethodChannelLiveLocation extends LiveLocationPlatform {
  /// The MethodChannel used for communication with native code.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.flutter_live_location/methods');

  /// The EventChannel for foreground location updates.
  @visibleForTesting
  final foregroundEventChannel = const EventChannel(
    'com.flutter_live_location/foreground_locations',
  );

  /// The EventChannel for background location updates.
  @visibleForTesting
  final backgroundEventChannel = const EventChannel(
    'com.flutter_live_location/background_locations',
  );

  /// Converts a map from platform to LocationUpdate.
  static LocationUpdate _locationFromMap(Map<dynamic, dynamic> map) {
    return LocationUpdate(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      timestampMs: (map['timestampMs'] as num?)?.toInt(),
    );
  }

  @override
  Future<void> initialize({required LocationConfig config}) async {
    try {
      await methodChannel.invokeMethod('initialize', {
        'timeIntervalSeconds': config.timeIntervalSeconds,
        'accuracy': config.accuracy.toString().split('.').last,
        'enableBackground': config.enableBackground,
      });

      // Handle callbacks pushed from native (e.g. permission errors)
      methodChannel.setMethodCallHandler(_handleNativeCallback);

      // Set up event channel listeners
      _setupEventChannels();
    } on PlatformException catch (e) {
      throw LocationPlatformException(
        message: e.message ?? 'Platform initialization failed',
        code: e.code,
      );
    }
  }

  /// Handles method calls pushed from native to Dart.
  ///
  /// Native code may invoke methods on the channel to report asynchronous
  /// events such as permission errors that occur outside a direct method call.
  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    if (call.method == 'onError') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      final code = args?['code'] as String?;
      final message = args?['message'] as String?;

      if (code == 'PERMISSION_DENIED') {
        debugPrint(
          '[LiveLocation] You need permission. '
          'Please grant location permission before starting tracking.',
        );
      } else {
        debugPrint('[LiveLocation] Native error [$code]: $message');
      }
    }
  }

  /// Sets up listeners for EventChannels from native platform.
  ///
  /// Parsed [LocationUpdate] objects are delivered via the
  /// [onForegroundLocation] and [onBackgroundLocation] callbacks set on the
  /// platform interface by the public API layer. This keeps the method channel
  /// layer decoupled from the public API singleton.
  void _setupEventChannels() {
    foregroundEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        try {
          final location = _locationFromMap(event as Map<dynamic, dynamic>);
          onForegroundLocation?.call(location);
        } catch (e) {
          debugPrint('Error parsing foreground location: $e');
        }
      },
      onError: (error) {
        debugPrint('Foreground location stream error: $error');
      },
    );

    backgroundEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        try {
          final location = _locationFromMap(event as Map<dynamic, dynamic>);
          onBackgroundLocation?.call(location);
        } catch (e) {
          debugPrint('Error parsing background location: $e');
        }
      },
      onError: (error) {
        debugPrint('Background location stream error: $error');
      },
    );
  }

  @override
  Future<void> startNativeTracking(LocationConfig config) async {
    try {
      await methodChannel.invokeMethod('startTracking', {
        'timeIntervalSeconds': config.timeIntervalSeconds,
      });
    } on PlatformException catch (e) {
      throw LocationPlatformException(
        message: e.message ?? 'Failed to start tracking',
        code: e.code,
      );
    }
  }

  @override
  Future<void> stopNativeTracking() async {
    try {
      await methodChannel.invokeMethod('stopTracking');
    } on PlatformException catch (e) {
      throw LocationPlatformException(
        message: e.message ?? 'Failed to stop tracking',
        code: e.code,
      );
    }
  }

  @override
  void onStreamListened() {
    try {
      methodChannel.invokeMethod('onStreamListened');
    } catch (e) {
      debugPrint('Error calling onStreamListened: $e');
    }
  }

  @override
  void onStreamCancelled() {
    try {
      methodChannel.invokeMethod('onStreamCancelled');
    } catch (e) {
      debugPrint('Error calling onStreamCancelled: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await methodChannel.invokeMethod('dispose');
    } on PlatformException catch (e) {
      throw LocationPlatformException(
        message: e.message ?? 'Failed to dispose',
        code: e.code,
      );
    }
  }
}
