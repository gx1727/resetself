class RestructureArchiveRecord {
  const RestructureArchiveRecord({
    required this.id,
    required this.antiVision,
    required this.fearContent,
    required this.beliefDraft,
    required this.identityDraft,
    required this.minActionDraft,
    required this.isLatest,
    required this.createYear,
    required this.createdAt,
    this.visionText = '',
    this.yearGoal = '',
    this.monthProject = '',
    this.constraints = '',
  });

  final int id;
  final String antiVision;
  final String fearContent;
  final String beliefDraft;
  final String identityDraft;
  final String minActionDraft;
  final bool isLatest;
  final int? createYear;
  final DateTime? createdAt;
  final String visionText;
  final String yearGoal;
  final String monthProject;
  final String constraints;

  factory RestructureArchiveRecord.fromMap(Map<String, Object?> map) {
    return RestructureArchiveRecord(
      id: map['id'] as int? ?? 0,
      antiVision: map['anti_vision'] as String? ?? '',
      fearContent: map['fear_content'] as String? ?? '',
      beliefDraft: map['belief_draft'] as String? ?? '',
      identityDraft: map['identity_draft'] as String? ?? '',
      minActionDraft: map['min_action_draft'] as String? ?? '',
      isLatest: (map['is_latest'] as int? ?? 0) == 1,
      createYear: map['create_year'] as int?,
      createdAt: _parseDateTime(map['created_at'] as String?),
      visionText: map['vision_text'] as String? ?? '',
      yearGoal: map['year_goal'] as String? ?? '',
      monthProject: map['month_project'] as String? ?? '',
      constraints: map['constraints'] as String? ?? '',
    );
  }
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
