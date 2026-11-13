/// 用户身份库里的单条身份卡片（最多 5 条）。
///
/// 一行 = 一句"我是 ____ 的人"。
/// `isActive` 为 0 表示已归档（年度迭代时会被收起），并不删除。
class IdentityAnchor {
  const IdentityAnchor({
    required this.id,
    required this.anchorText,
    required this.source,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String anchorText;
  final String source;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 用户自定义 / 重构向导生成的"全新身份"。
  static const sourceInitial = 'initial';
  static const sourceManual = 'manual';
  static const sourceRestructure = 'restructure';
  static const sourceArchive = 'archive';

  /// 5 条库上限，对应产品全案"用户自定义 5 条以内核心身份"。
  static const maxActiveAnchors = 5;

  IdentityAnchor copyWith({
    int? id,
    String? anchorText,
    String? source,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IdentityAnchor(
      id: id ?? this.id,
      anchorText: anchorText ?? this.anchorText,
      source: source ?? this.source,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'anchor_text': anchorText,
      'source': source,
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static IdentityAnchor fromMap(Map<String, Object?> map) {
    return IdentityAnchor(
      id: map['id'] as int?,
      anchorText: (map['anchor_text'] as String?) ?? '',
      source: (map['source'] as String?) ?? sourceManual,
      isActive: ((map['is_active'] as int?) ?? 1) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse((map['updated_at'] as String?) ?? '') ??
              DateTime.now(),
    );
  }
}
