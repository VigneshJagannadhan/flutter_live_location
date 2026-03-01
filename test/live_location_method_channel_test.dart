import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_live_location/live_location_method_channel.dart';
import 'package:flutter_live_location/models/location_config.dart';
import 'package:flutter_live_location/models/location_accuracy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelLiveLocation platform = MethodChannelLiveLocation();
  const MethodChannel channel = MethodChannel(
    'com.flutter_live_location/methods',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'initialize':
              return null;
            case 'startTracking':
              return null;
            case 'stopTracking':
              return null;
            case 'dispose':
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize', () async {
    final config = LocationConfig(
      timeIntervalSeconds: 2,
      accuracy: LocationAccuracy.high,
      enableBackground: false,
    );
    // Should not throw
    await platform.initialize(config: config);
  });
}
