import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_providers.dart';
import '../../../data/models/action_feedback.dart';

/// 最近留下的行动反馈闭环记录，用于回看与继续调整。
final recentActionFeedbacksProvider =
    FutureProvider.autoDispose<List<ActionFeedback>>((ref) {
      return ref
          .watch(userProfileRepositoryProvider)
          .getRecentActionFeedbacks();
    });

/// 最近一次行动反馈，供首页入口卡片引用。
final latestActionFeedbackProvider =
    FutureProvider.autoDispose<ActionFeedback?>((ref) {
      return ref.watch(userProfileRepositoryProvider).getLatestActionFeedback();
    });
