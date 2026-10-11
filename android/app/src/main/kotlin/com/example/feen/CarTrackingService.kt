package com.dalely.app

import android.annotation.SuppressLint
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlin.math.ceil

class CarTrackingService : Service() {

    companion object {
        const val ACTION_START = "com.dalely.app.START_TRACKING"
        const val ACTION_STOP = "com.dalely.app.STOP_TRACKING"

        const val EXTRA_CAR_LAT = "extra_car_lat"
        const val EXTRA_CAR_LNG = "extra_car_lng"
        const val EXTRA_SPOT_ID = "extra_spot_id"
        const val EXTRA_CAR_SAVED_AT = "extra_car_saved_at"
        const val EXTRA_IS_ARABIC = "extra_is_arabic"

        const val EXTRA_USER_LAT = "extra_user_lat"
        const val EXTRA_USER_LNG = "extra_user_lng"

        private const val ARRIVAL_DISTANCE_METERS = 15.0
        private const val ARRIVAL_MAX_ACCURACY_METERS = 25.0
        private const val DEPARTURE_DISTANCE_METERS = 30.0
        private const val ARRIVAL_AUTO_STOP_MS = 120_000L // 2 minutes

        private const val MIN_UPDATE_INTERVAL_MS = 5_000L
        private const val MAX_UPDATE_INTERVAL_MS = 15_000L

        @Volatile
        var isRunning = false
            private set

        fun startService(
            context: Context,
            carLat: Double,
            carLng: Double,
            spotId: String,
            carSavedAt: Long,
            isArabic: Boolean,
            userLat: Double? = null,
            userLng: Double? = null
        ) {
            val intent = Intent(context, CarTrackingService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_CAR_LAT, carLat)
                putExtra(EXTRA_CAR_LNG, carLng)
                putExtra(EXTRA_SPOT_ID, spotId)
                putExtra(EXTRA_CAR_SAVED_AT, carSavedAt)
                putExtra(EXTRA_IS_ARABIC, isArabic)
                if (userLat != null && userLng != null) {
                    putExtra(EXTRA_USER_LAT, userLat)
                    putExtra(EXTRA_USER_LNG, userLng)
                }
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stopService(context: Context) {
            val intent = Intent(context, CarTrackingService::class.java).apply {
                action = ACTION_STOP
            }
            context.stopService(intent)
        }
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var notificationManager: NotificationManager
    private val mainHandler = Handler(Looper.getMainLooper())

    private var carLat = 0.0
    private var carLng = 0.0
    private var spotId = ""
    private var isArabic = false
    private var carSavedAt = System.currentTimeMillis()

    private var startDistanceMeters: Double? = null
    private var isArrived = false
    private var arrivalRunnable: Runnable? = null

    private var lastUpdateTimeMs = 0L
    private var lastDisplayedDistanceStr: String? = null
    private var lastDisplayedWalkMinutes: Int? = null
    private var lastState: String = "waitingForGps"

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            val location = result.lastLocation ?: return
            handleLocationFix(location)
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        CarTrackingNotificationBuilder.createNotificationChannel(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        carLat = intent.getDoubleExtra(EXTRA_CAR_LAT, 0.0)
        carLng = intent.getDoubleExtra(EXTRA_CAR_LNG, 0.0)
        spotId = intent.getStringExtra(EXTRA_SPOT_ID) ?: ""
        isArabic = intent.getBooleanExtra(EXTRA_IS_ARABIC, false)
        carSavedAt = intent.getLongExtra(EXTRA_CAR_SAVED_AT, System.currentTimeMillis())

        val notification = CarTrackingNotificationBuilder.buildNotification(
            context = this,
            state = "waitingForGps",
            distanceMeters = null,
            walkMinutes = null,
            progress = 0.0,
            isArabic = isArabic,
            carSavedAt = carSavedAt
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                CarTrackingNotificationBuilder.NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(CarTrackingNotificationBuilder.NOTIFICATION_ID, notification)
        }

        // If initial user location was passed, immediately calculate distance and update notification
        if (intent.hasExtra(EXTRA_USER_LAT) && intent.hasExtra(EXTRA_USER_LNG)) {
            val uLat = intent.getDoubleExtra(EXTRA_USER_LAT, 0.0)
            val uLng = intent.getDoubleExtra(EXTRA_USER_LNG, 0.0)
            val seedLocation = Location("seed").apply {
                latitude = uLat
                longitude = uLng
                accuracy = 10f
                time = System.currentTimeMillis()
            }
            handleLocationFix(seedLocation)
        } else {
            CarTrackingPlugin.dispatchTrackingEvent(
                state = "waitingForGps",
                distanceMeters = null,
                walkMinutes = null,
                progress = 0.0,
                isArabic = isArabic,
                isArrived = false
            )
        }

        startLocationUpdates()

        return START_NOT_STICKY
    }

    @SuppressLint("MissingPermission")
    private fun startLocationUpdates() {
        try {
            // Immediately request last location for instant update
            fusedLocationClient.lastLocation.addOnSuccessListener { lastLoc ->
                if (lastLoc != null) {
                    handleLocationFix(lastLoc)
                }
            }

            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            val isPowerSave = powerManager?.isPowerSaveMode ?: false
            val interval = if (isPowerSave) 10_000L else 4_000L

            val locationRequest = LocationRequest.Builder(
                Priority.PRIORITY_HIGH_ACCURACY,
                interval
            ).apply {
                setMinUpdateDistanceMeters(0f)
                setMinUpdateIntervalMillis(2_000L)
            }.build()

            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
        } catch (e: SecurityException) {
            stopSelf()
        }
    }

    private fun handleLocationFix(location: Location) {
        val results = FloatArray(1)
        Location.distanceBetween(
            location.latitude,
            location.longitude,
            carLat,
            carLng,
            results
        )
        val distance = results[0].toDouble()
        val accuracy = location.accuracy.toDouble()

        // Capture initial startDistance
        if (startDistanceMeters == null) {
            if (accuracy <= ARRIVAL_MAX_ACCURACY_METERS || startDistanceMeters == null) {
                startDistanceMeters = distance
            }
        } else {
            val currentStart = startDistanceMeters ?: distance
            if (distance > 1.5 * currentStart) {
                startDistanceMeters = distance
            }
        }

        val startDist = startDistanceMeters ?: distance
        val progress = if (startDist > 0) {
            (1.0 - (distance / startDist)).coerceIn(0.0, 1.0)
        } else {
            1.0
        }

        // Arrival hysteresis
        val wasArrived = isArrived
        if (isArrived) {
            if (distance > DEPARTURE_DISTANCE_METERS) {
                isArrived = false
                cancelArrivalTimeout()
            }
        } else {
            if (distance <= ARRIVAL_DISTANCE_METERS && accuracy <= ARRIVAL_MAX_ACCURACY_METERS) {
                isArrived = true
                startArrivalTimeout()
            }
        }

        val state = if (isArrived) "arrived" else "walking"

        // Walk time calculation: distance / 1.4 m/s
        val walkSeconds = distance / 1.4
        val walkMinutes = if (walkSeconds < 60.0) 0 else ceil(walkSeconds / 60.0).toInt()

        val distanceFormatted = if (distance < 100.0) {
            "${(Math.round(distance / 5.0) * 5).toInt()} m"
        } else if (distance < 1000.0) {
            "${(Math.round(distance / 10.0) * 10).toInt()} m"
        } else {
            String.format(java.util.Locale.US, "%.1f km", distance / 1000.0)
        }

        val now = System.currentTimeMillis()
        val timeSinceLastUpdate = now - lastUpdateTimeMs
        val valueChanged = distanceFormatted != lastDisplayedDistanceStr ||
                walkMinutes != lastDisplayedWalkMinutes ||
                state != lastState

        val shouldUpdateNotification = (timeSinceLastUpdate >= MIN_UPDATE_INTERVAL_MS && valueChanged) ||
                (timeSinceLastUpdate >= MAX_UPDATE_INTERVAL_MS)

        if (shouldUpdateNotification || lastUpdateTimeMs == 0L) {
            lastUpdateTimeMs = now
            lastDisplayedDistanceStr = distanceFormatted
            lastDisplayedWalkMinutes = walkMinutes
            lastState = state

            val notification = CarTrackingNotificationBuilder.buildNotification(
                context = this,
                state = state,
                distanceMeters = distance,
                walkMinutes = walkMinutes,
                progress = if (isArrived) 1.0 else progress,
                isArabic = isArabic,
                carSavedAt = carSavedAt
            )
            notificationManager.notify(
                CarTrackingNotificationBuilder.NOTIFICATION_ID,
                notification
            )
        }

        // Always push live event to Flutter for smooth UI updates
        CarTrackingPlugin.dispatchTrackingEvent(
            state = state,
            distanceMeters = distance,
            walkMinutes = walkMinutes,
            progress = if (isArrived) 1.0 else progress,
            isArabic = isArabic,
            isArrived = isArrived
        )
    }

    private fun startArrivalTimeout() {
        if (arrivalRunnable == null) {
            arrivalRunnable = Runnable {
                stopSelf()
            }
            mainHandler.postDelayed(arrivalRunnable!!, ARRIVAL_AUTO_STOP_MS)
        }
    }

    private fun cancelArrivalTimeout() {
        arrivalRunnable?.let { mainHandler.removeCallbacks(it) }
        arrivalRunnable = null
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        cancelArrivalTimeout()
        fusedLocationClient.removeLocationUpdates(locationCallback)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        notificationManager.cancel(CarTrackingNotificationBuilder.NOTIFICATION_ID)
        CarTrackingPlugin.dispatchTrackingEvent(
            state = "stopped",
            distanceMeters = null,
            walkMinutes = null,
            progress = 0.0,
            isArabic = isArabic,
            isArrived = false
        )
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
