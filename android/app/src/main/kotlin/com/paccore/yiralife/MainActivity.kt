package com.paccore.yiralife

import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val INTENT_CHANNEL = "com.paccore.yiralife/native_intent"

    // Tapping a push while the app is closed starts this activity with the
    // push's data as intent extras. Flutter reads an extra named "route" as
    // the first screen to open, and our pushes carry one (for example
    // "/appointmentDashboardScreen"). That skipped the splash screen and the
    // app's own push routing, and opened a doctor's screen for patients.
    // Always start at the splash screen; the app routes the tapped push itself.
    override fun getInitialRoute(): String = "/"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "clearLaunchIntent") {
                intent = Intent(Intent.ACTION_MAIN)
                result.success(true)
            } else if (call.method == "scanMedia") {
                val path = call.argument<String>("path")
                if (path != null) {
                    android.media.MediaScannerConnection.scanFile(this, arrayOf(path), null) { _, _ -> }
                    result.success(true)
                } else {
                    result.error("INVALID_PATH", "Path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
