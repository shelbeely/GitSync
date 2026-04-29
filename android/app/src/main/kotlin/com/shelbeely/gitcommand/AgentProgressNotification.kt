package com.shelbeely.gitcommand

import android.content.Context

/**
 * Copilot agent-session progress notification.
 *
 * Three-segment bar: Creating → Working → Done.
 * Must match `agentSessionNotificationId` and `gitSyncAgentChannelId` in
 * `lib/constant/strings.dart`.
 */
object AgentProgressNotification {

    const val CHANNEL_NAME = "com.shelbeely.gitcommand/agent_progress"

    private const val NOTIF_CHANNEL_ID = "git_sync_agent_channel"
    private const val NOTIF_CHANNEL_USER_NAME = "GitSync Agent Status"
    private const val NOTIFICATION_ID = 1735

    // Segment weights (progress units).
    private const val SEG_CREATING = 200
    private const val SEG_WORKING = 400
    private const val SEG_DONE = 200

    fun create(context: Context): ProgressStyleNotificationHelper =
        ProgressStyleNotificationHelper(
            context = context,
            channelId = NOTIF_CHANNEL_ID,
            channelUserName = NOTIF_CHANNEL_USER_NAME,
            notificationId = NOTIFICATION_ID,
            segments = listOf(
                NotifSegment(SEG_CREATING, "#1976D2"),
                NotifSegment(SEG_WORKING, "#7B1FA2"),
                NotifSegment(SEG_DONE, "#388E3C"),
            ),
            stageProgressMap = mapOf(
                "creating" to SEG_CREATING / 2,
                "working" to SEG_CREATING + SEG_WORKING / 2,
            ),
        )
}
