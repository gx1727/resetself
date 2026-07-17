class AppDebugSnapshot {
  const AppDebugSnapshot({
    required this.databasePath,
    required this.totalSampleCount,
    required this.recentSampleCount,
    required this.dailyCheckinCount,
    required this.hasDraft,
    this.latestCheckinDate,
  });

  final String databasePath;
  final int totalSampleCount;
  final int recentSampleCount;
  final int dailyCheckinCount;
  final bool hasDraft;
  final String? latestCheckinDate;
}
