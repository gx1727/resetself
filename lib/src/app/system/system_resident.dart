import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/copy/neutral_copy_engine.dart';
import '../../data/models/vacuum_mode_settings.dart';

/// 系统层后台服务与提醒排程的状态快照。
class SystemResidentStatus {
  const SystemResidentStatus({
    required this.notificationsEnabled,
    required this.exactAlarmAllowed,
    required this.ignoringBatteryOptimizations,
    required this.residentRunning,
    required this.scheduledReminderCount,
  });

  final bool notificationsEnabled;
  final bool exactAlarmAllowed;
  final bool ignoringBatteryOptimizations;
  final bool residentRunning;
  final int scheduledReminderCount;

  static const SystemResidentStatus unsupported = SystemResidentStatus(
    notificationsEnabled: false,
    exactAlarmAllowed: false,
    ignoringBatteryOptimizations: false,
    residentRunning: false,
    scheduledReminderCount: 0,
  );

  factory SystemResidentStatus.fromMap(Map<Object?, Object?> map) {
    bool readBool(String key) => map[key] == true;
    return SystemResidentStatus(
      notificationsEnabled: readBool('notificationsEnabled'),
      exactAlarmAllowed: readBool('exactAlarmAllowed'),
      ignoringBatteryOptimizations: readBool('ignoringBatteryOptimizations'),
      residentRunning: readBool('residentRunning'),
      scheduledReminderCount:
          (map['scheduledReminderCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 与 Android 原生侧（前台常驻服务 + AlarmManager 闹钟）的桥接。
///
/// 提醒内容由 Dart 侧按当前真空模式设置生成，原生侧只负责排程与展示，
/// 因此修改设置只需要重新 sync 一次。
class SystemResident {
  const SystemResident._();

  static const MethodChannel _channel = MethodChannel(
    'com.gx1727.resetself/resident',
  );

  /// 日间打断的提醒 id 从 2000 起，真空温和提醒固定 2900，避开前台服务的 1001。
  static const int _interruptReminderIdBase = 2000;
  static const int _vacuumReminderId = 2900;

  static bool get isSupported => Platform.isAndroid;

  /// 通知点击"问题直达"时，原生侧通过这个流把目标问题 id 传给 Dart。
  static final StreamController<String> _daytimePromptController =
      StreamController<String>.broadcast();

  static Stream<String> get daytimePromptRequests =>
      _daytimePromptController.stream;

  static bool _promptHandlerBound = false;

  /// 绑定原生 → Dart 的通知点击回调，并告知原生侧可以开始投递。
  ///
  /// 冷启动时通知点发生得早于 Dart 初始化，因此用 ready 握手让原生侧先在
  /// 本地暂存，等这里准备好后再补发，避免丢失"问题直达"。
  static void bindDaytimePromptRequests() {
    if (!isSupported || _promptHandlerBound) {
      return;
    }
    _promptHandlerBound = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openDaytimePrompt') {
        final arguments = call.arguments;
        final promptId = arguments is Map
            ? arguments['promptId'] as String?
            : null;
        if (promptId != null && promptId.isNotEmpty) {
          _daytimePromptController.add(promptId);
        }
      }
      return null;
    });
    _invoke('promptBridgeReady');
  }

  /// 拉起前台常驻服务，让进程在后台不被系统回收。失败时静默忽略。
  static Future<void> start() async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('startResident');
    } catch (_) {
      // 原生侧不可用时不影响应用本身。
    }
  }

  static Future<void> stop() async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('stopResident');
    } catch (_) {
      // 忽略。
    }
  }

  /// 按当前真空模式设置重排全部提醒。
  static Future<void> syncReminders(VacuumModeSettings settings) async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>(
        'syncReminders',
        buildReminders(settings),
      );
    } catch (_) {
      // 忽略。
    }
  }

  static Future<SystemResidentStatus> status() async {
    if (!isSupported) {
      return SystemResidentStatus.unsupported;
    }
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'status',
      );
      if (result == null) {
        return SystemResidentStatus.unsupported;
      }
      return SystemResidentStatus.fromMap(result);
    } catch (_) {
      return SystemResidentStatus.unsupported;
    }
  }

  static Future<void> requestNotificationPermission() async {
    await _invoke('requestNotificationPermission');
  }

  static Future<void> requestExactAlarmPermission() async {
    await _invoke('requestExactAlarm');
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    await _invoke('requestIgnoreBatteryOptimizations');
  }

  static Future<void> _invoke(String method) async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>(method);
    } catch (_) {
      // 忽略。
    }
  }

  /// 把真空模式设置翻译成原生侧的每日提醒清单。
  static List<Map<String, Object?>> buildReminders(
    VacuumModeSettings settings,
  ) {
    final reminders = <Map<String, Object?>>[];
    final interruptCopy = CopyStrategy.daytimeInterrupt();
    final prompts = interruptCopy.prompts;

    if (settings.interruptEnabled) {
      final times = settings.interruptTimeList;
      for (var index = 0; index < times.length; index++) {
        final time = times[index];
        final parsed = _parseHourMinute(time);
        if (parsed == null) {
          continue;
        }
        final prompt = index < prompts.length ? prompts[index] : null;
        reminders.add({
          'id': _interruptReminderIdBase + index,
          'hour': parsed.$1,
          'minute': parsed.$2,
          'title': '日间打断 · $time',
          'body': prompt?.question ?? '花片刻回看刚才的行为：发生了什么，它可能在服务什么？',
          'promptId': prompt?.id ?? '',
        });
      }
    }

    if (settings.gentleReminderEnabled) {
      final parsed = _parseHourMinute(settings.reminderTime);
      if (parsed != null) {
        reminders.add({
          'id': _vacuumReminderId,
          'hour': parsed.$1,
          'minute': parsed.$2,
          'title': '温和提醒',
          'body': '${settings.reminderTime} 到了。把它当作一次轻提醒，不把它当成压迫。',
        });
      }
    }

    return reminders;
  }

  static (int, int)? _parseHourMinute(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return (hour, minute);
  }
}
