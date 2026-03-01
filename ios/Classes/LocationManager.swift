import CoreLocation
import Foundation
import UIKit

/// Manages location updates using CLLocationManager on iOS.
///
/// Handles location delegate callbacks, filtering, and background tracking.
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let timeIntervalSeconds: Int32
    private let accuracy: String
    private let enableBackground: Bool

    private let foregroundEventSink: ([String: Any?]) -> Void
    private let backgroundEventSink: ([String: Any?]) -> Void
    private let onError: (String, String) -> Void

    private var isTracking = false
    private var hasListeners = false
    private var lastEmittedLocation: CLLocation?
    private var lastEmissionTime: Date?

    weak var plugin: LiveLocationPlugin?

    init(
        plugin: LiveLocationPlugin,
        timeIntervalSeconds: Int32,
        accuracy: String,
        enableBackground: Bool,
        foregroundEventSink: @escaping ([String: Any?]) -> Void,
        backgroundEventSink: @escaping ([String: Any?]) -> Void,
        onError: @escaping (String, String) -> Void
    ) {
        self.timeIntervalSeconds = timeIntervalSeconds
        self.accuracy = accuracy
        self.enableBackground = enableBackground
        self.foregroundEventSink = foregroundEventSink
        self.backgroundEventSink = backgroundEventSink
        self.onError = onError

        super.init()

        setupLocationManager()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self

        // Set desired accuracy
        locationManager.desiredAccuracy = getAccuracyLevel(from: accuracy)

        // Enable background location updates if requested
        if enableBackground {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        }
    }

    private func getAccuracyLevel(from accuracy: String) -> CLLocationAccuracy {
        switch accuracy.lowercased() {
        case "lowest":
            return kCLLocationAccuracyThreeKilometers
        case "low":
            return kCLLocationAccuracyKilometer
        case "medium":
            return kCLLocationAccuracyHundredMeters
        case "high":
            return kCLLocationAccuracyNearestTenMeters
        case "best":
            return kCLLocationAccuracyBest
        default:
            return kCLLocationAccuracyNearestTenMeters
        }
    }

    // MARK: - Tracking Control

    func startTracking() {
        if isTracking { return }

        // Check and request permissions
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        default:
            onError("PERMISSION_DENIED", "Location permission not granted")
            return
        }

        locationManager.startUpdatingLocation()
        isTracking = true
    }

    func stopTracking() {
        if !isTracking { return }

        locationManager.stopUpdatingLocation()
        isTracking = false
    }

    func onStreamListened() {
        hasListeners = true
    }

    func onStreamCancelled() {
        hasListeners = false
        if isTracking {
            stopTracking()
        }
    }

    func dispose() {
        stopTracking()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard hasListeners else { return }

        for location in locations {
            // Apply time and distance filters
            if shouldEmitLocation(location) {
                let locationMap = locationToMap(location)
                
                // Determine application state on the main thread
                var isForeground = true
                if Thread.isMainThread {
                    isForeground = UIApplication.shared.applicationState != .background
                } else {
                    DispatchQueue.main.sync {
                        isForeground = UIApplication.shared.applicationState != .background
                    }
                }

                if isForeground {
                    foregroundEventSink(locationMap)
                } else if enableBackground {
                    backgroundEventSink(locationMap)
                }

                lastEmittedLocation = location
                lastEmissionTime = Date()
            }
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        onError("LOCATION_ERROR", error.localizedDescription)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .denied, .restricted:
            onError("PERMISSION_DENIED", "Location permission was denied or restricted")
        default:
            break
        }
    }

    // MARK: - Filtering

    private func shouldEmitLocation(_ location: CLLocation) -> Bool {
        guard let lastTime = lastEmissionTime else {
            return true
        }

        // Check time interval
        let timeSinceLastEmission = Date().timeIntervalSince(lastTime)
        if timeSinceLastEmission >= Double(timeIntervalSeconds) {
            return true
        }

        return false
    }

    private func locationToMap(_ location: CLLocation) -> [String: Any?] {
        return [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "altitude": location.altitude,
            "accuracy": location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil,
            "heading": location.course >= 0 ? location.course : nil,
            "speed": location.speed >= 0 ? location.speed : nil,
            "timestampMs": Int64(location.timestamp.timeIntervalSince1970 * 1000)
        ]
    }
}
