class RestructureDraft {
  const RestructureDraft({
    required this.antiVision,
    required this.fearContent,
    required this.beliefDraft,
    required this.identityDraft,
    required this.minActionDraft,
    this.updatedAt,
  });

  final String antiVision;
  final String fearContent;
  final String beliefDraft;
  final String identityDraft;
  final String minActionDraft;
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
        minActionDraft.trim().isNotEmpty;
  }

  bool get isReadyToSubmit {
    return antiVision.trim().isNotEmpty &&
        fearContent.trim().isNotEmpty &&
        beliefDraft.trim().isNotEmpty &&
        identityDraft.trim().isNotEmpty &&
        minActionDraft.trim().isNotEmpty;
  }

  RestructureDraft copyWith({
    String? antiVision,
    String? fearContent,
    String? beliefDraft,
    String? identityDraft,
    String? minActionDraft,
    DateTime? updatedAt,
  }) {
    return RestructureDraft(
      antiVision: antiVision ?? this.antiVision,
      fearContent: fearContent ?? this.fearContent,
      beliefDraft: beliefDraft ?? this.beliefDraft,
      identityDraft: identityDraft ?? this.identityDraft,
      minActionDraft: minActionDraft ?? this.minActionDraft,
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
