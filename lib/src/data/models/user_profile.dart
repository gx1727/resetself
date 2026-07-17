enum UserProfileStatus {
  uninit('uninit'),
  init('init'),
  finished('finished');

  const UserProfileStatus(this.value);

  final String value;

  static UserProfileStatus fromValue(String? value) {
    return UserProfileStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserProfileStatus.uninit,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.identityText,
    required this.todayMinAction,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String identityText;
  final String todayMinAction;
  final UserProfileStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasCompletedInitialRestructure => status == UserProfileStatus.finished;

  static UserProfile empty() {
    return const UserProfile(
      id: 1,
      identityText: '',
      todayMinAction: '',
      status: UserProfileStatus.uninit,
    );
  }

  static UserProfile demoFinished() {
    return const UserProfile(
      id: 1,
      identityText: '我是一个以清醒、稳定和持续迭代为核心的人。',
      todayMinAction: '今晚睡前写下 1 条新的身份证据。',
      status: UserProfileStatus.finished,
    );
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id'] as int? ?? 1,
      identityText: map['identity_text'] as String? ?? '',
      todayMinAction: map['today_min_action'] as String? ?? '',
      status: UserProfileStatus.fromValue(map['status'] as String?),
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'identity_text': identityText,
      'today_min_action': todayMinAction,
      'status': status.value,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value case final String text when text.isNotEmpty) {
      return DateTime.tryParse(text);
    }

    return null;
  }
}
