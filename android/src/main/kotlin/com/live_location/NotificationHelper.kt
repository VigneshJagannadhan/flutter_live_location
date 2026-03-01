package com.live_location

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

/// Helper for creating and managing foreground service notifications.
///
/// Handles Android version differences for notification APIs (8+ requires channels).
class NotificationHelper(private val context: Context) {
    companion object {
        private const val CHANNEL_ID = "live_location_channel"
        private const val CHANNEL_NAME = "Location Tracking"
    }

    private val notificationManager: NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /// Creates the notification channel (required for Android 8+).
    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when live location tracking is active"
                enableLights(false)
                enableVibration(false)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    /// Creates the foreground service notification.
    fun createNotification(
        title: String = "Location Tracking",
        message: String = "Live location is being tracked"
    ): Notification {
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_map)  // Standard map icon
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)  // Foreground service notification
            .setAutoCancel(false)
            .build()
    }

    /// Updates the notification with new text.
    fun updateNotification(
        notificationId: Int,
        title: String,
        message: String
    ) {
        val notification = createNotification(title, message)
        notificationManager.notify(notificationId, notification)
    }
}
