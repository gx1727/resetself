class VacuumFocusState {
  const VacuumFocusState({
    required this.isActive,
    this.startedAt,
    this.plannedEndAt,
    this.lastEndedAt,
  });

  final bool isActive;
  final DateTime? startedAt;
  final DateTime? plannedEndAt;
  final DateTime? lastEndedAt;

  factory VacuumFocusState.inactive({DateTime? lastEndedAt}) {
    return VacuumFocusState(
      isActive: false,
      lastEndedAt: lastEndedAt,
    );
  }

  factory VacuumFocusState.fromMap(Map<String, Object?> map) {
    return VacuumFocusState(
      isActive: (map['is_active'] as int? ?? 0) == 1,
      startedAt: _parseDateTime(map['started_at']),
      plannedEndAt: _parseDateTime(map['planned_end_at']),
      lastEndedAt: _parseDateTime(map['last_ended_at']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'is_active': isActive ? 1 : 0,
      'started_at': startedAt?.toIso8601String(),
      'planned_end_at': plannedEndAt?.toIso8601String(),
      'last_ended_at': lastEndedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  int? get plannedMinutes {
    if (startedAt == null || plannedEndAt == null) {
      return null;
    }

    return plannedEndAt!.difference(startedAt!).inMinutes;
  }

  int? get remainingMinutes {
    if (!isActive || plannedEndAt == null) {
      return null;
    }

    final now = DateTime.now();
    final diff = plannedEndAt!.difference(now).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  bool get isOverdue {
    if (!isActive || plannedEndAt == null) {
      return false;
    }

    return plannedEndAt!.isBefore(DateTime.now());
  }
}

DateTime? _parseDateTime(Object? value) {
  final raw = value as String?;
  if (raw == null || raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}
