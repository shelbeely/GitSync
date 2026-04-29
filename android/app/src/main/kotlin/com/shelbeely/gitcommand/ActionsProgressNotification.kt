package com.shelbeely.gitcommand

import android.content.Context

/**
 * Actions workflow-run progress notification.
 *
 * Three-segment bar: Queued → Running → Done.
 * Must match `actionsRunNotificationId` and `gitSyncActionsChannelId` in
 * `lib/constant/strings.dart`.
 */
object ActionsProgressNotification {

    const val CHANNEL_NAME = "com.shelbeely.gitcommand/actions_progress"

    private const val NOTIF_CHANNEL_ID = "git_sync_actions_channel"
    private const val NOTIF_CHANNEL_USER_NAME = "GitSync Actions Status"
    private const val NOTIFICATION_ID = 1734

    // Segment weights (progress units).
    private const val SEG_QUEUED = 200
    private const val SEG_RUNNING = 400
    private const val SEG_DONE = 200

    fun create(context: Context): ProgressStyleNotificationHelper =
        ProgressStyleNotificationHelper(
            context = context,
            channelId = NOTIF_CHANNEL_ID,
            channelUserName = NOTIF_CHANNEL_USER_NAME,
            notificationId = NOTIFICATION_ID,
            segments = listOf(
                NotifSegment(SEG_QUEUED, "#808080"),
                NotifSegment(SEG_RUNNING, "#1976D2"),
                NotifSegment(SEG_DONE, "#388E3C"),
            ),
            stageProgressMap = mapOf(
                "queued" to SEG_QUEUED / 2,
                "running" to SEG_QUEUED + SEG_RUNNING / 2,
            ),
        )
}
