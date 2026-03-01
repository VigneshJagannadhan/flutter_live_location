package com.live_location

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build

/// Helper for managing foreground service lifecycle.
///
/// Handles starting/stopping the background location service with proper version handling.
object ForegroundServiceHelper {
    
    /// Starts the location foreground service.
    fun startLocationService(context: Context) {
        val intent = Intent(context, LocationService::class.java).apply {
            action = LocationService.ACTION_START_TRACKING
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    /// Stops the location foreground service.
    fun stopLocationService(context: Context) {
        val intent = Intent(context, LocationService::class.java).apply {
            action = LocationService.ACTION_STOP_TRACKING
        }
        context.startService(intent)
    }

    /// Checks if the location service is currently running.
    fun isLocationServiceRunning(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        return activityManager.getRunningServices(Int.MAX_VALUE).any {
            it.service.className == LocationService::class.java.name
        }
    }
}
