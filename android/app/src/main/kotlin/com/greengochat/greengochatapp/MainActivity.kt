package com.greengochat.greengochatapp

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // P3-1 regional age assurance: Google Play Age Signals.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AgeSignalsBridge.CHANNEL)
            .setMethodCallHandler(AgeSignalsBridge(this))
    }
}
