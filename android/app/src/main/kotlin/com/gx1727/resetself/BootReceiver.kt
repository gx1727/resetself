package com.gx1727.resetself

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * 开机 / 应用更新后，闹钟会被系统清空，这里按持久化的清单重排，
 * 并顺手把常驻服务拉起来。
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        NotificationHelper.ensureChannels(context)
        ReminderScheduler.rescheduleSaved(context)
        ResidentService.start(context)
    }
}
