package com.example.feen

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat

object CarTrackingNotificationBuilder {
    const val CHANNEL_ID = "car_tracking"
    const val NOTIFICATION_ID = 2001

    private const val COLOR_INDIGO = 0xFF4F46E5.toInt()
    private const val COLOR_GREEN = 0xFF0E9F75.toInt()

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = context.getString(R.string.car_tracking_channel_name)
            val description = context.getString(R.string.car_tracking_channel_description)
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                this.description = description
                enableLights(false)
                enableVibration(false)
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    fun buildNotification(
        context: Context,
        state: String, // "waitingForGps", "walking", "arrived"
        distanceMeters: Double?,
        walkMinutes: Int?,
        progress: Double,
        isArabic: Boolean,
    ): Notification {
        val title: String
        val body: String
        val collapsedSummary: String
        val accentColor = if (state == "arrived") COLOR_GREEN else COLOR_INDIGO
        val isArrived = state == "arrived"
        val isWaiting = state == "waitingForGps"

        val distanceFormatted = if (distanceMeters != null) {
            formatDistance(distanceMeters, isArabic)
        } else {
            ""
        }
        val walkFormatted = if (walkMinutes != null) {
            formatWalkTime(walkMinutes, isArabic)
        } else {
            ""
        }

        when {
            isWaiting -> {
                title = context.getString(R.string.car_tracking_looking_for_location)
                body = context.getString(R.string.car_tracking_waiting_for_gps)
                collapsedSummary = title
            }
            isArrived -> {
                title = context.getString(R.string.car_tracking_arrived_title)
                body = context.getString(R.string.car_tracking_arrived_body)
                collapsedSummary = title
            }
            else -> {
                title = context.getString(R.string.car_tracking_walking_title, distanceFormatted)
                body = walkFormatted
                collapsedSummary = "$title - $body"
            }
        }

        // Action 1: "Show on map" -> opens app via deep link feen://map?spot=car
        val mapIntent = Intent(Intent.ACTION_VIEW, Uri.parse("feen://map?spot=car")).apply {
            setPackage(context.packageName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mapPendingIntent = PendingIntent.getActivity(
            context,
            101,
            mapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action 2: "Found my car" / "Done" -> triggers broadcast receiver
        val actionFoundIntent = Intent(context, CarTrackingReceiver::class.java).apply {
            action = CarTrackingReceiver.ACTION_FOUND_CAR
        }
        val foundPendingIntent = PendingIntent.getBroadcast(
            context,
            102,
            actionFoundIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val foundLabel = if (isArrived) {
            context.getString(R.string.car_tracking_action_done)
        } else {
            context.getString(R.string.car_tracking_action_found_car)
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_feen)
            .setContentTitle(title)
            .setContentText(body)
            .setSubText(context.getString(R.string.app_name))
            .setColor(accentColor)
            .setColorized(false)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(mapPendingIntent)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(body)
                    .setSummaryText(collapsedSummary)
            )
            .addAction(
                0,
                context.getString(R.string.car_tracking_action_show_on_map),
                mapPendingIntent
            )
            .addAction(
                0,
                foundLabel,
                foundPendingIntent
            )

        return builder.build()
    }

    private fun formatDistance(meters: Double, isArabic: Boolean): String {
        val clamped = if (meters < 0) 0.0 else meters
        return if (clamped < 100.0) {
            val rounded = (Math.round(clamped / 5.0) * 5).toInt()
            val unit = if (isArabic) "م" else "m"
            "$rounded $unit"
        } else if (clamped < 1000.0) {
            val rounded = (Math.round(clamped / 10.0) * 10).toInt()
            if (rounded >= 1000) {
                val km = String.format(java.util.Locale.US, "%.1f", rounded / 1000.0)
                val unit = if (isArabic) "كم" else "km"
                "$km $unit"
            } else {
                val unit = if (isArabic) "م" else "m"
                "$rounded $unit"
            }
        } else {
            val km = String.format(java.util.Locale.US, "%.1f", clamped / 1000.0)
            val unit = if (isArabic) "كم" else "km"
            "$km $unit"
        }
    }

    private fun formatWalkTime(minutes: Int, isArabic: Boolean): String {
        if (minutes <= 0) {
            return if (isArabic) "أقل من دقيقة" else "Less than a minute"
        }
        return if (isArabic) {
            when (minutes) {
                1 -> "حوالي دقيقة سيرًا"
                2 -> "حوالي دقيقتين سيرًا"
                in 3..10 -> "حوالي $minutes دقائق سيرًا"
                else -> "حوالي $minutes دقيقة سيرًا"
            }
        } else {
            if (minutes == 1) "About 1 min walk" else "About $minutes min walk"
        }
    }
}
