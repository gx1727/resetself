class RestructureDraft {
  const RestructureDraft({
    required this.antiVision,
    required this.fearContent,
    required this.beliefDraft,
    required this.identityDraft,
    required this.minActionDraft,
    this.visionText = '',
    this.yearGoal = '',
    this.monthProject = '',
    this.constraints = '',
    this.updatedAt,
  });

  final String antiVision;
  final String fearContent;
  final String beliefDraft;
  final String identityDraft;
  final String minActionDraft;

  /// 游戏化闭环里的"愿景 MVP"：一句话描述理想中的新生活。
  final String visionText;

  /// 年度层：贴合新身份的长期方向（不量化结果）。
  final String yearGoal;

  /// 月度层：用来校准身份的核心任务。
  final String monthProject;

  /// 避坑机制：会触发旧习惯的环境、场景、信息与规避规则。
  final String constraints;

  final DateTime? updatedAt;

  static RestructureDraft empty() {
    return const RestructureDraft(
      antiVision: '',
      fearContent: '',
      beliefDraft: '',
      identityDraft: '',
      minActionDraft: '',
    );
  }

  bool get hasAnyInput {
    return antiVision.trim().isNotEmpty ||
        fearContent.trim().isNotEmpty ||
        beliefDraft.trim().isNotEmpty ||
        identityDraft.trim().isNotEmpty ||
        minActionDraft.trim().isNotEmpty ||
        visionText.trim().isNotEmpty ||
        yearGoal.trim().isNotEmpty ||
        monthProject.trim().isNotEmpty ||
        constraints.trim().isNotEmpty;
  }

  bool get isReadyToSubmit {
    return antiVision.trim().isNotEmpty &&
        fearContent.trim().isNotEmpty &&
        beliefDraft.trim().isNotEmpty &&
        identityDraft.trim().isNotEmpty &&
        minActionDraft.trim().isNotEmpty &&
        visionText.trim().isNotEmpty &&
        yearGoal.trim().isNotEmpty &&
        monthProject.trim().isNotEmpty &&
        constraints.trim().isNotEmpty;
  }

  RestructureDraft copyWith({
    String? antiVision,
    String? fearContent,
    String? beliefDraft,
    String? identityDraft,
    String? minActionDraft,
    String? visionText,
    String? yearGoal,
    String? monthProject,
    String? constraints,
    DateTime? updatedAt,
  }) {
    return RestructureDraft(
      antiVision: antiVision ?? this.antiVision,
      fearContent: fearContent ?? this.fearContent,
      beliefDraft: beliefDraft ?? this.beliefDraft,
      identityDraft: identityDraft ?? this.identityDraft,
      minActionDraft: minActionDraft ?? this.minActionDraft,
      visionText: visionText ?? this.visionText,
      yearGoal: yearGoal ?? this.yearGoal,
      monthProject: monthProject ?? this.monthProject,
      constraints: constraints ?? this.constraints,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RestructureDraft.fromMap(Map<String, Object?> map) {
    return RestructureDraft(
      antiVision: map['anti_vision'] as String? ?? '',
      fearContent: map['fear_content'] as String? ?? '',
      beliefDraft: map['belief_draft'] as String? ?? '',
      identityDraft: map['identity_draft'] as String? ?? '',
      minActionDraft: map['min_action_draft'] as String? ?? '',
      visionText: map['vision_text'] as String? ?? '',
      yearGoal: map['year_goal'] as String? ?? '',
      monthProject: map['month_project'] as String? ?? '',
      constraints: map['constraints'] as String? ?? '',
      updatedAt: _parseTimestamp(map['updated_at']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'anti_vision': antiVision.trim(),
      'fear_content': fearContent.trim(),
      'belief_draft': beliefDraft.trim(),
      'identity_draft': identityDraft.trim(),
      'min_action_draft': minActionDraft.trim(),
      'vision_text': visionText.trim(),
      'year_goal': yearGoal.trim(),
      'month_project': monthProject.trim(),
      'constraints': constraints.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value case final String text when text.isNotEmpty) {
      return DateTime.tryParse(text);
    }

    return null;
  }
}
