package com.paccore.yiralife

import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val INTENT_CHANNEL = "com.paccore.yiralife/native_intent"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "clearLaunchIntent") {
                intent = Intent(Intent.ACTION_MAIN)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
