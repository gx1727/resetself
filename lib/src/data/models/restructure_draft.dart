class RestructureDraft {
  const RestructureDraft({
    required this.antiVision,
    required this.fearContent,
    required this.beliefDraft,
    required this.identityDraft,
    required this.minActionDraft,
    this.dailyLevers = '',
    this.visionText = '',
    this.yearGoal = '',
    this.monthProject = '',
    this.constraints = '',
    this.valueConstraints = '',
    this.updatedAt,
  });

  final String antiVision;
  final String fearContent;
  final String beliefDraft;
  final String identityDraft;

  /// 每日杠杆：明天优先推进月项目的 2–3 个行动，可为每一项安排时间块。
  /// 原文建议 2–3 项；这里用多行文本，每行一项。
  final String dailyLevers;

  /// 最小启动行动：从一项推进月项目的每日杠杆中，缩小到当下能开始的一步。
  /// 它是产品适配，用于降低启动负担，仍需指向对应项目；不代替每日杠杆。
  final String minActionDraft;

  /// 游戏化闭环里的"愿景 MVP"：一句话描述理想中的新生活。
  final String visionText;

  /// 年度层：一年后希望成立的一个具体事实（镜头）。
  /// 允许包含合理的数量、日期或其他指标；目标可以随经验调整。
  final String yearGoal;

  /// 月度层：推进一年目标的阶段项目。
  /// 应说明需要学习什么、获得什么技能、构建什么成果。
  final String monthProject;

  /// 环境避坑规则：哪些环境、场景、信息会触发旧习惯，以及对应的规避规则。
  /// 注意与 [valueConstraints] 区分，后者承载原文六组件里的 Constraints。
  final String constraints;

  /// 价值约束：为了实现愿景，不愿牺牲的事项与边界（如健康、重要关系、诚信）。
  final String valueConstraints;

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
        dailyLevers.trim().isNotEmpty ||
        visionText.trim().isNotEmpty ||
        yearGoal.trim().isNotEmpty ||
        monthProject.trim().isNotEmpty ||
        constraints.trim().isNotEmpty ||
        valueConstraints.trim().isNotEmpty;
  }

  bool get isReadyToSubmit {
    return antiVision.trim().isNotEmpty &&
        fearContent.trim().isNotEmpty &&
        beliefDraft.trim().isNotEmpty &&
        identityDraft.trim().isNotEmpty &&
        minActionDraft.trim().isNotEmpty &&
        dailyLevers.trim().isNotEmpty &&
        visionText.trim().isNotEmpty &&
        yearGoal.trim().isNotEmpty &&
        monthProject.trim().isNotEmpty &&
        constraints.trim().isNotEmpty &&
        valueConstraints.trim().isNotEmpty;
  }

  RestructureDraft copyWith({
    String? antiVision,
    String? fearContent,
    String? beliefDraft,
    String? identityDraft,
    String? minActionDraft,
    String? dailyLevers,
    String? visionText,
    String? yearGoal,
    String? monthProject,
    String? constraints,
    String? valueConstraints,
    DateTime? updatedAt,
  }) {
    return RestructureDraft(
      antiVision: antiVision ?? this.antiVision,
      fearContent: fearContent ?? this.fearContent,
      beliefDraft: beliefDraft ?? this.beliefDraft,
      identityDraft: identityDraft ?? this.identityDraft,
      minActionDraft: minActionDraft ?? this.minActionDraft,
      dailyLevers: dailyLevers ?? this.dailyLevers,
      visionText: visionText ?? this.visionText,
      yearGoal: yearGoal ?? this.yearGoal,
      monthProject: monthProject ?? this.monthProject,
      constraints: constraints ?? this.constraints,
      valueConstraints: valueConstraints ?? this.valueConstraints,
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
      dailyLevers: map['daily_levers'] as String? ?? '',
      visionText: map['vision_text'] as String? ?? '',
      yearGoal: map['year_goal'] as String? ?? '',
      monthProject: map['month_project'] as String? ?? '',
      constraints: map['constraints'] as String? ?? '',
      valueConstraints: map['value_constraints'] as String? ?? '',
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
      'daily_levers': dailyLevers.trim(),
      'vision_text': visionText.trim(),
      'year_goal': yearGoal.trim(),
      'month_project': monthProject.trim(),
      'constraints': constraints.trim(),
      'value_constraints': valueConstraints.trim(),
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
