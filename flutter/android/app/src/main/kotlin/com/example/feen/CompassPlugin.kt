package com.dalely.app

import android.app.Activity
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Surface
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class CompassPlugin(private val context: Context) :
    EventChannel.StreamHandler,
    SensorEventListener {

    companion object {
        private const val EVENT_CHANNEL = "feen/compass"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val plugin = CompassPlugin(context)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(plugin)
        }
    }

    private var sensorManager: SensorManager? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var rotationVectorSensor: Sensor? = null
    private var geomagneticVectorSensor: Sensor? = null
    private var accelerometer: Sensor? = null
    private var magneticField: Sensor? = null
    private var orientationSensor: Sensor? = null

    private var gravityValues: FloatArray? = null
    private var magneticValues: FloatArray? = null
    private var lastEmitTime = 0L
    private var lastRotationVectorTime = 0L
    private var lastAccelMagTime = 0L

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val sm = (context.getSystemService(Context.SENSOR_SERVICE)
            ?: context.applicationContext.getSystemService(Context.SENSOR_SERVICE)) as? SensorManager
        if (sm == null) return
        sensorManager = sm

        rotationVectorSensor = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        geomagneticVectorSensor = sm.getDefaultSensor(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)
        accelerometer = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        magneticField = sm.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
        @Suppress("DEPRECATION")
        orientationSensor = sm.getDefaultSensor(Sensor.TYPE_ORIENTATION)

        // Register sensors with UI delay (~60ms) to conserve battery
        rotationVectorSensor?.let { sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }
        if (rotationVectorSensor == null) {
            geomagneticVectorSensor?.let { sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }
        }

        // Register accelerometer and magnetometer as fallback
        accelerometer?.let { sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }
        magneticField?.let { sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }

        // Also register legacy orientation sensor as fallback
        orientationSensor?.let { sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }
    }

    override fun onCancel(arguments: Any?) {
        mainHandler.removeCallbacksAndMessages(null)
        sensorManager?.unregisterListener(this)
        sensorManager = null
        eventSink = null
        gravityValues = null
        magneticValues = null
        lastEmitTime = 0L
        lastRotationVectorTime = 0L
        lastAccelMagTime = 0L
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        val sink = eventSink ?: return
        val now = SystemClock.elapsedRealtime()

        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR,
            Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR -> {
                lastRotationVectorTime = now
                processRotationVector(event.values, sink, now)
            }

            Sensor.TYPE_ACCELEROMETER -> {
                gravityValues = event.values.clone()
                // If rotation vector is absent or hasn't produced data in 1.0 second, use accelerometer+magnetometer
                if (now - lastRotationVectorTime > 1000L) {
                    processAccelerometerMagnetometer(sink, now)
                }
            }

            Sensor.TYPE_MAGNETIC_FIELD -> {
                magneticValues = event.values.clone()
                if (now - lastRotationVectorTime > 1000L) {
                    processAccelerometerMagnetometer(sink, now)
                }
            }

            @Suppress("DEPRECATION")
            Sensor.TYPE_ORIENTATION -> {
                // If rotation vector and accelerometer/magnetometer haven't produced data in 1.5 seconds, use orientation sensor
                if (now - lastRotationVectorTime > 1500L && now - lastAccelMagTime > 1500L) {
                    processLegacyOrientation(event.values, sink, now)
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No-op
    }

    private fun processRotationVector(values: FloatArray, sink: EventChannel.EventSink, now: Long) {
        if (now - lastEmitTime < 30L) return

        val rotationMatrix = FloatArray(9)
        val vec = if (values.size > 4) {
            floatArrayOf(values[0], values[1], values[2], values[3])
        } else {
            values
        }

        try {
            SensorManager.getRotationMatrixFromVector(rotationMatrix, vec)
        } catch (_: Exception) {
            try {
                SensorManager.getRotationMatrixFromVector(rotationMatrix, values)
            } catch (_: Exception) {
                return
            }
        }

        val azimuth = computeAzimuthWithPitchCompensation(rotationMatrix)
        if (azimuth.isNaN() || azimuth.isInfinite()) return
        lastEmitTime = now
        emitHeading(azimuth, sink)
    }

    private fun processAccelerometerMagnetometer(sink: EventChannel.EventSink, now: Long) {
        val grav = gravityValues ?: return
        val mag = magneticValues ?: return
        if (now - lastEmitTime < 30L) return

        val r = FloatArray(9)
        val i = FloatArray(9)
        if (SensorManager.getRotationMatrix(r, i, grav, mag)) {
            val azimuth = computeAzimuthWithPitchCompensation(r)
            if (azimuth.isNaN() || azimuth.isInfinite()) return
            lastAccelMagTime = now
            lastEmitTime = now
            emitHeading(azimuth, sink)
        }
    }

    private fun processLegacyOrientation(values: FloatArray, sink: EventChannel.EventSink, now: Long) {
        if (now - lastEmitTime < 30L) return
        val rawAzimuth = values[0].toDouble()
        val displayRotation = getDisplayRotation()

        val adjusted = when (displayRotation) {
            Surface.ROTATION_90 -> rawAzimuth + 90.0
            Surface.ROTATION_180 -> rawAzimuth + 180.0
            Surface.ROTATION_270 -> rawAzimuth + 270.0
            else -> rawAzimuth
        }

        val azimuth = (adjusted % 360.0 + 360.0) % 360.0
        if (azimuth.isNaN() || azimuth.isInfinite()) return
        lastEmitTime = now
        emitHeading(azimuth, sink)
    }

    /**
     * Computes the device's compass azimuth [0..360) with display rotation alignment
     * and pitch/roll remapping for devices held upright in hand (pitch < -45°).
     */
    private fun computeAzimuthWithPitchCompensation(rotationMatrix: FloatArray): Double {
        val displayRotation = getDisplayRotation()
        var axisX: Int
        var axisY: Int

        when (displayRotation) {
            Surface.ROTATION_90 -> {
                axisX = SensorManager.AXIS_Y
                axisY = SensorManager.AXIS_MINUS_X
            }
            Surface.ROTATION_180 -> {
                axisX = SensorManager.AXIS_MINUS_X
                axisY = SensorManager.AXIS_MINUS_Y
            }
            Surface.ROTATION_270 -> {
                axisX = SensorManager.AXIS_MINUS_Y
                axisY = SensorManager.AXIS_X
            }
            else -> {
                axisX = SensorManager.AXIS_X
                axisY = SensorManager.AXIS_Y
            }
        }

        val adjustedMatrix = FloatArray(9)
        SensorManager.remapCoordinateSystem(rotationMatrix, axisX, axisY, adjustedMatrix)

        val orientation = FloatArray(3)
        SensorManager.getOrientation(adjustedMatrix, orientation)

        // When device is held upright in hand (pitch < -45°), remap coordinate system so
        // rotation about the vertical axis is correctly measured along the phone plane.
        if (orientation[1] < -Math.PI / 4.0) {
            when (displayRotation) {
                Surface.ROTATION_90 -> {
                    axisX = SensorManager.AXIS_Z
                    axisY = SensorManager.AXIS_MINUS_X
                }
                Surface.ROTATION_180 -> {
                    axisX = SensorManager.AXIS_MINUS_X
                    axisY = SensorManager.AXIS_MINUS_Z
                }
                Surface.ROTATION_270 -> {
                    axisX = SensorManager.AXIS_MINUS_Z
                    axisY = SensorManager.AXIS_X
                }
                else -> {
                    axisX = SensorManager.AXIS_X
                    axisY = SensorManager.AXIS_Z
                }
            }
            SensorManager.remapCoordinateSystem(rotationMatrix, axisX, axisY, adjustedMatrix)
            SensorManager.getOrientation(adjustedMatrix, orientation)
        } else if (orientation[1] > Math.PI / 4.0) {
            when (displayRotation) {
                Surface.ROTATION_90 -> {
                    axisX = SensorManager.AXIS_MINUS_Z
                    axisY = SensorManager.AXIS_MINUS_X
                }
                Surface.ROTATION_180 -> {
                    axisX = SensorManager.AXIS_MINUS_X
                    axisY = SensorManager.AXIS_Z
                }
                Surface.ROTATION_270 -> {
                    axisX = SensorManager.AXIS_Z
                    axisY = SensorManager.AXIS_X
                }
                else -> {
                    axisX = SensorManager.AXIS_X
                    axisY = SensorManager.AXIS_MINUS_Z
                }
            }
            SensorManager.remapCoordinateSystem(rotationMatrix, axisX, axisY, adjustedMatrix)
            SensorManager.getOrientation(adjustedMatrix, orientation)
        }

        return (Math.toDegrees(orientation[0].toDouble()) + 360.0) % 360.0
    }

    private fun getDisplayRotation(): Int {
        try {
            val act = context as? Activity
            if (act != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    try {
                        val rotation = act.display?.rotation
                        if (rotation != null) return rotation
                    } catch (_: Exception) {}
                }
                @Suppress("DEPRECATION")
                val rotation = act.windowManager?.defaultDisplay?.rotation
                if (rotation != null) return rotation
            }
        } catch (_: Exception) {}

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val rotation = context.display?.rotation
                if (rotation != null) return rotation
            } catch (_: Exception) {}
        }

        return try {
            @Suppress("DEPRECATION")
            (context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager)
                ?.defaultDisplay?.rotation ?: Surface.ROTATION_0
        } catch (_: Exception) {
            Surface.ROTATION_0
        }
    }

    private fun emitHeading(azimuth: Double, sink: EventChannel.EventSink) {
        if (azimuth.isNaN() || azimuth.isInfinite()) return
        mainHandler.post {
            try {
                if (eventSink != null) {
                    sink.success(azimuth)
                }
            } catch (_: Exception) {}
        }
    }
}
