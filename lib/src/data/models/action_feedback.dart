/// 行动反馈闭环的一条记录。
///
/// 对齐规范 §8.1 建议的产品记录模板：
/// 「尝试了什么 → 发生了什么 → 得到什么认识 → 下一次调整什么」。
/// 四个字段都是用户写下的主观文本，不做评分或排名。
class ActionFeedback {
  const ActionFeedback({
    required this.id,
    required this.attempted,
    required this.happened,
    required this.insight,
    required this.adjustment,
    required this.createdAt,
  });

  final int id;

  /// 尝试了什么：这一次实际执行的动作或实验。
  final String attempted;

  /// 发生了什么：执行之后观察到的实际结果。
  final String happened;

  /// 得到什么认识：从结果里读到的判断或线索。
  final String insight;

  /// 下一次调整什么：准备改变的行动、环境或方法。
  final String adjustment;

  final DateTime createdAt;

  bool get hasAnyInput =>
      attempted.trim().isNotEmpty ||
      happened.trim().isNotEmpty ||
      insight.trim().isNotEmpty ||
      adjustment.trim().isNotEmpty;

  factory ActionFeedback.fromMap(Map<String, Object?> map) {
    return ActionFeedback(
      id: map['id'] as int? ?? 0,
      attempted: map['attempted'] as String? ?? '',
      happened: map['happened'] as String? ?? '',
      insight: map['insight'] as String? ?? '',
      adjustment: map['adjustment'] as String? ?? '',
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
