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
 *
 * The implementation delegates entirely to [ProgressStyleNotificationHelper];
 * this class only retains the [CHANNEL_NAME] constant and the factory so
 * existing references in [MainActivity] remain stable.
 */
object SyncProgressNotification {

    const val CHANNEL_NAME = "com.viscouspot.gitsync/sync_progress"

    // Must match `gitSyncSyncChannelId` in lib/constant/strings.dart.
    private const val NOTIF_CHANNEL_ID = "git_sync_sync_channel"
    private const val NOTIF_CHANNEL_USER_NAME = "GitSync Sync Status"

    // Must match `syncStatusNotificationId` in lib/constant/strings.dart so
    // we share the slot with the Dart-side fallback notification.
    private const val NOTIFICATION_ID = 1733

    private const val SEG_DETECT = 100
    private const val SEG_PULL = 300
    private const val SEG_PUSH = 300
    private const val SEG_FINALISE = 100

    fun create(context: Context): ProgressStyleNotificationHelper =
        ProgressStyleNotificationHelper(
            context = context,
            channelId = NOTIF_CHANNEL_ID,
            channelUserName = NOTIF_CHANNEL_USER_NAME,
            notificationId = NOTIFICATION_ID,
            segments = listOf(
                NotifSegment(SEG_DETECT, "#808080"),
                NotifSegment(SEG_PULL, "#1976D2"),
                NotifSegment(SEG_PUSH, "#388E3C"),
                NotifSegment(SEG_FINALISE, "#808080"),
            ),
            stageProgressMap = mapOf(
                "detecting" to SEG_DETECT / 2,
                "pulling" to SEG_DETECT + SEG_PULL / 2,
                "pushing" to SEG_DETECT + SEG_PULL + SEG_PUSH / 2,
            ),
        )
}
