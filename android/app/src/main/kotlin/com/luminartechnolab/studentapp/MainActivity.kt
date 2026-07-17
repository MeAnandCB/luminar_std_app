package com.luminartechnolab.studentapp

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val deviceTimeChannel = "luminar/device_time"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceTimeChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAutoTimeEnabled" -> {
                        // Settings.Global.AUTO_TIME reflects the device's
                        // "Set time automatically" toggle — 1 when on, 0 when off.
                        // No special permission required to read it.
                        val autoTime = Settings.Global.getInt(
                            contentResolver,
                            Settings.Global.AUTO_TIME,
                            0
                        )
                        result.success(autoTime == 1)
                    }
                    "openDateSettings" -> {
                        startActivity(Intent(Settings.ACTION_DATE_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
