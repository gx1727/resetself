package com.gx1727.resetself

import android.Manifest
import android.app.ActivityManager
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startResident" -> {
                        ResidentService.start(this)
                        result.success(true)
                    }

                    "stopResident" -> {
                        ResidentService.stop(this)
                        result.success(true)
                    }

                    "syncReminders" -> {
                        val specs = parseReminders(call.arguments)
                        NotificationHelper.ensureChannels(this)
                        ReminderScheduler.sync(this, specs)
                        result.success(true)
                    }

                    "status" -> result.success(currentStatus())

                    "requestNotificationPermission" -> {
                        requestNotificationPermission()
                        result.success(true)
                    }

                    "requestExactAlarm" -> {
                        openExactAlarmSettings()
                        result.success(true)
                    }

                    "requestIgnoreBatteryOptimizations" -> {
                        openBatteryOptimizationSettings()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun parseReminders(arguments: Any?): List<ReminderSpec> {
        val list = arguments as? List<*> ?: return emptyList()
        return list.mapNotNull { raw ->
            val item = raw as? Map<*, *> ?: return@mapNotNull null
            val id = (item["id"] as? Number)?.toInt() ?: return@mapNotNull null
            val hour = (item["hour"] as? Number)?.toInt() ?: return@mapNotNull null
            val minute = (item["minute"] as? Number)?.toInt() ?: return@mapNotNull null
            ReminderSpec(
                id = id,
                hour = hour,
                minute = minute,
                title = item["title"] as? String ?: "ResetSelf",
                body = item["body"] as? String ?: "",
            )
        }
    }

    private fun currentStatus(): Map<String, Any?> {
        val notificationsEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.areNotificationsEnabled()
        }

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        return mapOf(
            "notificationsEnabled" to notificationsEnabled,
            "exactAlarmAllowed" to ReminderScheduler.canScheduleExact(alarmManager),
            "ignoringBatteryOptimizations" to powerManager.isIgnoringBatteryOptimizations(packageName),
            "residentRunning" to isResidentRunning(),
            "scheduledReminderCount" to ReminderStore.load(this).size,
        )
    }

    private fun isResidentRunning(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        val services = manager.getRunningServices(Int.MAX_VALUE)
        return services.any { it.service.className == ResidentService::class.java.name }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return
        }
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATION)
    }

    private fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            openAppDetailsSettings()
            return
        }
        try {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                    Uri.parse("package:$packageName"),
                ),
            )
        } catch (ignored: Exception) {
            openAppDetailsSettings()
        }
    }

    private fun openBatteryOptimizationSettings() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (powerManager.isIgnoringBatteryOptimizations(packageName)) {
            return
        }
        try {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:$packageName"),
                ),
            )
        } catch (ignored: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (ignoredToo: Exception) {
                openAppDetailsSettings()
            }
        }
    }

    private fun openAppDetailsSettings() {
        try {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName"),
                ),
            )
        } catch (ignored: Exception) {
            // 忽略。
        }
    }

    companion object {
        private const val CHANNEL_NAME = "com.gx1727.resetself/resident"
        private const val REQUEST_NOTIFICATION = 9101
    }
}
