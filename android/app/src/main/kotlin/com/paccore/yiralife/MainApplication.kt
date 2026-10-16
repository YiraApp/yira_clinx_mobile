package com.paccore.yiralife

import android.app.Application
import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor

class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // flutter_overlay_window only creates the floating popup's engine when
        // the app's screen opens. A medicine reminder push can arrive while the
        // app is closed, so when the patient chose the floating popup, make
        // sure that engine exists whenever the app process starts.
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (prefs.getString("flutter.med_alert_style_v1", null) == "floatingPopup") {
            try {
                ensureOverlayEngine(this)
            } catch (e: Exception) {
                android.util.Log.w("MainApplication", "Could not prepare the reminder popup", e)
            }
        }
    }

    companion object {
        /** Same key flutter_overlay_window uses for its cached engine. */
        private const val OVERLAY_ENGINE_TAG = "myCachedEngine"

        fun ensureOverlayEngine(context: Context) {
            if (FlutterEngineCache.getInstance().get(OVERLAY_ENGINE_TAG) != null) return
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context)
            loader.ensureInitializationComplete(context, null)
            val entrypoint = DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "overlayMain")
            val engine = FlutterEngineGroup(context).createAndRunEngine(context, entrypoint)
            FlutterEngineCache.getInstance().put(OVERLAY_ENGINE_TAG, engine)
        }
    }
}
