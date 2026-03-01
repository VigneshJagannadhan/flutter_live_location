package com.live_location

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder

/// Foreground Service for background location tracking.
///
/// This service keeps the location tracking alive even when the app is backgrounded.
/// Required on Android 8+ and mandatory for background location updates.
class LocationService : Service() {
    companion object {
        private const val NOTIFICATION_ID = 42
        const val CHANNEL_ID = "live_location_channel"
        const val NOTIFICATION_CHANNEL_NAME = "Location Tracking"
        const val ACTION_START_TRACKING = "com.live_location.START_TRACKING"
        const val ACTION_STOP_TRACKING = "com.live_location.STOP_TRACKING"
    }

    private var locationManager: LocationManager? = null
    private var notificationHelper: NotificationHelper? = null
    private var isServiceRunning = false

    // Wake lock to keep CPU awake while tracking
    private var wakeLock: android.os.PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        notificationHelper = NotificationHelper(this)
        notificationHelper?.createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_TRACKING -> startTracking()
            ACTION_STOP_TRACKING -> stopTracking()
        }

        return START_STICKY
    }

    override fun onDestroy() {
        stopTracking()
        notificationHelper = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /// Starts foreground location tracking with service notification.
    private fun startTracking() {
        if (isServiceRunning) return

        try {
            // Start foreground with notification
            val notification = notificationHelper?.createNotification(
                title = "Location Tracking",
                message = "Live location tracking is active"
            )

            if (notification != null) {
                startForeground(NOTIFICATION_ID, notification)
            }

            // Acquire partial wake lock so CPU won't sleep
            acquireWakeLock()

            isServiceRunning = true
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    /// Stops tracking and removes foreground notification.
    private fun stopTracking() {
        if (!isServiceRunning) return

        try {
            locationManager?.stopTracking()
            locationManager = null
            isServiceRunning = false

            // Release wake lock if held
            releaseWakeLock()

            // Stop foreground service
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /// Sets the location manager for this service.
    fun setLocationManager(manager: LocationManager) {
        this.locationManager = manager
    }

    /// Acquire a partial wake lock to keep CPU on while tracking.
    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        wakeLock = pm.newWakeLock(
            android.os.PowerManager.PARTIAL_WAKE_LOCK,
            "com.live_location:WakeLock"
        )
        wakeLock?.acquire(10 * 60 * 1000L /*10 minutes*/)
    }

    /// Release the previously acquired wake lock, if any.
    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
    }


}
