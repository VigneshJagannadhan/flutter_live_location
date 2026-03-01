package com.live_location

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
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
class LiveLocationPlugin : FlutterPlugin, ActivityAware {
    companion object {
        private const val METHOD_CHANNEL = "com.flutter_live_location/methods"
        private const val FOREGROUND_EVENT_CHANNEL = "com.flutter_live_location/foreground_locations"
        private const val BACKGROUND_EVENT_CHANNEL = "com.flutter_live_location/background_locations"
    }

    private lateinit var context: Context
    private var activity: android.app.Activity? = null
    private lateinit var methodChannel: MethodChannel
    private lateinit var foregroundEventChannel: EventChannel
    private lateinit var backgroundEventChannel: EventChannel

    private var locationManager: LocationManager? = null
    private var foregroundEventSink: EventChannel.EventSink? = null
    private var backgroundEventSink: EventChannel.EventSink? = null



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
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
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
                "dispose" -> {
                    dispose(result)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("PLATFORM_ERROR", e.message, e.stackTraceToString())
        }
    }

    private fun initialize(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            val timeInterval = (call.argument<Number>("timeIntervalSeconds") ?: 2).toInt()
            val accuracy = call.argument<String>("accuracy") ?: "high"
            val enableBackground = call.argument<Boolean>("enableBackground") ?: false

            locationManager = LocationManager(
                context = context,
                timeIntervalSeconds = timeInterval,
                accuracy = accuracy,
                enableBackground = enableBackground,
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
