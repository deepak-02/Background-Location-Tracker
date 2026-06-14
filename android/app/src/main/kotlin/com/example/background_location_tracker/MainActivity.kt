package com.example.background_location_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.background_location_tracker/battery"
    private val EVENT_CHANNEL = "com.example.background_location_tracker/battery_stream"

    private var batteryReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── MethodChannel for one-shot battery query (used at startup) ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBatteryInfo" -> {
                        val info = getBatteryInfo()
                        result.success(info)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── EventChannel for real-time battery level stream ──
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    batteryReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                            val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
                            val percent = if (scale > 0) (level * 100) / scale else -1
                            events?.success(percent)
                        }
                    }
                    registerReceiver(
                        batteryReceiver,
                        IntentFilter(Intent.ACTION_BATTERY_CHANGED)
                    )
                }

                override fun onCancel(arguments: Any?) {
                    batteryReceiver?.let { unregisterReceiver(it) }
                    batteryReceiver = null
                }
            })
    }

    private fun getBatteryInfo(): HashMap<String, Any> {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)

        val info = HashMap<String, Any>()
        info["level"] = level
        return info
    }
}
