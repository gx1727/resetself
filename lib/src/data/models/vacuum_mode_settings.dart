class VacuumModeSettings {
  const VacuumModeSettings({
    required this.focusWindowMinutes,
    required this.noiseCutEnabled,
    required this.gentleReminderEnabled,
    required this.reminderTime,
    required this.focusRhythmLabel,
    this.interruptEnabled = true,
    this.interruptTimes = defaultInterruptTimes,
  });

  final int focusWindowMinutes;
  final bool noiseCutEnabled;
  final bool gentleReminderEnabled;
  final String reminderTime;
  final String focusRhythmLabel;

  /// 是否安排日间观察通知；不影响手动练习。
  final bool interruptEnabled;

  /// 六个打断时点，逗号分隔，例如 `11:00,13:30,15:15,17:00,19:30,21:00`。
  final String interruptTimes;

  /// 原文提供的六个示例时点，可按日程调整。
  static const defaultInterruptTimes = '11:00,13:30,15:15,17:00,19:30,21:00';

  List<String> get interruptTimeList {
    return interruptTimes
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  factory VacuumModeSettings.defaults() {
    return const VacuumModeSettings(
      focusWindowMinutes: 90,
      noiseCutEnabled: true,
      gentleReminderEnabled: true,
      reminderTime: '21:30',
      focusRhythmLabel: '每晚一次温和提醒',
    );
  }

  VacuumModeSettings copyWith({
    int? focusWindowMinutes,
    bool? noiseCutEnabled,
    bool? gentleReminderEnabled,
    String? reminderTime,
    String? focusRhythmLabel,
    bool? interruptEnabled,
    String? interruptTimes,
  }) {
    return VacuumModeSettings(
      focusWindowMinutes: focusWindowMinutes ?? this.focusWindowMinutes,
      noiseCutEnabled: noiseCutEnabled ?? this.noiseCutEnabled,
      gentleReminderEnabled:
          gentleReminderEnabled ?? this.gentleReminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      focusRhythmLabel: focusRhythmLabel ?? this.focusRhythmLabel,
      interruptEnabled: interruptEnabled ?? this.interruptEnabled,
      interruptTimes: interruptTimes ?? this.interruptTimes,
    );
  }

  factory VacuumModeSettings.fromMap(Map<String, Object?> map) {
    return VacuumModeSettings(
      focusWindowMinutes: map['focus_window_minutes'] as int? ?? 90,
      noiseCutEnabled: (map['noise_cut_enabled'] as int? ?? 1) == 1,
      gentleReminderEnabled: (map['gentle_reminder_enabled'] as int? ?? 1) == 1,
      reminderTime: map['reminder_time'] as String? ?? '21:30',
      focusRhythmLabel: map['focus_rhythm_label'] as String? ?? '每晚一次温和提醒',
      interruptEnabled: (map['interrupt_enabled'] as int? ?? 1) == 1,
      interruptTimes:
          map['interrupt_times'] as String? ?? defaultInterruptTimes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'focus_window_minutes': focusWindowMinutes,
      'noise_cut_enabled': noiseCutEnabled ? 1 : 0,
      'gentle_reminder_enabled': gentleReminderEnabled ? 1 : 0,
      'reminder_time': reminderTime,
      'focus_rhythm_label': focusRhythmLabel,
      'interrupt_enabled': interruptEnabled ? 1 : 0,
      'interrupt_times': interruptTimes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
