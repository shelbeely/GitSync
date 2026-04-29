package com.shelbeely.gitcommand

import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.Bundle
import android.view.Window
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import android.window.SystemOnBackInvokedCallbacks
import android.content.Intent

class MainActivity: FlutterActivity() {
    companion object {
        var channel: MethodChannel? = null

        // Android 16 (BAKLAVA) introduced the new predictive-back observer
        // priority and the system "finish-and-remove-task" callback.
        private const val ANDROID_16 = 36
    }

    private var systemBackObserver: OnBackInvokedCallback? = null
    private var finishAndRemoveTaskCallback: OnBackInvokedCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)        

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "accessibility_service_helper")
        channel!!.setMethodCallHandler(AccessibilityServiceHelper(context))

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SyncProgressNotification.CHANNEL_NAME)
            .setMethodCallHandler(SyncProgressNotification.create(applicationContext))

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ActionsProgressNotification.CHANNEL_NAME)
            .setMethodCallHandler(ActionsProgressNotification.create(applicationContext))

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AgentProgressNotification.CHANNEL_NAME)
            .setMethodCallHandler(AgentProgressNotification.create(applicationContext))

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SyncDiagnostics.CHANNEL_NAME)
            .setMethodCallHandler(SyncDiagnostics(applicationContext))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);


        if (actionBar!=null) {
            this.actionBar!!.hide();
        }

        registerPredictiveBackCallbacks()
        handleIntent(intent)
    }

    override fun onDestroy() {
        unregisterPredictiveBackCallbacks()
        super.onDestroy()
    }

    /**
     * Registers Android 16 predictive-back callbacks:
     *  * `PRIORITY_SYSTEM_NAVIGATION_OBSERVER` lets us observe back
     *    navigation without preventing the system back-to-home animation.
     *  * `finishAndRemoveTaskCallback` plays the ahead-of-time animation when
     *    the user backs out of the root activity.
     *
     * Falls back silently on devices below API 36.
     */
    private fun registerPredictiveBackCallbacks() {
        if (Build.VERSION.SDK_INT < ANDROID_16) return
        try {
            val dispatcher = onBackInvokedDispatcher
            // The observer is intentionally a no-op beyond logging — registering
            // at PRIORITY_SYSTEM_NAVIGATION_OBSERVER lets us see back gestures
            // without preventing the system from playing its back-to-home
            // animation. Useful for diagnostics; do not consume the event.
            val observer = OnBackInvokedCallback {
                Log.d("MainActivity", "System back navigation observed")
            }
            dispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_SYSTEM_NAVIGATION_OBSERVER,
                observer,
            )
            systemBackObserver = observer

            val finishCallback = SystemOnBackInvokedCallbacks.finishAndRemoveTaskCallback(this)
            dispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT,
                finishCallback,
            )
            finishAndRemoveTaskCallback = finishCallback
        } catch (t: Throwable) {
            Log.w("MainActivity", "Failed to register Android 16 back callbacks", t)
        }
    }

    private fun unregisterPredictiveBackCallbacks() {
        if (Build.VERSION.SDK_INT < ANDROID_16) return
        try {
            val dispatcher = onBackInvokedDispatcher
            systemBackObserver?.let { dispatcher.unregisterOnBackInvokedCallback(it) }
            finishAndRemoveTaskCallback?.let { dispatcher.unregisterOnBackInvokedCallback(it) }
        } catch (t: Throwable) {
            Log.w("MainActivity", "Failed to unregister Android 16 back callbacks", t)
        } finally {
            systemBackObserver = null
            finishAndRemoveTaskCallback = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.action?.let { action ->
            val index = intent.getIntExtra("index", -1)
            channel?.invokeMethod("onIntentAction", mapOf(
                "action" to action,
                "index" to index
            ))
        }
    }
}
