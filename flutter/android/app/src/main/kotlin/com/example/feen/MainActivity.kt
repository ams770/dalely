package com.dalely.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    companion object {
        private var initialAction: String? = null
        private var initialData: String? = null
        private var initialTimestamp: Long = 0L

        fun setInitialAction(action: String?, data: String?, timestamp: Long) {
            initialAction = action
            initialData = data
            initialTimestamp = timestamp
        }

        fun consumeInitialAction(): Map<String, Any?>? {
            val action = initialAction ?: return null
            val map = mapOf(
                "action" to action,
                "data" to initialData,
                "timestamp" to initialTimestamp
            )
            initialAction = null
            initialData = null
            initialTimestamp = 0L
            return map
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CarTrackingPlugin.registerWith(flutterEngine, this)
        NotificationActionPlugin.registerWith(flutterEngine, this)
        CompassPlugin.registerWith(flutterEngine, this)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        handleIntent(intent, isColdStart = true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent, isColdStart = false)
    }

    private fun handleIntent(intent: Intent?, isColdStart: Boolean) {
        if (intent == null) return
        val uriStr = intent.data?.toString()
        val action = intent.action

        if (action == Intent.ACTION_SEND) {
            val shareIntent = Intent(intent).apply {
                setClass(this@MainActivity, ShareSpotActivity::class.java)
                addFlags(Intent.FLAG_ACTIVITY_FORWARD_RESULT)
            }
            startActivity(shareIntent)
            finish()
            return
        }

        val dataPayload = uriStr

        val actionName = when {
            uriStr == CarTrackingNotificationBuilder.URI_MAP_CAR ||
                    uriStr?.startsWith("feen://map") == true ||
                    uriStr?.startsWith("dalely://map") == true ||
                    action == CarTrackingNotificationBuilder.ACTION_SHOW_ON_MAP -> "SHOW_MAP"
            uriStr == CarTrackingNotificationBuilder.URI_FOUND_CAR ||
                    uriStr == "dalely://found_car" ||
                    action == CarTrackingNotificationBuilder.ACTION_FOUND_CAR -> "FOUND_CAR"
            uriStr == "feen://park" || uriStr == "dalely://park" -> "PARK"
            uriStr == "feen://car" || uriStr == "dalely://car" -> "CAR"
            uriStr?.startsWith("geo:") == true ||
                    uriStr?.contains("maps.google.") == true ||
                    uriStr?.contains("/maps") == true ||
                    uriStr?.contains("maps.app.goo.gl") == true ||
                    uriStr?.contains("maps.apple.com") == true ||
                    uriStr?.startsWith("feen://save") == true ||
                    uriStr?.startsWith("dalely://save") == true ||
                    uriStr?.startsWith("feen://add") == true ||
                    uriStr?.startsWith("dalely://add") == true -> "OPEN_LOCATION"
            else -> null
        }

        if (actionName != null) {
            val now = System.currentTimeMillis()
            if (isColdStart) {
                setInitialAction(actionName, dataPayload, now)
            } else {
                NotificationActionPlugin.dispatchAction(actionName, now, dataPayload)
            }
            val prefs = getSharedPreferences(CarTrackingReceiver.PREFS_NAME, android.content.Context.MODE_PRIVATE)
            prefs.edit()
                .putString(CarTrackingReceiver.KEY_PENDING_ACTION, actionName)
                .putLong(CarTrackingReceiver.KEY_PENDING_TIME, now)
                .putString("pending_action_data", dataPayload)
                .apply()
            // Clear consumed action and data so recreation or rotation does not replay it
            intent.data = null
            intent.action = null
            intent.removeExtra(Intent.EXTRA_TEXT)
            intent.removeExtra(Intent.EXTRA_SUBJECT)
            intent.clipData = null
        }
    }
}
