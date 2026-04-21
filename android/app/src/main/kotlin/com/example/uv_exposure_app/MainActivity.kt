package com.example.uv_exposure_app

import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sunsense/multicast"
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquireMulticastLock" -> {
                        try {
                            if (multicastLock == null || !multicastLock!!.isHeld) {
                                val wifi = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
                                multicastLock = wifi.createMulticastLock("sunsense_multicast")
                                multicastLock!!.setReferenceCounted(true)
                                multicastLock!!.acquire()
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("MULTICAST_ERROR", e.message, null)
                        }
                    }
                    "releaseMulticastLock" -> {
                        try {
                            if (multicastLock != null && multicastLock!!.isHeld) {
                                multicastLock!!.release()
                            }
                            multicastLock = null
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("MULTICAST_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        if (multicastLock != null && multicastLock!!.isHeld) {
            multicastLock!!.release()
        }
        super.onDestroy()
    }
}
