package com.live_location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/// Main plugin class for Live Location tracking on Android.
///
/// Manages the lifecycle of location tracking, permissions, and communication
/// with the Dart layer via method and event channels.
class LiveLocationPlugin : FlutterPlugin, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val METHOD_CHANNEL = "com.flutter_live_location/methods"
        private const val FOREGROUND_EVENT_CHANNEL = "com.flutter_live_location/foreground_locations"
        private const val BACKGROUND_EVENT_CHANNEL = "com.flutter_live_location/background_locations"
        private const val PERMISSION_REQUEST_CODE = 100
    }

    private lateinit var context: Context
    private var activity: android.app.Activity? = null
    private var activityPluginBinding: ActivityPluginBinding? = null
    private lateinit var methodChannel: MethodChannel
    private lateinit var foregroundEventChannel: EventChannel
    private lateinit var backgroundEventChannel: EventChannel

    private var locationManager: LocationManager? = null
    private var foregroundEventSink: EventChannel.EventSink? = null
    private var backgroundEventSink: EventChannel.EventSink? = null

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        // Set up method channel
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }

        // Set up event channels
        foregroundEventChannel = EventChannel(binding.binaryMessenger, FOREGROUND_EVENT_CHANNEL)
        foregroundEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                foregroundEventSink = events
                locationManager?.onStreamListened()
            }

            override fun onCancel(arguments: Any?) {
                foregroundEventSink = null
                if (backgroundEventSink == null) {
                    locationManager?.onStreamCancelled()
                }
            }
        })

        backgroundEventChannel = EventChannel(binding.binaryMessenger, BACKGROUND_EVENT_CHANNEL)
        backgroundEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                backgroundEventSink = events
                locationManager?.onStreamListened()
            }

            override fun onCancel(arguments: Any?) {
                backgroundEventSink = null
                if (foregroundEventSink == null) {
                    locationManager?.onStreamCancelled()
                }
            }
        })
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        foregroundEventChannel.setStreamHandler(null)
        backgroundEventChannel.setStreamHandler(null)
        locationManager?.dispose()
        activity = null
    }

    // ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityPluginBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityPluginBinding?.removeRequestPermissionsResultListener(this)
        activityPluginBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityPluginBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityPluginBinding?.removeRequestPermissionsResultListener(this)
        activityPluginBinding = null
        activity = null
    }

    // PluginRegistry.RequestPermissionsResultListener

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val pending = pendingPermissionResult ?: return false
        pendingPermissionResult = null

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (granted) {
            pending.success("granted")
        } else {
            val act = activity
            val showRationale = act != null && ActivityCompat.shouldShowRequestPermissionRationale(
                act, Manifest.permission.ACCESS_FINE_LOCATION
            )
            pending.success(if (showRationale) "denied" else "deniedForever")
        }
        return true
    }

    private fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            when (call.method) {
                "initialize" -> initialize(call, result)
                "startTracking" -> startTracking(call, result)
                "stopTracking" -> stopTracking(result)
                "onStreamListened" -> {
                    locationManager?.onStreamListened()
                    result.success(null)
                }
                "onStreamCancelled" -> {
                    locationManager?.onStreamCancelled()
                    result.success(null)
                }
                "checkPermission" -> checkPermission(result)
                "requestPermission" -> requestPermission(result)
                "checkLocationServiceEnabled" -> checkLocationServiceEnabled(result)
                "dispose" -> dispose(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("PLATFORM_ERROR", e.message, e.stackTraceToString())
        }
    }

    private fun initialize(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            val sysLocationManager = context.getSystemService(Context.LOCATION_SERVICE)
                as android.location.LocationManager
            if (!sysLocationManager.isLocationEnabled) {
                result.error(
                    "LOCATION_SERVICE_DISABLED",
                    "Location services are disabled on this device. " +
                        "Enable location in device settings before initializing.",
                    null
                )
                return
            }

            val timeInterval = (call.argument<Number>("timeIntervalSeconds") ?: 2).toInt()
            val accuracy = call.argument<String>("accuracy") ?: "high"
            val enableBackground = call.argument<Boolean>("enableBackground") ?: false
            val distanceFilter = (call.argument<Number>("distanceFilterMeters") ?: 0.0).toDouble()

            locationManager = LocationManager(
                context = context,
                timeIntervalSeconds = timeInterval,
                accuracy = accuracy,
                enableBackground = enableBackground,
                distanceFilterMeters = distanceFilter,
                foregroundEventSink = { location ->
                    foregroundEventSink?.success(location)
                },
                backgroundEventSink = { location ->
                    backgroundEventSink?.success(location)
                },
                onError = { code, message ->
                    methodChannel.invokeMethod("onError", mapOf("code" to code, "message" to message))
                }
            )

            result.success(null)
        } catch (e: Exception) {
            result.error("INIT_ERROR", e.message, null)
        }
    }

    private fun startTracking(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            locationManager?.startTracking()
            result.success(null)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
        } catch (e: Exception) {
            result.error("START_TRACKING_ERROR", e.message, null)
        }
    }

    private fun stopTracking(result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            locationManager?.stopTracking()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_TRACKING_ERROR", e.message, null)
        }
    }

    private fun checkPermission(result: MethodChannel.Result) {
        val fineGranted = ActivityCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ActivityCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        result.success(if (fineGranted || coarseGranted) "granted" else "denied")
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val fineGranted = ActivityCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        if (fineGranted) {
            result.success("granted")
            return
        }

        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity is not available for permission request", null)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            act,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
            PERMISSION_REQUEST_CODE
        )
    }

    private fun checkLocationServiceEnabled(result: MethodChannel.Result) {
        val sysLocationManager = context.getSystemService(Context.LOCATION_SERVICE)
            as android.location.LocationManager
        result.success(sysLocationManager.isLocationEnabled)
    }

    private fun dispose(result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            locationManager?.dispose()
            locationManager = null
            result.success(null)
        } catch (e: Exception) {
            result.error("DISPOSE_ERROR", e.message, null)
        }
    }
}
