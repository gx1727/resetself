package com.gx1727.resetself

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * 前台常驻服务：只挂一条最小重要度的通知，用来让进程不被系统回收，
 * 从而保证本地提醒调度稳定。不做任何后台计算。
 */
class ResidentService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        NotificationHelper.ensureChannels(this)
        val notification = NotificationHelper.buildResidentNotification(this)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NotificationHelper.RESIDENT_NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
                )
            } else {
                startForeground(NotificationHelper.RESIDENT_NOTIFICATION_ID, notification)
            }
        } catch (ignored: Exception) {
            // 系统拒绝前台服务时不崩溃：提醒闹钟本身仍然有效。
        }

        return START_STICKY
    }

    companion object {
        fun start(context: Context) {
            val intent = Intent(context, ResidentService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (ignored: Exception) {
                // 后台启动前台服务被限制时忽略。
            }
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, ResidentService::class.java))
            } catch (ignored: Exception) {
                // 忽略。
            }
        }
    }
}
