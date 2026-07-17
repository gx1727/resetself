class DailyCheckin {
  const DailyCheckin({
    required this.id,
    required this.checkDate,
    required this.matchStatus,
    required this.systemComment,
    required this.createdAt,
  });

  final int id;
  final String checkDate;
  final String matchStatus;
  final String systemComment;
  final DateTime createdAt;

  factory DailyCheckin.fromMap(Map<String, Object?> map) {
    return DailyCheckin(
      id: map['id'] as int? ?? 0,
      checkDate: map['check_date'] as String? ?? '',
      matchStatus: map['match_status'] as String? ?? '',
      systemComment: map['system_comment'] as String? ?? '',
      createdAt: _parseTimestamp(map['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value case final String text when text.isNotEmpty) {
      return DateTime.tryParse(text);
    }

    return null;
  }
}
