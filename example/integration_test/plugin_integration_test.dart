// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_live_location/flutter_live_location.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Initialize and start tracking', (WidgetTester tester) async {
    // Initialize the plugin
    await LiveLocation.initialize(
      config: LocationConfig(
        timeIntervalSeconds: 2,
        accuracy: LocationAccuracy.high,
        enableBackground: false,
      ),
    );

    // Plugin should be initialized
    expect(LiveLocation.instance.isInitialized, true);

    // Start tracking for a short duration
    await LiveLocation.instance.startLocationUpdates(Duration(seconds: 5));
    expect(LiveLocation.instance.isTracking, true);

    // Stop tracking
    await LiveLocation.instance.stopLocationUpdates();
    expect(LiveLocation.instance.isTracking, false);

    // Dispose
    await LiveLocation.instance.dispose();
    expect(LiveLocation.instance.isInitialized, false);
  });
}
