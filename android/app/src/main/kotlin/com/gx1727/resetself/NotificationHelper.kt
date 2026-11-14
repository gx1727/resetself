package com.gx1727.resetself

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * 通知渠道与通知构造。
 *
 * 「后台常驻」渠道用最小重要度，保证前台服务通知安静不打扰；
 * 「节奏提醒」渠道承载日间打断与温和提醒。
 */
object NotificationHelper {
    const val CHANNEL_RESIDENT = "resetself_resident"
    const val CHANNEL_REMINDER = "resetself_reminder"
    const val RESIDENT_NOTIFICATION_ID = 1001

    /** 通知点击时携带的自省问题 id，用于打开应用后直达对应问题。 */
    const val EXTRA_PROMPT_ID = "resetself_prompt_id"

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val resident = NotificationChannel(
            CHANNEL_RESIDENT,
            "后台常驻",
            NotificationManager.IMPORTANCE_MIN,
        ).apply {
            description = "保持本地提醒调度在后台存活"
            setShowBadge(false)
        }

        val reminder = NotificationChannel(
            CHANNEL_REMINDER,
            "节奏提醒",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "日间打断与温和提醒"
        }

        manager.createNotificationChannel(resident)
        manager.createNotificationChannel(reminder)
    }

    fun buildResidentNotification(context: Context): Notification {
        val builder = newBuilder(context, CHANNEL_RESIDENT)
        return builder
            .setSmallIcon(R.drawable.ic_stat_resetself)
            .setContentTitle("ResetSelf 正在守护今日节奏")
            .setContentText("提醒会在后台准时到达")
            .setOngoing(true)
            .setShowWhen(false)
            .setContentIntent(activityIntent(context, RESIDENT_NOTIFICATION_ID, ""))
            .build()
    }

    fun notifyReminder(context: Context, spec: ReminderSpec) {
        ensureChannels(context)
        val builder = newBuilder(context, CHANNEL_REMINDER)
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_resetself)
            .setContentTitle(spec.title)
            .setContentText(spec.body)
            .setStyle(Notification.BigTextStyle().bigText(spec.body))
            .setAutoCancel(true)
            .setContentIntent(activityIntent(context, spec.id, spec.promptId))
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(spec.id, notification)
    }

    private fun newBuilder(context: Context, channelId: String): Notification.Builder {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
    }

    private fun activityIntent(context: Context, requestCode: Int, promptId: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (promptId.isNotEmpty()) {
                putExtra(EXTRA_PROMPT_ID, promptId)
            }
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }
}
