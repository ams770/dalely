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
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (resources.configuration.smallestScreenWidthDp < 600) {
            requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } else {
            requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }
        handleIntent(intent, isColdStart = true)
    }

    override fun onConfigurationChanged(newConfig: android.content.res.Configuration) {
        super.onConfigurationChanged(newConfig)
        if (newConfig.smallestScreenWidthDp < 600) {
            requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } else {
            requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }
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

        val actionName = when {
            uriStr == CarTrackingNotificationBuilder.URI_MAP_CAR ||
                    uriStr?.startsWith("feen://map") == true ||
                    action == CarTrackingNotificationBuilder.ACTION_SHOW_ON_MAP -> "SHOW_MAP"
            uriStr == CarTrackingNotificationBuilder.URI_FOUND_CAR ||
                    action == CarTrackingNotificationBuilder.ACTION_FOUND_CAR -> "FOUND_CAR"
            uriStr == "feen://park" -> "PARK"
            uriStr == "feen://car" -> "CAR"
            else -> null
        }

        if (actionName != null) {
            val now = System.currentTimeMillis()
            if (isColdStart) {
                setInitialAction(actionName, uriStr, now)
            } else {
                NotificationActionPlugin.dispatchAction(actionName, now, uriStr)
            }
            // Clear consumed action and data so recreation or rotation does not replay it
            intent.data = null
            intent.action = null
        }
    }
}
