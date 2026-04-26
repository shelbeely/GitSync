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
 * Bridges Flutter sync-status calls to an Android 16 (API 36)
 * `Notification.ProgressStyle` notification. On older devices the methods are
 * silently no-ops; the Flutter wrapper falls back to the existing toast UX.
 *
 * Stages map onto a four-segment progress bar:
 *   detecting -> first segment active
 *   pulling   -> second segment active (point at boundary)
 *   pushing   -> third segment active (point at boundary)
 *   complete  -> entire bar filled, success/error tinted
 */
class SyncProgressNotification(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.viscouspot.gitsync/sync_progress"

        // Must match `gitSyncSyncChannelId` in lib/constant/strings.dart.
        private const val NOTIF_CHANNEL_ID = "git_sync_sync_channel"
        private const val NOTIF_CHANNEL_USER_NAME = "GitSync Sync Status"

        // Must match `syncStatusNotificationId` in lib/constant/strings.dart so
        // we share the slot with the Dart-side fallback notification.
        private const val NOTIFICATION_ID = 1733

        // Android 16 was assigned API level 36 (BAKLAVA).
        private const val ANDROID_16 = 36

        // Segment widths are arbitrary "progress units"; they describe relative
        // visual width, not real progress amounts.
        private const val SEG_DETECT = 100
        private const val SEG_PULL = 300
        private const val SEG_PUSH = 300
        private const val SEG_FINALISE = 100
        private const val TOTAL = SEG_DETECT + SEG_PULL + SEG_PUSH + SEG_FINALISE
    }

    private val isSupported: Boolean
        get() = Build.VERSION.SDK_INT >= ANDROID_16

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isSupported" -> result.success(isSupported)
                "showProgress" -> {
                    val stage = call.argument<String>("stage") ?: "detecting"
                    val title = call.argument<String>("title") ?: "GitSync"
                    val text = call.argument<String>("text") ?: ""
                    showProgress(stage, title, text)
                    result.success(null)
                }
                "completeProgress" -> {
                    val success = call.argument<Boolean>("success") ?: true
                    val title = call.argument<String>("title") ?: "GitSync"
                    val text = call.argument<String>("text") ?: ""
                    val autoCancelMs = (call.argument<Int>("autoCancelMs") ?: 2000)
                    completeProgress(success, title, text, autoCancelMs.toLong())
                    result.success(null)
                }
                "cancelProgress" -> {
                    cancelProgress()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            Log.e("SyncProgressNotification", "Method call failed: ${call.method}", t)
            result.error("sync_progress_failed", t.message, null)
        }
    }

    @SuppressLint("NewApi")
    private fun showProgress(stage: String, title: String, text: String) {
        if (!isSupported) return

        ensureChannel()

        val progress = when (stage) {
            "detecting" -> SEG_DETECT / 2
            "pulling" -> SEG_DETECT + SEG_PULL / 2
            "pushing" -> SEG_DETECT + SEG_PULL + SEG_PUSH / 2
            else -> SEG_DETECT / 2
        }

        val style = Notification.ProgressStyle()
            .setStyledByProgress(true)
            .setProgress(progress)
            .setProgressTrackerIcon(trackerIcon())
            .setProgressSegments(
                listOf(
                    Notification.ProgressStyle.Segment(SEG_DETECT).setColor(Color.GRAY),
                    Notification.ProgressStyle.Segment(SEG_PULL).setColor(Color.parseColor("#1976D2")),
                    Notification.ProgressStyle.Segment(SEG_PUSH).setColor(Color.parseColor("#388E3C")),
                    Notification.ProgressStyle.Segment(SEG_FINALISE).setColor(Color.GRAY),
                )
            )
            .setProgressPoints(
                listOf(
                    Notification.ProgressStyle.Point(SEG_DETECT).setColor(Color.WHITE),
                    Notification.ProgressStyle.Point(SEG_DETECT + SEG_PULL).setColor(Color.WHITE),
                    Notification.ProgressStyle.Point(SEG_DETECT + SEG_PULL + SEG_PUSH).setColor(Color.WHITE),
                )
            )

        val notification = baseBuilder(title, text)
            .setStyle(style)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()

        notificationManager().notify(NOTIFICATION_ID, notification)
    }

    @SuppressLint("NewApi")
    private fun completeProgress(success: Boolean, title: String, text: String, autoCancelMs: Long) {
        if (!isSupported) return

        ensureChannel()

        val color = if (success) Color.parseColor("#388E3C") else Color.parseColor("#D32F2F")
        val style = Notification.ProgressStyle()
            .setStyledByProgress(true)
            .setProgress(TOTAL)
            .setProgressTrackerIcon(trackerIcon())
            .setProgressSegments(
                listOf(Notification.ProgressStyle.Segment(TOTAL).setColor(color))
            )

        val notification = baseBuilder(title, text)
            .setStyle(style)
            .setOngoing(false)
            .setAutoCancel(true)
            .build()

        val nm = notificationManager()
        nm.notify(NOTIFICATION_ID, notification)

        if (autoCancelMs > 0) {
            android.os.Handler(context.mainLooper).postDelayed({
                try {
                    nm.cancel(NOTIFICATION_ID)
                } catch (t: Throwable) {
                    Log.w("SyncProgressNotification", "auto-cancel failed", t)
                }
            }, autoCancelMs)
        }
    }

    private fun cancelProgress() {
        try {
            notificationManager().cancel(NOTIFICATION_ID)
        } catch (t: Throwable) {
            Log.w("SyncProgressNotification", "cancel failed", t)
        }
    }

    @SuppressLint("NewApi")
    private fun baseBuilder(title: String, text: String): Notification.Builder {
        val builder = Notification.Builder(context, NOTIF_CHANNEL_ID)
            .setSmallIcon(smallIconRes())
            .setContentTitle(title)
            .setContentText(text)
            .setShowWhen(false)
        return builder
    }

    @SuppressLint("NewApi")
    private fun trackerIcon(): Icon {
        return Icon.createWithResource(context, smallIconRes())
    }

    /**
     * Resolves the `gitsync_notif` drawable by name so this file does not need
     * a generated `R` import (the Flutter Gradle plugin owns that namespace).
     * Falls back to the system info icon if the resource is missing.
     */
    private fun smallIconRes(): Int {
        val res = context.resources.getIdentifier("gitsync_notif", "drawable", context.packageName)
        return if (res != 0) res else android.R.drawable.ic_dialog_info
    }

    private fun notificationManager(): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = notificationManager()
        if (nm.getNotificationChannel(NOTIF_CHANNEL_ID) == null) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                NOTIF_CHANNEL_USER_NAME,
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.setShowBadge(false)
            nm.createNotificationChannel(channel)
        }
    }
}
