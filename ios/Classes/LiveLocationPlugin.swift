import Flutter
import CoreLocation

/// Manages foreground location stream
private class ForegroundLocationStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    weak var locationManager: LocationManager?

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events
        locationManager?.onStreamListened()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        let plugin = locationManager?.plugin
        if plugin?.backgroundStreamHandler?.eventSink == nil {
            locationManager?.onStreamCancelled()
        }
        return nil
    }
}

/// Manages background location stream
private class BackgroundLocationStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    weak var locationManager: LocationManager?

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events
        locationManager?.onStreamListened()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        let plugin = locationManager?.plugin
        if plugin?.foregroundStreamHandler?.eventSink == nil {
            locationManager?.onStreamCancelled()
        }
        return nil
    }
}

/// Main plugin class for Live Location tracking on iOS.
///
/// Manages the lifecycle of location tracking, permissions, and communication
/// with the Dart layer via method and event channels.
public class LiveLocationPlugin: NSObject, FlutterPlugin {
    static let METHOD_CHANNEL = "com.flutter_live_location/methods"
    static let FOREGROUND_EVENT_CHANNEL = "com.flutter_live_location/foreground_locations"
    static let BACKGROUND_EVENT_CHANNEL = "com.flutter_live_location/background_locations"

    private var methodChannel: FlutterMethodChannel?
    private var foregroundEventChannel: FlutterEventChannel?
    private var backgroundEventChannel: FlutterEventChannel?

    private var locationManager: LocationManager?
    fileprivate var foregroundStreamHandler: ForegroundLocationStreamHandler?
    fileprivate var backgroundStreamHandler: BackgroundLocationStreamHandler?


    public static func dummyMethodToEnforceBundling() {
        // This enforces bundling of the class
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = LiveLocationPlugin()
        instance.setupChannels(with: registrar.messenger())
    }

    public func dummyMethodToEnforceBundling() {
        // Do nothing
    }

    // MARK: - FlutterPlugin

    public static func dummy(withIdentifier identifier: String) {}

    func setupChannels(with binaryMessenger: FlutterBinaryMessenger) {
        // Method channel
        methodChannel = FlutterMethodChannel(
            name: Self.METHOD_CHANNEL,
            binaryMessenger: binaryMessenger
        )
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        // Foreground event channel with dedicated handler
        foregroundStreamHandler = ForegroundLocationStreamHandler()
        foregroundEventChannel = FlutterEventChannel(
            name: Self.FOREGROUND_EVENT_CHANNEL,
            binaryMessenger: binaryMessenger
        )
        foregroundEventChannel?.setStreamHandler(foregroundStreamHandler)

        // Background event channel with dedicated handler
        backgroundStreamHandler = BackgroundLocationStreamHandler()
        backgroundEventChannel = FlutterEventChannel(
            name: Self.BACKGROUND_EVENT_CHANNEL,
            binaryMessenger: binaryMessenger
        )
        backgroundEventChannel?.setStreamHandler(backgroundStreamHandler)
    }

    // MARK: - Method Call Handler

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "initialize":
            initialize(call, result: result)
        case "startTracking":
            startTracking(call, result: result)
        case "stopTracking":
            stopTracking(result: result)

        case "onStreamListened":
            locationManager?.onStreamListened()
            result(nil)
        case "onStreamCancelled":
            locationManager?.onStreamCancelled()
            result(nil)
        case "dispose":
            dispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initialize(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard CLLocationManager.locationServicesEnabled() else {
            result(FlutterError(
                code: "LOCATION_SERVICE_DISABLED",
                message: "Location services are disabled on this device. " +
                    "Enable location in Settings > Privacy > Location Services.",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments",
                details: nil
            ))
            return
        }

        do {
            let timeInterval = args["timeIntervalSeconds"] as? Int ?? 2
            let accuracy = args["accuracy"] as? String ?? "high"
            let enableBackground = args["enableBackground"] as? Bool ?? false
            let distanceFilter = args["distanceFilterMeters"] as? Double ?? 0.0
            locationManager = LocationManager(
                plugin: self,
                timeIntervalSeconds: Int32(timeInterval),
                accuracy: accuracy,
                enableBackground: enableBackground,
                distanceFilterMeters: distanceFilter,
                foregroundEventSink: { [weak self] location in
                    self?.foregroundStreamHandler?.eventSink?(location)
                },
                backgroundEventSink: { [weak self] location in
                    self?.backgroundStreamHandler?.eventSink?(location)
                },
                onError: { [weak self] code, message in
                    self?.methodChannel?.invokeMethod(
                        "onError",
                        arguments: ["code": code, "message": message]
                    )
                }
            )

            // Link stream handlers to location manager
            foregroundStreamHandler?.locationManager = locationManager
            backgroundStreamHandler?.locationManager = locationManager

            result(nil)
        } catch {
            result(FlutterError(
                code: "INIT_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    private func startTracking(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        do {
            try locationManager?.startTracking()
            result(nil)
        } catch LocationError.permissionDenied {
            result(FlutterError(
                code: "PERMISSION_DENIED",
                message: "Location permission not granted",
                details: nil
            ))
        } catch {
            result(FlutterError(
                code: "START_TRACKING_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    private func stopTracking(result: @escaping FlutterResult) {
        do {
            locationManager?.stopTracking()
            result(nil)
        } catch {
            result(FlutterError(
                code: "STOP_TRACKING_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }



    private func dispose(result: @escaping FlutterResult) {
        do {
            locationManager?.dispose()
            locationManager = nil
            result(nil)
        } catch {
            result(FlutterError(
                code: "DISPOSE_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    // Helper to forward errors to Dart via the method channel
    private func onError(_ code: String, _ message: String) {
        methodChannel?.invokeMethod(
            "onError",
            arguments: ["code": code, "message": message]
        )
    }


}
