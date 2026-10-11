package com.example.feen

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class CarTrackingPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL = "feen/car_tracking"
        private const val EVENT_CHANNEL = "feen/car_tracking/events"

        private var eventSink: EventChannel.EventSink? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val plugin = CarTrackingPlugin(context)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
                .setMethodCallHandler(plugin)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(plugin)
        }

        fun dispatchTrackingEvent(
            state: String,
            distanceMeters: Double?,
            walkMinutes: Int?,
            progress: Double,
            isArabic: Boolean,
            isArrived: Boolean
        ) {
            mainHandler.post {
                val map = hashMapOf<String, Any?>(
                    "state" to state,
                    "distanceMeters" to distanceMeters,
                    "walkMinutes" to walkMinutes,
                    "progress" to progress,
                    "isArabic" to isArabic,
                    "isArrived" to isArrived
                )
                eventSink?.success(map)
            }
        }

        fun dispatchFoundCarEvent() {
            mainHandler.post {
                val map = hashMapOf<String, Any?>(
                    "state" to "foundCar"
                )
                eventSink?.success(map)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val carLat = call.argument<Double>("carLat") ?: 0.0
                val carLng = call.argument<Double>("carLng") ?: 0.0
                val spotId = call.argument<String>("spotId") ?: ""
                val carSavedAt = (call.argument<Number>("carSavedAt"))?.toLong()
                    ?: System.currentTimeMillis()
                val isArabic = call.argument<Boolean>("isArabic") ?: false

                CarTrackingService.startService(
                    context = context,
                    carLat = carLat,
                    carLng = carLng,
                    spotId = spotId,
                    carSavedAt = carSavedAt,
                    isArabic = isArabic
                )
                result.success(true)
            }
            "stop" -> {
                CarTrackingService.stopService(context)
                result.success(null)
            }
            "isRunning" -> {
                result.success(CarTrackingService.isRunning)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
