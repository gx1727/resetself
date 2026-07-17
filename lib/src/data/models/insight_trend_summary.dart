class InsightTrendSummary {
  const InsightTrendSummary({
    required this.dailyDeviationCount,
    required this.sosCount,
    required this.restructureCount,
    required this.vacuumFocusCount,
  });

  final int dailyDeviationCount;
  final int sosCount;
  final int restructureCount;
  final int vacuumFocusCount;

  int get totalCount =>
      dailyDeviationCount + sosCount + restructureCount + vacuumFocusCount;

  String get dominantLabel {
    if (totalCount == 0) {
      return '最近 7 天还没有趋势样本';
    }

    if (sosCount >= dailyDeviationCount && sosCount >= restructureCount) {
      return '情绪波动型样本更集中';
    }

    if (dailyDeviationCount >= restructureCount) {
      return '日常偏离型样本更集中';
    }

    if (vacuumFocusCount >= restructureCount) {
      return '真空专注完成样本正在增加';
    }

    return '重构锚点型样本更集中';
  }
}
