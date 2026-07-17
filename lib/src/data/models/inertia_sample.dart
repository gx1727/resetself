class InertiaSample {
  const InertiaSample({
    required this.id,
    required this.sourceType,
    required this.statusTag,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String sourceType;
  final String statusTag;
  final String content;
  final DateTime createdAt;

  factory InertiaSample.fromMap(Map<String, Object?> map) {
    return InertiaSample(
      id: map['id'] as int? ?? 0,
      sourceType: map['source_type'] as String? ?? '',
      statusTag: map['status_tag'] as String? ?? '',
      content: map['content'] as String? ?? '',
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
