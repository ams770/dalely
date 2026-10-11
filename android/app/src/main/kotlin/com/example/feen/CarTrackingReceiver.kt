package com.example.feen

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CarTrackingReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_FOUND_CAR = "com.example.feen.ACTION_FOUND_CAR"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_FOUND_CAR) {
            CarTrackingService.stopService(context)
            CarTrackingPlugin.dispatchFoundCarEvent()
        }
    }
}
