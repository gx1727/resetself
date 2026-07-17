import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_providers.dart';
import '../../../data/models/daily_checkin.dart';
import '../../../data/models/inertia_sample.dart';
import '../../../data/models/weekly_review_summary.dart';
import '../../vacuum/application/vacuum_mode_providers.dart';

final todayCheckinProvider = FutureProvider.autoDispose<DailyCheckin?>((ref) {
  return ref.watch(userProfileRepositoryProvider).getTodayCheckin();
});

final recentSampleCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(userProfileRepositoryProvider).getRecentSampleCount();
});

final latestSampleProvider = FutureProvider.autoDispose<InertiaSample?>((ref) {
  return ref.watch(userProfileRepositoryProvider).getLatestSample();
});

final homeWeeklyReviewProvider =
    FutureProvider.autoDispose<WeeklyReviewSummary>((ref) {
  return ref.watch(userProfileRepositoryProvider).getWeeklyReviewSummary();
});

void invalidateHomeSurface(WidgetRef ref) {
  ref.invalidate(todayCheckinProvider);
  ref.invalidate(recentSampleCountProvider);
  ref.invalidate(latestSampleProvider);
  ref.invalidate(homeWeeklyReviewProvider);
  ref.invalidate(vacuumFocusStateProvider);
}
