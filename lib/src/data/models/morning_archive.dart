import 'dart:convert';

class MorningDraftSnapshot {
  MorningDraftSnapshot(Map<String, String> answers, Set<String> reviewKeys)
    : answers = Map.unmodifiable(answers),
      reviewKeys = Set.unmodifiable(reviewKeys);
  final Map<String, String> answers;
  final Set<String> reviewKeys;
}

class MorningArchive {
  MorningArchive.fromMap(Map<String, Object?> row)
    : id = row['id'] as int,
      startedAt = DateTime.tryParse(row['started_at'] as String? ?? ''),
      archivedAt = DateTime.parse(row['archived_at'] as String),
      answers = Map.unmodifiable(
        Map<String, String>.from(
          jsonDecode(row['answers_json'] as String) as Map,
        ),
      ),
      reviewKeys = Set.unmodifiable(
        List<String>.from(
          jsonDecode(row['review_keys_json'] as String) as List,
        ),
      );
  final int id;
  final DateTime? startedAt;
  final DateTime archivedAt;
  final Map<String, String> answers;
  final Set<String> reviewKeys;
}
