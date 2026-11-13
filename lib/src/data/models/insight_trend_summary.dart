import '../../core/copy/neutral_copy_engine.dart';

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
    return NeutralCopyEngine.insightDominantLabel(
      totalCount: totalCount,
      dailyDeviationCount: dailyDeviationCount,
      sosCount: sosCount,
      restructureCount: restructureCount,
      vacuumFocusCount: vacuumFocusCount,
    );
  }
}
