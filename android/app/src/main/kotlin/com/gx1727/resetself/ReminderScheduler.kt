package com.gx1727.resetself

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

/**
 * 用 AlarmManager 排每日提醒。
 *
 * 优先用 setExactAndAllowWhileIdle 安排指定时点；送达仍受系统限制；
 * 若系统未授予精确闹钟权限，则退回 setAndAllowWhileIdle（可能被系统延后几分钟）。
 */
object ReminderScheduler {
    fun sync(context: Context, specs: List<ReminderSpec>) {
        cancelAll(context)
        ReminderStore.save(context, specs)
        specs.forEach { schedule(context, it) }
    }

    fun rescheduleSaved(context: Context) {
        ReminderStore.load(context).forEach { schedule(context, it) }
    }

    fun cancelAll(context: Context) {
        val alarmManager = alarmManager(context) ?: return
        ReminderStore.load(context).forEach { spec ->
            alarmManager.cancel(pendingIntent(context, spec.id))
        }
    }

    fun schedule(context: Context, spec: ReminderSpec) {
        val alarmManager = alarmManager(context) ?: return
        val triggerAt = nextTriggerMillis(spec.hour, spec.minute)
        val pendingIntent = pendingIntent(context, spec.id)

        if (canScheduleExact(alarmManager)) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAt,
                pendingIntent,
            )
        } else {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAt,
                pendingIntent,
            )
        }
    }

    fun canScheduleExact(alarmManager: AlarmManager): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
    }

    /** 今天该时点若已过，则排到明天。 */
    fun nextTriggerMillis(hour: Int, minute: Int): Long {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, hour)
        calendar.set(Calendar.MINUTE, minute)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        if (calendar.timeInMillis <= System.currentTimeMillis()) {
            calendar.add(Calendar.DAY_OF_YEAR, 1)
        }
        return calendar.timeInMillis
    }

    private fun pendingIntent(context: Context, id: Int): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            action = "com.gx1727.resetself.action.REMINDER"
            putExtra(ReminderReceiver.EXTRA_REMINDER_ID, id)
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getBroadcast(context, id, intent, flags)
    }

    private fun alarmManager(context: Context): AlarmManager? {
        return context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
    }
}
