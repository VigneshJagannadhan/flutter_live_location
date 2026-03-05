/// Tests for foreground/background location streams and permission handling.
///
/// These tests verify that:
///   - Foreground and background location streams emit correctly.
///   - [LiveLocation.isTracking] reflects the correct state at all times.
///   - When permission is denied, [LocationPermissionException] is thrown and
///     tracking state is left unchanged.
///   - The MethodChannel handler processes native permission-denied callbacks
///     without throwing.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_live_location/flutter_live_location.dart';
import 'package:flutter_live_location/live_location_method_channel.dart';
import 'package:flutter_live_location/live_location_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ─── Mock platforms ───────────────────────────────────────────────────────────

/// A mock platform where all operations succeed and no real native calls occur.
class _SuccessMockPlatform
    with MockPlatformInterfaceMixin
    implements LiveLocationPlatform {
  @override
  void Function(LocationUpdate)? onForegroundLocation;

  @override
  void Function(LocationUpdate)? onBackgroundLocation;

  @override
  Future<void> initialize({required LocationConfig config}) => Future.value();

  @override
  Future<void> startNativeTracking(LocationConfig config) => Future.value();

  @override
  Future<void> stopNativeTracking() => Future.value();

  @override
  void onStreamListened() {}

  @override
  void onStreamCancelled() {}

  @override
  Future<LocationPermissionStatus> checkPermission() =>
      Future.value(LocationPermissionStatus.granted);

  @override
  Future<LocationPermissionStatus> requestPermission() =>
      Future.value(LocationPermissionStatus.granted);

  @override
  Future<bool> checkLocationServiceEnabled() => Future.value(true);

  @override
  Future<void> dispose() => Future.value();
}

/// A mock platform that simulates location permission being denied.
///
/// [startNativeTracking] throws [LocationPermissionException], mirroring the
/// behaviour of a real device where the user has not granted location access.
class _PermissionDeniedMockPlatform
    with MockPlatformInterfaceMixin
    implements LiveLocationPlatform {
  @override
  void Function(LocationUpdate)? onForegroundLocation;

  @override
  void Function(LocationUpdate)? onBackgroundLocation;

  @override
  Future<void> initialize({required LocationConfig config}) => Future.value();

  @override
  Future<void> startNativeTracking(LocationConfig config) async {
    throw LocationPermissionException(
      message: 'Location permission not granted',
    );
  }

  @override
  Future<void> stopNativeTracking() => Future.value();

  @override
  void onStreamListened() {}

  @override
  void onStreamCancelled() {}

  @override
  Future<LocationPermissionStatus> checkPermission() =>
      Future.value(LocationPermissionStatus.denied);

  @override
  Future<LocationPermissionStatus> requestPermission() =>
      Future.value(LocationPermissionStatus.denied);

  @override
  Future<bool> checkLocationServiceEnabled() => Future.value(true);

  @override
  Future<void> dispose() => Future.value();
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

LocationConfig _config({bool background = false}) => LocationConfig(
  timeIntervalSeconds: 1,
  accuracy: LocationAccuracy.high,
  enableBackground: background,
);

const _foregroundUpdate = LocationUpdate(
  latitude: 10.0,
  longitude: 20.0,
  timestampMs: 1000,
);

const _backgroundUpdate = LocationUpdate(
  latitude: 48.8566,
  longitude: 2.3522,
  timestampMs: 2000,
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LiveLocationPlatform.instance = _SuccessMockPlatform();
  });

  tearDown(() async {
    // Dispose the singleton if it is still alive from a test.
    try {
      await LiveLocation.instance.dispose();
    } catch (_) {}
  });

  // ─── Foreground stream ───────────────────────────────────────────────────

  group('Foreground location stream', () {
    test('emits a location update to all active listeners', () async {
      await LiveLocation.initialize(config: _config());

      final received = <LocationUpdate>[];
      final sub = LiveLocation.instance.foregroundLocationStream.listen(
        received.add,
      );

      LiveLocationPlatform.instance.onForegroundLocation?.call(
        _foregroundUpdate,
      );
      await Future.microtask(() {});

      expect(received, hasLength(1));
      expect(received.first.latitude, _foregroundUpdate.latitude);
      expect(received.first.longitude, _foregroundUpdate.longitude);

      await sub.cancel();
    });

    test(
      'supports multiple simultaneous listeners (broadcast stream)',
      () async {
        await LiveLocation.initialize(config: _config());

        final first = <LocationUpdate>[];
        final second = <LocationUpdate>[];

        final sub1 = LiveLocation.instance.foregroundLocationStream.listen(
          first.add,
        );
        final sub2 = LiveLocation.instance.foregroundLocationStream.listen(
          second.add,
        );

        LiveLocationPlatform.instance.onForegroundLocation?.call(
          _foregroundUpdate,
        );
        await Future.microtask(() {});

        expect(first, hasLength(1));
        expect(second, hasLength(1));

        await sub1.cancel();
        await sub2.cancel();
      },
    );

    test('caches the last foreground update in lastKnownLocation', () async {
      await LiveLocation.initialize(config: _config());

      expect(LiveLocation.instance.lastKnownLocation, isNull);

      LiveLocationPlatform.instance.onForegroundLocation?.call(
        _foregroundUpdate,
      );
      await Future.microtask(() {});

      expect(
        LiveLocation.instance.lastKnownLocation?.latitude,
        _foregroundUpdate.latitude,
      );
    });

    test('stream completes cleanly when dispose is called', () async {
      await LiveLocation.initialize(config: _config());

      var streamDone = false;
      LiveLocation.instance.foregroundLocationStream.listen(
        (_) {},
        onDone: () => streamDone = true,
      );

      await LiveLocation.instance.dispose();
      await Future.microtask(() {});

      expect(streamDone, isTrue);
    });
  });

  // ─── Background stream ───────────────────────────────────────────────────

  group('Background location stream', () {
    test('emits a location update to all active listeners', () async {
      await LiveLocation.initialize(config: _config(background: true));

      final received = <LocationUpdate>[];
      final sub = LiveLocation.instance.backgroundLocationStream.listen(
        received.add,
      );

      LiveLocationPlatform.instance.onBackgroundLocation?.call(
        _backgroundUpdate,
      );
      await Future.microtask(() {});

      expect(received, hasLength(1));
      expect(received.first.latitude, _backgroundUpdate.latitude);
      expect(received.first.longitude, _backgroundUpdate.longitude);

      await sub.cancel();
    });

    test('caches the last background update in lastKnownLocation', () async {
      await LiveLocation.initialize(config: _config(background: true));

      LiveLocationPlatform.instance.onBackgroundLocation?.call(
        _backgroundUpdate,
      );
      await Future.microtask(() {});

      expect(
        LiveLocation.instance.lastKnownLocation?.latitude,
        _backgroundUpdate.latitude,
      );
    });

    test(
      'background update overwrites a prior foreground update in lastKnownLocation',
      () async {
        await LiveLocation.initialize(config: _config(background: true));

        LiveLocationPlatform.instance.onForegroundLocation?.call(
          _foregroundUpdate,
        );
        LiveLocationPlatform.instance.onBackgroundLocation?.call(
          _backgroundUpdate,
        );
        await Future.microtask(() {});

        // The most recent emission wins.
        expect(
          LiveLocation.instance.lastKnownLocation?.latitude,
          _backgroundUpdate.latitude,
        );
      },
    );

    test('stream completes cleanly when dispose is called', () async {
      await LiveLocation.initialize(config: _config(background: true));

      var streamDone = false;
      LiveLocation.instance.backgroundLocationStream.listen(
        (_) {},
        onDone: () => streamDone = true,
      );

      await LiveLocation.instance.dispose();
      await Future.microtask(() {});

      expect(streamDone, isTrue);
    });
  });

  // ─── Permission handling ─────────────────────────────────────────────────

  group('Permission handling', () {
    test(
      'throws LocationPermissionException when permission is denied',
      () async {
        LiveLocationPlatform.instance = _PermissionDeniedMockPlatform();
        await LiveLocation.initialize(config: _config());

        await expectLater(
          LiveLocation.instance.startLocationUpdates(
            const Duration(minutes: 1),
          ),
          throwsA(isA<LocationPermissionException>()),
        );
      },
    );

    test('isTracking remains false when permission is denied', () async {
      LiveLocationPlatform.instance = _PermissionDeniedMockPlatform();
      await LiveLocation.initialize(config: _config());

      try {
        await LiveLocation.instance.startLocationUpdates(
          const Duration(minutes: 1),
        );
      } on LocationPermissionException {
        // Expected — the platform rejected the start call.
      }

      expect(LiveLocation.instance.isTracking, isFalse);
    });

    test('isTracking becomes true when permission is granted', () async {
      await LiveLocation.initialize(config: _config());

      await LiveLocation.instance.startLocationUpdates(
        const Duration(minutes: 1),
      );

      expect(LiveLocation.instance.isTracking, isTrue);
    });

    test('isTracking becomes false after stopLocationUpdates', () async {
      await LiveLocation.initialize(config: _config());

      await LiveLocation.instance.startLocationUpdates(
        const Duration(minutes: 1),
      );
      expect(LiveLocation.instance.isTracking, isTrue);

      await LiveLocation.instance.stopLocationUpdates();
      expect(LiveLocation.instance.isTracking, isFalse);
    });

    test('startLocationUpdates is idempotent: second call while tracking '
        'only refreshes the auto-stop timer', () async {
      await LiveLocation.initialize(config: _config());

      await LiveLocation.instance.startLocationUpdates(
        const Duration(minutes: 1),
      );
      // Call again while already tracking — must not throw or duplicate tracking.
      await LiveLocation.instance.startLocationUpdates(
        const Duration(minutes: 2),
      );

      expect(LiveLocation.instance.isTracking, isTrue);
    });

    // ── Native → Dart permission callback ────────────────────────────────

    test(
      'method channel handles a native PERMISSION_DENIED callback gracefully',
      () async {
        // This test verifies that the Dart handler registered by
        // MethodChannelLiveLocation.initialize() processes the "onError"
        // invocation that Android/iOS push when location permission is missing,
        // without throwing an exception.

        const methodChannelName = 'com.flutter_live_location/methods';
        const channel = MethodChannel(methodChannelName);

        // Mock every method call from Dart → native to return success.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall call) async {
              return null;
            });

        final platform = MethodChannelLiveLocation();
        await platform.initialize(config: _config());

        // Simulate native pushing onError('PERMISSION_DENIED') back to Dart,
        // which is what Android's LocationManager does when permission is missing.
        const codec = StandardMethodCodec();
        final ByteData data = codec.encodeMethodCall(
          const MethodCall('onError', {
            'code': 'PERMISSION_DENIED',
            'message': 'Location permission not granted',
          }),
        );

        // The handler must complete without throwing.
        await expectLater(
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(methodChannelName, data, (ByteData? _) {}),
          completes,
        );

        // Cleanup channel mock.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      },
    );

    test(
      'method channel handles an unknown native error callback gracefully',
      () async {
        const methodChannelName = 'com.flutter_live_location/methods';
        const channel = MethodChannel(methodChannelName);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall call) async {
              return null;
            });

        final platform = MethodChannelLiveLocation();
        await platform.initialize(config: _config());

        const codec = StandardMethodCodec();
        final ByteData data = codec.encodeMethodCall(
          const MethodCall('onError', {
            'code': 'SERVICE_DISABLED',
            'message': 'Location services are off',
          }),
        );

        await expectLater(
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(methodChannelName, data, (ByteData? _) {}),
          completes,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      },
    );
  });
}
