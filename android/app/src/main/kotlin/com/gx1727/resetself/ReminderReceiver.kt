package com.gx1727.resetself

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** 闹钟到点：弹出提醒，并把这条提醒排到明天同一时刻。 */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_REMINDER_ID, -1)
        if (id <= 0) {
            return
        }

        val spec = ReminderStore.find(context, id) ?: return
        NotificationHelper.notifyReminder(context, spec)
        ReminderScheduler.schedule(context, spec)
    }

    companion object {
        const val EXTRA_REMINDER_ID = "reminder_id"
    }
}
