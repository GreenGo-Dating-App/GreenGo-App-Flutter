package com.greengochat.greengochatapp

import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.function.Consumer

class MainActivity : FlutterActivity() {
    /**
     * Screenshot / screen-recording protection (Dart side:
     * lib/core/security/screen_security_service.dart).
     *
     * BLOCKED: FLAG_SECURE app-wide, set before the first frame. Screenshots
     * and screen recordings show a black window, the recent-apps thumbnail is
     * blank, and the window is not shown on non-secure displays (casting).
     * Dart may call `disable`/`enable` (remote kill-switch, or a screen that
     * must allow screenshots).
     *
     * DETECTED (reported to Dart, never blocking):
     *  - Android 14+ (API 34) `ScreenCaptureCallback` -> `onScreenshot`. The
     *    system only reports screenshots of windows that are NOT secure, so
     *    in practice this fires only while FLAG_SECURE is off.
     *  - Android 15+ (API 35) screen-recording callback -> `onCaptureChanged`
     *    (true while this app is visible in a recording; a FLAG_SECURE window
     *    is not "visible", so it reports false while protection is on).
     */
    private var screenChannel: MethodChannel? = null
    private var screenCaptureCallback: Any? = null
    private var screenRecordingCallback: Any? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setSecure(true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // P3-1 regional age assurance: Google Play Age Signals.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AgeSignalsBridge.CHANNEL)
            .setMethodCallHandler(AgeSignalsBridge(this))

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> { setSecure(true); result.success(true) }
                "disable" -> { setSecure(false); result.success(true) }
                "isCaptured" -> result.success(isRecordingVisible)
                else -> result.notImplemented()
            }
        }
        screenChannel = channel
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        screenChannel?.setMethodCallHandler(null)
        screenChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun setSecure(secure: Boolean) {
        if (secure) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    private var isRecordingVisible = false

    override fun onStart() {
        super.onStart()
        if (Build.VERSION.SDK_INT >= 34) registerScreenshotCallback()
        if (Build.VERSION.SDK_INT >= 35) registerRecordingCallback()
    }

    override fun onStop() {
        if (Build.VERSION.SDK_INT >= 34) unregisterScreenshotCallback()
        if (Build.VERSION.SDK_INT >= 35) unregisterRecordingCallback()
        super.onStop()
    }

    // Needs <uses-permission android:name="android.permission.DETECT_SCREEN_CAPTURE"/>
    // (normal, install-time). Any failure only disables detection.
    @androidx.annotation.RequiresApi(34)
    private fun registerScreenshotCallback() {
        if (screenCaptureCallback != null) return
        try {
            val cb = Activity.ScreenCaptureCallback {
                screenChannel?.invokeMethod("onScreenshot", null)
            }
            registerScreenCaptureCallback(mainExecutor, cb)
            screenCaptureCallback = cb
        } catch (e: Exception) {
            screenCaptureCallback = null
        }
    }

    @androidx.annotation.RequiresApi(34)
    private fun unregisterScreenshotCallback() {
        val cb = screenCaptureCallback as? Activity.ScreenCaptureCallback ?: return
        try {
            unregisterScreenCaptureCallback(cb)
        } catch (_: Exception) {
        }
        screenCaptureCallback = null
    }

    // Needs <uses-permission android:name="android.permission.DETECT_SCREEN_RECORDING"/>.
    @androidx.annotation.RequiresApi(35)
    private fun registerRecordingCallback() {
        if (screenRecordingCallback != null) return
        try {
            val cb = Consumer<Int> { state -> onRecordingState(state) }
            val initial = windowManager.addScreenRecordingCallback(mainExecutor, cb)
            screenRecordingCallback = cb
            onRecordingState(initial)
        } catch (e: Exception) {
            screenRecordingCallback = null
        }
    }

    @androidx.annotation.RequiresApi(35)
    private fun unregisterRecordingCallback() {
        @Suppress("UNCHECKED_CAST")
        val cb = screenRecordingCallback as? Consumer<Int> ?: return
        try {
            windowManager.removeScreenRecordingCallback(cb)
        } catch (_: Exception) {
        }
        screenRecordingCallback = null
        onRecordingState(WindowManager.SCREEN_RECORDING_STATE_NOT_VISIBLE)
    }

    private fun onRecordingState(state: Int) {
        val visible = state == WindowManager.SCREEN_RECORDING_STATE_VISIBLE
        if (visible == isRecordingVisible) return
        isRecordingVisible = visible
        screenChannel?.invokeMethod("onCaptureChanged", visible)
    }

    companion object {
        const val SCREEN_CHANNEL = "greengo/screen_security"
    }
}
