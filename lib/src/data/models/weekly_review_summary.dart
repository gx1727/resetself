class WeeklyReviewSummary {
  const WeeklyReviewSummary({
    required this.matchCount,
    required this.partialCount,
    required this.fullDeviationCount,
    required this.sosCount,
    required this.vacuumFocusCount,
    required this.sampleCount,
  });

  final int matchCount;
  final int partialCount;
  final int fullDeviationCount;
  final int sosCount;
  final int vacuumFocusCount;
  final int sampleCount;

  int get totalCheckins => matchCount + partialCount + fullDeviationCount;

  String get summaryTitle {
    if (totalCheckins == 0 && sosCount == 0 && vacuumFocusCount == 0) {
      return '这一周还没有形成复盘样本';
    }

    if (vacuumFocusCount >= 3 && matchCount >= fullDeviationCount) {
      return '这一周已经开始形成稳定回流';
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
    if (totalCheckins == 0 && sosCount == 0 && vacuumFocusCount == 0) {
      return '没有关系，系统会继续等你把第一批真实数据带回来。';
    }

    final buffer = StringBuffer();
    buffer.write('完全匹配 $matchCount 次');
    buffer.write('，部分偏离 $partialCount 次');
    buffer.write('，完全偏离 $fullDeviationCount 次');
    if (sosCount > 0) {
      buffer.write('，触发 SOS $sosCount 次');
    }
    if (vacuumFocusCount > 0) {
      buffer.write('，完成真空专注 $vacuumFocusCount 次');
    }
    buffer.write('。');
    return buffer.toString();
  }

  String get positiveSignalTitle {
    if (vacuumFocusCount == 0 && matchCount == 0) {
      return '正向回流还在积累中';
    }

    if (vacuumFocusCount >= 3) {
      return '你已经开始主动把自己带回来了';
    }

    if (matchCount >= 2) {
      return '新的身份匹配开始有连续性了';
    }

    return '这一周已经出现第一批回流信号';
  }

  String get positiveSignalBody {
    if (vacuumFocusCount == 0 && matchCount == 0) {
      return '先完成一次专注，或记录一次完全匹配，系统就会开始显影正向变化。';
    }

    if (vacuumFocusCount >= 3) {
      return '最近 7 天你已经完成 $vacuumFocusCount 次真空专注，这说明你不只是看见偏离，也开始主动回到轨道。';
    }

    if (matchCount >= 2) {
      return '最近 7 天已有 $matchCount 次完全匹配，说明新的身份并不是偶发出现。';
    }

    return '最近 7 天你已经留下了第一批可见的回流证据，继续把它们做小、做稳。';
  }
}
