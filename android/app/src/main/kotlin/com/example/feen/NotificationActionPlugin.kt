package com.example.feen

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NotificationActionPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "feen/notification_actions"
        const val EVENT_CHANNEL = "feen/notification_actions/events"

        private var actionSink: EventChannel.EventSink? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val plugin = NotificationActionPlugin(context)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
                .setMethodCallHandler(plugin)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(plugin)
        }

        fun dispatchAction(action: String, timestamp: Long, data: String? = null) {
            mainHandler.post {
                val map = hashMapOf<String, Any?>(
                    "action" to action,
                    "data" to data,
                    "timestamp" to timestamp
                )
                try {
                    actionSink?.success(map)
                } catch (_: Exception) {}
            }
        }
    }

    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(CarTrackingReceiver.PREFS_NAME, Context.MODE_PRIVATE)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInitialAction" -> {
                val initial = MainActivity.consumeInitialAction()
                result.success(initial)
            }
            "getPendingAction" -> {
                val action = prefs.getString(CarTrackingReceiver.KEY_PENDING_ACTION, null)
                val time = prefs.getLong(CarTrackingReceiver.KEY_PENDING_TIME, 0L)
                if (action != null) {
                    val map = hashMapOf<String, Any?>(
                        "action" to action,
                        "timestamp" to time
                    )
                    result.success(map)
                } else {
                    result.success(null)
                }
            }
            "clearPendingAction" -> {
                prefs.edit()
                    .remove(CarTrackingReceiver.KEY_PENDING_ACTION)
                    .remove(CarTrackingReceiver.KEY_PENDING_TIME)
                    .apply()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        actionSink = events
    }

    override fun onCancel(arguments: Any?) {
        actionSink = null
    }
}
