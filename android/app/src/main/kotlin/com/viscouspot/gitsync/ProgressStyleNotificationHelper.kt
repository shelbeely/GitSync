package com.viscouspot.gitsync

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.Icon
import android.os.Build
import io.flutter.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Segment configuration for [ProgressStyleNotificationHelper].
 *
 * @param weight   Relative weight (progress units) of this segment.
 * @param colorHex ARGB or RGB hex color string, e.g. `"#1976D2"`.
 */
data class NotifSegment(val weight: Int, val colorHex: String)

/**
 * Generalised bridge between Flutter and the Android 16 (API 36)
 * `Notification.ProgressStyle` API.
 *
 * Each instance represents one notification slot and is configured through its
 * constructor — channel ID / name, notification ID, progress bar segments,
 * and a map of stage-name → progress position.  On devices below API 36 all
 * methods are silent no-ops.
 *
 * This class implements [MethodChannel.MethodCallHandler] so it can be
 * registered directly with a [MethodChannel] in `MainActivity`.  It handles
 * the following methods:
 *
 *  - `isSupported` → Boolean
 *  - `showProgress` (args: `stage`, `title`, `text`)
 *  - `completeProgress` (args: `success`, `title`, `text`, `autoCancelMs`)
 *  - `cancelProgress`
 */
class ProgressStyleNotificationHelper(
    private val context: Context,
    private val channelId: String,
    private val channelUserName: String,
    private val notificationId: Int,
    private val segments: List<NotifSegment>,
    /** Maps stage-name strings to progress positions within the bar. */
    private val stageProgressMap: Map<String, Int>,
) : MethodChannel.MethodCallHandler {

    companion object {
        // Android 16 was assigned API level 36 (BAKLAVA).
        private const val ANDROID_16 = 36
    }

    private val total: Int = segments.sumOf { it.weight }

    private val isSupported: Boolean
        get() = Build.VERSION.SDK_INT >= ANDROID_16

    // ─── MethodCallHandler ───────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isSupported" -> result.success(isSupported)
                "showProgress" -> {
                    val stage = call.argument<String>("stage") ?: ""
                    val title = call.argument<String>("title") ?: "GitSync"
                    val text = call.argument<String>("text") ?: ""
                    showProgress(stage, title, text)
                    result.success(null)
                }
                "completeProgress" -> {
                    val success = call.argument<Boolean>("success") ?: true
                    val title = call.argument<String>("title") ?: "GitSync"
                    val text = call.argument<String>("text") ?: ""
                    val autoCancelMs = (call.argument<Int>("autoCancelMs") ?: 2000).toLong()
                    completeProgress(success, title, text, autoCancelMs)
                    result.success(null)
                }
                "cancelProgress" -> {
                    cancelProgress()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            Log.e("ProgressStyleNotif", "Method call failed: ${call.method}", t)
            result.error("progress_notif_failed", t.message, null)
        }
    }

    // ─── Public helpers (callable directly from Kotlin if needed) ────────────

    @SuppressLint("NewApi")
    fun showProgress(stage: String, title: String, text: String) {
        if (!isSupported) return
        ensureChannel()

        val progress = stageProgressMap[stage] ?: stageProgressMap.values.firstOrNull() ?: 0

        val style = Notification.ProgressStyle()
            .setStyledByProgress(true)
            .setProgress(progress)
            .setProgressTrackerIcon(trackerIcon())
            .setProgressSegments(segments.map {
                Notification.ProgressStyle.Segment(it.weight).setColor(Color.parseColor(it.colorHex))
            })
            .setProgressPoints(cumulativePoints())

        val notification = baseBuilder(title, text)
            .setStyle(style)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()

        notificationManager().notify(notificationId, notification)
    }

    @SuppressLint("NewApi")
    fun completeProgress(success: Boolean, title: String, text: String, autoCancelMs: Long) {
        if (!isSupported) return
        ensureChannel()

        val color = if (success) Color.parseColor("#388E3C") else Color.parseColor("#D32F2F")
        val style = Notification.ProgressStyle()
            .setStyledByProgress(true)
            .setProgress(total)
            .setProgressTrackerIcon(trackerIcon())
            .setProgressSegments(
                listOf(Notification.ProgressStyle.Segment(total).setColor(color))
            )

        val notification = baseBuilder(title, text)
            .setStyle(style)
            .setOngoing(false)
            .setAutoCancel(true)
            .build()

        val nm = notificationManager()
        nm.notify(notificationId, notification)

        if (autoCancelMs > 0) {
            android.os.Handler(context.mainLooper).postDelayed({
                try {
                    nm.cancel(notificationId)
                } catch (t: Throwable) {
                    Log.w("ProgressStyleNotif", "auto-cancel failed", t)
                }
            }, autoCancelMs)
        }
    }

    fun cancelProgress() {
        try {
            notificationManager().cancel(notificationId)
        } catch (t: Throwable) {
            Log.w("ProgressStyleNotif", "cancel failed", t)
        }
    }

    // ─── Private helpers ─────────────────────────────────────────────────────

    /**
     * Computes white divider points at every segment boundary except the last.
     */
    @SuppressLint("NewApi")
    private fun cumulativePoints(): List<Notification.ProgressStyle.Point> {
        val points = mutableListOf<Notification.ProgressStyle.Point>()
        var cumulative = 0
        for (i in 0 until segments.size - 1) {
            cumulative += segments[i].weight
            points.add(Notification.ProgressStyle.Point(cumulative).setColor(Color.WHITE))
        }
        return points
    }

    @SuppressLint("NewApi")
    private fun baseBuilder(title: String, text: String): Notification.Builder {
        return Notification.Builder(context, channelId)
            .setSmallIcon(smallIconRes())
            .setContentTitle(title)
            .setContentText(text)
            .setShowWhen(false)
    }

    @SuppressLint("NewApi")
    private fun trackerIcon(): Icon {
        return Icon.createWithResource(context, smallIconRes())
    }

    private fun smallIconRes(): Int {
        val res = context.resources.getIdentifier("gitsync_notif", "drawable", context.packageName)
        return if (res != 0) res else android.R.drawable.ic_dialog_info
    }

    private fun notificationManager(): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = notificationManager()
        if (nm.getNotificationChannel(channelId) == null) {
            val channel = NotificationChannel(
                channelId,
                channelUserName,
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.setShowBadge(false)
            nm.createNotificationChannel(channel)
        }
    }
}
