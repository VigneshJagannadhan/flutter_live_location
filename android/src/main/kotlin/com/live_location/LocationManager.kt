package com.live_location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner

/// Manages location updates using FusedLocationProviderClient.
///
/// Handles location request configuration, listening lifecycle, and filtering.
class LocationManager(
    private val context: Context,
    private val timeIntervalSeconds: Int,
    private val accuracy: String,
    private val enableBackground: Boolean,
    private val foregroundEventSink: (Map<String, Any?>) -> Unit,
    private val backgroundEventSink: (Map<String, Any?>) -> Unit,
    private val onError: (String, String) -> Unit,
) {
    private val fusedLocationClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
    private lateinit var locationRequest: LocationRequest
    private lateinit var locationCallback: LocationCallback
    private var isTracking = false
    private var hasListeners = false
    private var isAppInForeground = false

    private val lifecycleObserver = object : DefaultLifecycleObserver {
        override fun onStart(owner: LifecycleOwner) {
            isAppInForeground = true
        }
        override fun onStop(owner: LifecycleOwner) {
            isAppInForeground = false
        }
    }

    init {
        createLocationRequest()
        setupLocationCallback()
        // Run on main thread usually by default init context
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            ProcessLifecycleOwner.get().lifecycle.addObserver(lifecycleObserver)
        }
    }

    /// Creates the LocationRequest with configured filters.
    private fun createLocationRequest() {
        locationRequest = LocationRequest.Builder(
            getPriorityFromAccuracy(accuracy),
            timeIntervalSeconds * 1000L
        )
            .build()
    }

    /// Maps accuracy string to Priority constant.
    private fun getPriorityFromAccuracy(accuracy: String): Int {
        return when (accuracy.lowercase()) {
            "lowest" -> Priority.PRIORITY_PASSIVE
            "low" -> Priority.PRIORITY_LOW_POWER
            "medium" -> Priority.PRIORITY_BALANCED_POWER_ACCURACY
            "high" -> Priority.PRIORITY_HIGH_ACCURACY
            "best" -> Priority.PRIORITY_HIGH_ACCURACY
            else -> Priority.PRIORITY_HIGH_ACCURACY
        }
    }

    /// Sets up the location callback handler.
    private fun setupLocationCallback() {
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    val locationMap = locationToMap(location)
                    // Emit to appropriate stream
                    if (isTracking) {
                        if (isAppInForeground) {
                            foregroundEventSink(locationMap)
                        } else if (enableBackground) {
                            backgroundEventSink(locationMap)
                        }
                    }
                }
            }
        }
    }

    /// Converts Android Location to a Map for Dart.
    private fun locationToMap(location: Location): Map<String, Any?> {
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "altitude" to (if (location.hasAltitude()) location.altitude else null),
            "accuracy" to (if (location.hasAccuracy()) location.accuracy.toDouble() else null),
            "heading" to (if (location.hasBearing()) location.bearing.toDouble() else null),
            "speed" to (if (location.hasSpeed()) location.speed.toDouble() else null),
            "timestampMs" to location.time
        )
    }

    /// Starts location tracking.
    fun startTracking() {
        if (isTracking) {
            return
        }

        // Check permissions
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            onError("PERMISSION_DENIED", "Location permission not granted")
            return
        }

        try {
            // Start foreground service if background tracking enabled
            if (enableBackground) {
                ForegroundServiceHelper.startLocationService(context)
            }

            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                null
            )
            isTracking = true
            
        } catch (e: Exception) {
            // Stop service if it was started but location request failed
            if (enableBackground) {
                ForegroundServiceHelper.stopLocationService(context)
            }
            onError("START_TRACKING_ERROR", e.message ?: "Failed to start tracking")
        }
    }

    /// Stops location tracking.
    fun stopTracking() {
        if (!isTracking) return

        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
            
            // Stop foreground service if background tracking was enabled
            if (enableBackground) {
                ForegroundServiceHelper.stopLocationService(context)
            }
            
            isTracking = false
        } catch (e: Exception) {
            onError("STOP_TRACKING_ERROR", e.message ?: "Failed to stop tracking")
        }
    }

    /// Called when a stream gets listeners.
    fun onStreamListened() {
        hasListeners = true
    }

    /// Called when all listeners unsubscribe.
    fun onStreamCancelled() {
        hasListeners = false
        if (isTracking) {
            stopTracking()
        }
    }

    /// Disposes resources.
    fun dispose() {
        if (isTracking) {
            stopTracking()
        }
        // Ensure service is stopped even if tracking wasn't active
        if (enableBackground) {
            ForegroundServiceHelper.stopLocationService(context)
        }
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            ProcessLifecycleOwner.get().lifecycle.removeObserver(lifecycleObserver)
        }
    }
}
