package com.dalely.app

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CarTrackingReceiver : BroadcastReceiver() {
    companion object {
        const val PREFS_NAME = "feen_pending_actions"
        const val KEY_PENDING_ACTION = "pending_action"
        const val KEY_PENDING_TIME = "pending_action_time"
        const val ACTION_FOUND_CAR = "com.dalely.app.ACTION_FOUND_CAR"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_FOUND_CAR ||
            intent.action == CarTrackingNotificationBuilder.ACTION_FOUND_CAR) {
            // 1. Immediately stop foreground service and cancel notification
            CarTrackingService.stopService(context)
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.cancel(CarTrackingNotificationBuilder.NOTIFICATION_ID)

            val now = System.currentTimeMillis()

            // 2. Persist pending action to SharedPreferences so Dart can process it on start / resume
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_PENDING_ACTION, "FOUND_CAR")
                .putLong(KEY_PENDING_TIME, now)
                .apply()

            // 3. Dispatch directly to live Dart engine if running
            NotificationActionPlugin.dispatchAction("FOUND_CAR", now, null)
        }
    }
}
