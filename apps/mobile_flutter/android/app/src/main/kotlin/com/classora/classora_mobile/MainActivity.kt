package com.classora.classora_mobile

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PIP_CHANNEL = "com.classora.app/pip"
    private val SECURITY_CHANNEL = "com.classora.app/security"
    private var pipChannel: MethodChannel? = null
    private var securityChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Screen Security Channel (FLAG_SECURE anti-screenshot/recording for exams & live classes)
        securityChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        if (enabled) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPipSupported" -> {
                        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                                packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
                        result.success(supported)
                    }
                    "enterPip" -> {
                        val width = call.argument<Int>("width") ?: 16
                        val height = call.argument<Int>("height") ?: 9

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            try {
                                val paramsBuilder = PictureInPictureParams.Builder()
                                    .setAspectRatio(Rational(width, height))
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                    paramsBuilder.setAutoEnterEnabled(true)
                                }
                                val entered = enterPictureInPictureMode(paramsBuilder.build())
                                result.success(entered)
                            } catch (e: Exception) {
                                result.error("PIP_ERROR", e.localizedMessage, null)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "isPipActive" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            result.success(isInPictureInPictureMode)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Screen Share Foreground Service Channel (Android 14+ MediaProjection requirements)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.classora.app/screenshare").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForeground" -> {
                        try {
                            val intent = android.content.Intent(this@MainActivity, MediaProjectionService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SERVICE_START_FAILED", e.localizedMessage, null)
                        }
                    }
                    "stopForeground" -> {
                        try {
                            val intent = android.content.Intent(this@MainActivity, MediaProjectionService::class.java)
                            stopService(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SERVICE_STOP_FAILED", e.localizedMessage, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }


    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }
}
