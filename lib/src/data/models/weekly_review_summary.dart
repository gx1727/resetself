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
    buffer.write('主观完全匹配 $matchCount 次');
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
      return '这段时间没有专注完成或主观完全匹配记录，可结合实际经历回顾。';
    }

    if (vacuumFocusCount >= 3) {
      return '最近 7 天记录了 $vacuumFocusCount 次已完成的专注。回看这些时间实际推进了什么。';
    }

    if (matchCount >= 2) {
      return '最近 7 天记录了 $matchCount 次主观完全匹配，可结合实际行动回顾。';
    }

    return '最近 7 天已有专注或主观匹配记录，可结合实际行动回顾。';
  }
}
