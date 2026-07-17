class VacuumModeSettings {
  const VacuumModeSettings({
    required this.focusWindowMinutes,
    required this.noiseCutEnabled,
    required this.gentleReminderEnabled,
    required this.reminderTime,
    required this.focusRhythmLabel,
  });

  final int focusWindowMinutes;
  final bool noiseCutEnabled;
  final bool gentleReminderEnabled;
  final String reminderTime;
  final String focusRhythmLabel;

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
  }) {
    return VacuumModeSettings(
      focusWindowMinutes: focusWindowMinutes ?? this.focusWindowMinutes,
      noiseCutEnabled: noiseCutEnabled ?? this.noiseCutEnabled,
      gentleReminderEnabled:
          gentleReminderEnabled ?? this.gentleReminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      focusRhythmLabel: focusRhythmLabel ?? this.focusRhythmLabel,
    );
  }

  factory VacuumModeSettings.fromMap(Map<String, Object?> map) {
    return VacuumModeSettings(
      focusWindowMinutes: map['focus_window_minutes'] as int? ?? 90,
      noiseCutEnabled: (map['noise_cut_enabled'] as int? ?? 1) == 1,
      gentleReminderEnabled:
          (map['gentle_reminder_enabled'] as int? ?? 1) == 1,
      reminderTime: map['reminder_time'] as String? ?? '21:30',
      focusRhythmLabel:
          map['focus_rhythm_label'] as String? ?? '每晚一次温和提醒',
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
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
