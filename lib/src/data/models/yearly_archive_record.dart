class YearlyArchiveRecord {
  const YearlyArchiveRecord({
    required this.id,
    required this.archiveYear,
    required this.identitySnapshot,
    required this.beliefSnapshot,
    required this.sampleCount,
    required this.checkinStability,
    required this.createdAt,
  });

  final int id;
  final int archiveYear;
  final String identitySnapshot;
  final String beliefSnapshot;
  final int sampleCount;
  final String checkinStability;
  final DateTime? createdAt;

  factory YearlyArchiveRecord.fromMap(Map<String, Object?> map) {
    return YearlyArchiveRecord(
      id: map['id'] as int? ?? 0,
      archiveYear: map['archive_year'] as int? ?? 0,
      identitySnapshot: map['identity_snapshot'] as String? ?? '',
      beliefSnapshot: map['belief_snapshot'] as String? ?? '',
      sampleCount: map['sample_count'] as int? ?? 0,
      checkinStability: map['checkin_stability'] as String? ?? '',
      createdAt: _parseDateTime(map['created_at'] as String?),
    );
  }
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
