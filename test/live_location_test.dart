import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_live_location/flutter_live_location.dart';
import 'package:flutter_live_location/live_location_platform_interface.dart';
import 'package:flutter_live_location/live_location_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLiveLocationPlatform
    with MockPlatformInterfaceMixin
    implements LiveLocationPlatform {
  @override
  void Function(LocationUpdate)? onForegroundLocation;

  @override
  void Function(LocationUpdate)? onBackgroundLocation;

  @override
  void Function(LocationException)? onError;

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

void main() {
  final LiveLocationPlatform initialPlatform = LiveLocationPlatform.instance;

  test('$MethodChannelLiveLocation is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLiveLocation>());
  });

  testWidgets('Initialize and manage singleton', (WidgetTester tester) async {
    final config = LocationConfig(
      timeIntervalSeconds: 2,
      accuracy: LocationAccuracy.high,
      enableBackground: false,
    );

    MockLiveLocationPlatform fakePlatform = MockLiveLocationPlatform();
    LiveLocationPlatform.instance = fakePlatform;

    await LiveLocation.initialize(config: config);
    expect(LiveLocation.instance.isInitialized, true);

    await LiveLocation.instance.dispose();
  });
}
