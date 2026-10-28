package com.dalely.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

object CarTrackingNotificationBuilder {
    const val CHANNEL_ID = "car_tracking"
    const val NOTIFICATION_ID = 2001

    const val REQUEST_CODE_SHOW_ON_MAP = 2001
    const val REQUEST_CODE_FOUND_CAR = 2002

    const val ACTION_SHOW_ON_MAP = "com.dalely.app.ACTION_SHOW_ON_MAP"
    const val ACTION_FOUND_CAR = "com.dalely.app.ACTION_FOUND_CAR"

    const val URI_MAP_CAR = "feen://map?spot=car"
    const val URI_FOUND_CAR = "feen://found_car"

    private const val COLOR_LIGHT_BLUE = 0xFF3C79F3.toInt()
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
        carSavedAt: Long = System.currentTimeMillis(),
    ): Notification {
        val title: String
        val body: String
        val accentColor = if (state == "arrived") COLOR_GREEN else COLOR_LIGHT_BLUE
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
            }
            isArrived -> {
                title = context.getString(R.string.car_tracking_arrived_title)
                body = context.getString(R.string.car_tracking_arrived_body)
            }
            else -> {
                title = context.getString(R.string.car_tracking_walking_title, distanceFormatted)
                body = walkFormatted
            }
        }

        // Action 1: "Show on map" -> Explicit Activity intent to MainActivity with singleTask flags
        val mapIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(URI_MAP_CAR)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val mapPendingIntent = PendingIntent.getActivity(
            context,
            REQUEST_CODE_SHOW_ON_MAP,
            mapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action 2: "Found my car" / "Done" -> Explicit Broadcast to CarTrackingReceiver (no Activity launch)
        val foundIntent = Intent(context, CarTrackingReceiver::class.java).apply {
            action = ACTION_FOUND_CAR
        }
        val foundPendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_FOUND_CAR,
            foundIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val foundLabel = if (isArrived) {
            context.getString(R.string.car_tracking_action_done)
        } else {
            context.getString(R.string.car_tracking_action_found_car)
        }

        val appName = if (isArabic) "دليلى" else "Dalely"
        val parkedAgoText = formatParkedAgo(carSavedAt, isArabic)

        val displayDistance = if (isWaiting) {
            if (isArabic) "0 متر" else "0 m"
        } else {
            distanceFormatted
        }

        val displayDetail = if (isWaiting) {
            if (isArabic) "..." else "..."
        } else if (isArrived) {
            if (isArabic) "أنت على بعد أقل من 15 م" else "You are within 15 m"
        } else {
            walkFormatted
        }

        // Custom view: Collapsed
        val collapsedViews = RemoteViews(context.packageName, R.layout.notification_car_tracking_collapsed).apply {
            setTextViewText(R.id.tv_app_name, appName)
            setTextViewText(R.id.tv_parked_time, parkedAgoText)
            setTextViewText(R.id.tv_distance, displayDistance)
            setTextViewText(R.id.tv_detail, displayDetail)
            setTextViewText(R.id.btn_map_quick, context.getString(R.string.car_tracking_action_show_on_map))
            setOnClickPendingIntent(R.id.btn_map_quick, mapPendingIntent)
            setOnClickPendingIntent(R.id.notification_root, mapPendingIntent)
            if (isArrived) {
                setTextColor(R.id.tv_detail, COLOR_GREEN)
            } else {
                setTextColor(R.id.tv_detail, Color.parseColor("#E6FFFFFF"))
            }
        }

        // Custom view: Expanded
        val expandedViews = RemoteViews(context.packageName, R.layout.notification_car_tracking_expanded).apply {
            setTextViewText(R.id.tv_app_name, appName)
            setTextViewText(R.id.tv_parked_time, parkedAgoText)
            setTextViewText(R.id.tv_distance, displayDistance)
            setTextViewText(R.id.tv_detail, displayDetail)
            setTextViewText(R.id.tv_btn_map_label, context.getString(R.string.car_tracking_action_show_on_map))
            setTextViewText(R.id.tv_btn_found_label, foundLabel)
            setOnClickPendingIntent(R.id.btn_show_on_map, mapPendingIntent)
            setOnClickPendingIntent(R.id.btn_found_car, foundPendingIntent)
            setOnClickPendingIntent(R.id.notification_root, mapPendingIntent)
            if (isArrived) {
                setTextColor(R.id.tv_detail, COLOR_GREEN)
            } else {
                setTextColor(R.id.tv_detail, Color.parseColor("#E6FFFFFF"))
            }
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_feen)
            .setContentTitle(title)
            .setContentText(body)
            .setSubText(appName)
            .setColor(accentColor)
            .setColorized(false)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(mapPendingIntent)
            .setCustomContentView(collapsedViews)
            .setCustomBigContentView(expandedViews)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
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

    private fun formatParkedAgo(savedAtMillis: Long, isArabic: Boolean): String {
        val hours = ((System.currentTimeMillis() - savedAtMillis) / 3_600_000L).toInt()
        return if (hours <= 0) {
            if (isArabic) "رُكنت حديثًا" else "Parked recently"
        } else {
            if (isArabic) "رُكنت منذ $hours س" else "Parked $hours h ago"
        }
    }
}
