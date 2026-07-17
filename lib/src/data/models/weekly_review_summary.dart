class WeeklyReviewSummary {
  const WeeklyReviewSummary({
    required this.matchCount,
    required this.partialCount,
    required this.fullDeviationCount,
    required this.sosCount,
    required this.sampleCount,
  });

  final int matchCount;
  final int partialCount;
  final int fullDeviationCount;
  final int sosCount;
  final int sampleCount;

  int get totalCheckins => matchCount + partialCount + fullDeviationCount;

  String get summaryTitle {
    if (totalCheckins == 0 && sosCount == 0) {
      return '这一周还没有形成复盘样本';
    }

    if (matchCount >= partialCount + fullDeviationCount) {
      return '这一周的新身份正在慢慢站稳';
    }

    if (fullDeviationCount > partialCount) {
      return '这一周旧惯性的反扑更明显一些';
    }

    return '这一周处在拉扯中，但已经开始被看见';
  }

  String get summaryBody {
    if (totalCheckins == 0 && sosCount == 0) {
      return '没有关系，系统会继续等你把第一批真实数据带回来。';
    }

    final buffer = StringBuffer();
    buffer.write('完全匹配 $matchCount 次');
    buffer.write('，部分偏离 $partialCount 次');
    buffer.write('，完全偏离 $fullDeviationCount 次');
    if (sosCount > 0) {
      buffer.write('，触发 SOS $sosCount 次');
    }
    buffer.write('。');
    return buffer.toString();
  }
}
