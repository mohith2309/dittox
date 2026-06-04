package com.login.dittox

import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screen capture on sensitive flows.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dittox/security"
        ).setMethodCallHandler { call, result ->
            if (call.method == "isDeviceCompromised") {
                result.success(isDeviceCompromised())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isDeviceCompromised(): Boolean {
        if (Build.TAGS?.contains("test-keys") == true) return true
        if (Debug.isDebuggerConnected()) return true

        val suPaths = arrayOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/system/sd/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/data/local/su"
        )
        return suPaths.any { File(it).exists() }
    }
}
