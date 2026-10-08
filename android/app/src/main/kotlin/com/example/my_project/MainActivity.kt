package com.mycompany.folkautodialer

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mycompany.folkautodialer/call_control"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "endCall" -> {
                    val success = disconnectCall()
                    result.success(success)
                }
                "requestCallPermissions" -> {
                    requestCallPermissions()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestCallPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ANSWER_PHONE_CALLS) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.ANSWER_PHONE_CALLS), 101)
            }
        }
    }

    private fun disconnectCall(): Boolean {
        android.util.Log.d("MainActivity", "disconnectCall requested")
        var callEnded = false

        // Method 1: TelecomManager.endCall() for Android 9+ (API 28+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                if (telecomManager != null) {
                    val ended = telecomManager.endCall()
                    android.util.Log.d("MainActivity", "TelecomManager.endCall() returned $ended")
                    if (ended) {
                        callEnded = true
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "TelecomManager.endCall() failed: ${e.message}", e)
            }
        }

        // Method 2: Reflection on TelephonyManager (Fallback)
        if (!callEnded) {
            try {
                val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                if (telephonyManager != null) {
                    val m = telephonyManager.javaClass.getDeclaredMethod("getITelephony")
                    m.isAccessible = true
                    val telephony = m.invoke(telephonyManager)
                    val endCallMethod = telephony.javaClass.getDeclaredMethod("endCall")
                    endCallMethod.invoke(telephony)
                    android.util.Log.d("MainActivity", "ITelephony.endCall() invoked successfully")
                    callEnded = true
                }
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "ITelephony.endCall() failed: ${e.message}", e)
            }
        }

        return callEnded
    }
}
