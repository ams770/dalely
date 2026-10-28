package com.dalely.app

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
        private var initialAction: Map<String, Any?>? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val plugin = NotificationActionPlugin(context)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
                .setMethodCallHandler(plugin)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(plugin)
        }

        fun dispatchAction(action: String, timestamp: Long, data: String? = null) {
            val map = hashMapOf<String, Any?>(
                "action" to action,
                "data" to data,
                "timestamp" to timestamp
            )
            mainHandler.post {
                val sink = actionSink
                if (sink != null) {
                    try {
                        sink.success(map)
                    } catch (_: Exception) {}
                } else {
                    initialAction = map
                }
            }
        }
    }

    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(CarTrackingReceiver.PREFS_NAME, Context.MODE_PRIVATE)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInitialAction" -> {
                val initial = MainActivity.consumeInitialAction() ?: initialAction.also { initialAction = null }
                result.success(initial)
            }
            "getPendingAction" -> {
                val action = prefs.getString(CarTrackingReceiver.KEY_PENDING_ACTION, null)
                val time = prefs.getLong(CarTrackingReceiver.KEY_PENDING_TIME, 0L)
                val data = prefs.getString("pending_action_data", null)
                if (action != null) {
                    val map = hashMapOf<String, Any?>(
                        "action" to action,
                        "timestamp" to time
                    )
                    if (data != null) {
                        map["data"] = data
                    }
                    result.success(map)
                } else {
                    result.success(null)
                }
            }
            "clearPendingAction" -> {
                prefs.edit()
                    .remove(CarTrackingReceiver.KEY_PENDING_ACTION)
                    .remove(CarTrackingReceiver.KEY_PENDING_TIME)
                    .remove("pending_action_data")
                    .apply()
                result.success(true)
            }
            "getPendingSavedSpots" -> {
                val raw = prefs.getString("pending_saved_spots", null)
                if (raw != null && raw != "[]") {
                    prefs.edit().remove("pending_saved_spots").apply()
                    try {
                        val arr = org.json.JSONArray(raw)
                        val list = mutableListOf<String>()
                        for (i in 0 until arr.length()) {
                            list.add(arr.getJSONObject(i).toString())
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.success(emptyList<String>())
                    }
                } else {
                    result.success(emptyList<String>())
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        actionSink = events
        val buffered = initialAction
        if (buffered != null) {
            initialAction = null
            events?.success(buffered)
        }
    }

    override fun onCancel(arguments: Any?) {
        actionSink = null
    }
}
