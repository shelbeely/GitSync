package com.viscouspot.gitsync

import android.annotation.SuppressLint
import android.app.ActivityManager
import android.app.job.JobScheduler
import android.content.Context
import android.os.Build
import io.flutter.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes Android 16 diagnostics (`JobScheduler.getPendingJobReasons` and
 * `ApplicationStartInfo.getStartComponent`) to Flutter for inclusion in the
 * bug-report payload that `Logger.generateDeviceInfoEntries` builds.
 */
class SyncDiagnostics(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.viscouspot.gitsync/sync_diagnostics"
        private const val ANDROID_16 = 36
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getPendingJobReasons" -> {
                    val jobId = call.argument<Int>("jobId") ?: -1
                    result.success(getPendingJobReasons(jobId))
                }
                "getRecentStartComponents" -> {
                    val limit = call.argument<Int>("limit") ?: 5
                    result.success(getRecentStartComponents(limit))
                }
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            Log.w("SyncDiagnostics", "Method call failed: ${call.method}", t)
            result.error("sync_diagnostics_failed", t.message, null)
        }
    }

    @SuppressLint("NewApi")
    private fun getPendingJobReasons(jobId: Int): List<String> {
        if (Build.VERSION.SDK_INT < ANDROID_16 || jobId < 0) return emptyList()
        return try {
            val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as? JobScheduler
                ?: return emptyList()
            val reasons = scheduler.getPendingJobReasons(jobId)
            reasons.map { it.toString() }
        } catch (t: Throwable) {
            Log.w("SyncDiagnostics", "getPendingJobReasons failed", t)
            emptyList()
        }
    }

    @SuppressLint("NewApi")
    private fun getRecentStartComponents(limit: Int): List<String> {
        if (Build.VERSION.SDK_INT < ANDROID_16) return emptyList()
        return try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                ?: return emptyList()
            val infos = am.getHistoricalProcessStartReasons(limit)
            infos.map { info ->
                val component = info.startComponent?.toString() ?: "<unknown>"
                "reason=${info.reason} type=${info.startType} component=$component"
            }
        } catch (t: Throwable) {
            Log.w("SyncDiagnostics", "getRecentStartComponents failed", t)
            emptyList()
        }
    }
}
