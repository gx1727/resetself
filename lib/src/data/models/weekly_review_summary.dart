import '../../core/copy/neutral_copy_engine.dart';

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
    return NeutralCopyEngine.weeklySummaryTitle(
      totalCheckins: totalCheckins,
      sosCount: sosCount,
      vacuumFocusCount: vacuumFocusCount,
      matchCount: matchCount,
      partialCount: partialCount,
      fullDeviationCount: fullDeviationCount,
    );
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
    return NeutralCopyEngine.weeklyPositiveSignalTitle(
      vacuumFocusCount: vacuumFocusCount,
      matchCount: matchCount,
    );
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
