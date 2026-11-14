import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../core/widgets/resetself_mark.dart';
import '../../../core/widgets/direction_summary.dart';
import '../../../core/widgets/min_action_editor.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/action_feedback.dart';
import '../../../data/models/daily_checkin.dart';
import '../../../data/models/inertia_sample.dart';
import '../../../data/models/restructure_archive_record.dart';
import '../../../data/models/vacuum_focus_state.dart';
import '../../../data/models/vacuum_mode_settings.dart';
import '../../../data/models/weekly_review_summary.dart';
import '../application/home_providers.dart';
import '../../vacuum/application/vacuum_mode_providers.dart';
import '../../feedback/application/action_feedback_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appControllerProvider).profile;
    final todayCheckinAsync = ref.watch(todayCheckinProvider);
    final recentSampleCountAsync = ref.watch(recentSampleCountProvider);
    final latestSampleAsync = ref.watch(latestSampleProvider);
    final weeklyReviewAsync = ref.watch(homeWeeklyReviewProvider);
    final vacuumSettingsAsync = ref.watch(vacuumModeSettingsProvider);
    final vacuumFocusStateAsync = ref.watch(vacuumFocusStateProvider);
    final latestRestructureAsync = ref.watch(latestRestructureRecordProvider);
    final todayInterruptAsync = ref.watch(todayInterruptReflectionsProvider);
    final actionFeedbacksAsync = ref.watch(recentActionFeedbacksProvider);

    final identityText = profile.identityText.isEmpty
        ? '“我是一个\n看重长远价值的人”'
        : '“${profile.identityText.replaceAll('，', '，\n')}”';
    final minAction = profile.todayMinAction.isEmpty
        ? '清理办公桌面 5 分钟'
        : profile.todayMinAction;
    final recentSampleCount = recentSampleCountAsync.valueOrNull ?? 0;
    final todayCheckin = todayCheckinAsync.valueOrNull;
    final latestSample = latestSampleAsync.valueOrNull;
    final homeCopy = CopyStrategy.home();
    final todayStatusLabel = _todayStatusLabel(todayCheckin);
    final todayStatusDescription = _todayStatusDescription(todayCheckin);
    final checkinButtonLabel = todayCheckin == null
        ? homeCopy.checkinCtaMissing
        : homeCopy.checkinCtaRecorded;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.push(AppRoutes.vacuumMode),
                        icon: const Icon(
                          Icons.air_rounded,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ResetSelfMark(size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'ResetSelf',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  letterSpacing: 2.4,
                                  color: const Color(0x992D2D2D),
                                ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () => context.push(
                              _insightsLocation(source: 'home_archive'),
                            ),
                            icon: const Icon(
                              Icons.archive_outlined,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          Positioned(
                            top: 9,
                            right: 6,
                            child: IgnorePointer(
                              child: recentSampleCount > 0
                                  ? Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF819B8E),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFF7F7F5),
                                          width: 2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        recentSampleCount > 9
                                            ? '9+'
                                            : '$recentSampleCount',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => context.push(AppRoutes.settings),
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0EC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              homeCopy.identityBadge,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    letterSpacing: 1.8,
                                    color: const Color(0xFF819B8E),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            identityText,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: const Color(0xFF2D2D2D),
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: const Color(0xFFF0F0F0),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0C000000),
                                  blurRadius: 15,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.menu_book_outlined,
                                            size: 14,
                                            color: Color(0xFF8E8E93),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            homeCopy.minActionLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF8E8E93,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        minAction,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: const Color(0xFF2D2D2D),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 14),
                                      if (latestRestructureAsync.valueOrNull !=
                                          null)
                                        DirectionSummary(
                                          record: latestRestructureAsync
                                              .valueOrNull!,
                                          title: '这一步服务的方向',
                                        ),
                                      TextButton(
                                        onPressed: () =>
                                            showMinActionEditor(context),
                                        child: const Text('修改最小启动行动'),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _todayStatusBackground(
                                            todayCheckin,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _todayStatusIcon(todayCheckin),
                                              size: 16,
                                              color: _todayStatusColor(
                                                todayCheckin,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                todayStatusLabel,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: _todayStatusColor(
                                                        todayCheckin,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _todayStatusBackground(todayCheckin),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _todayStatusBackground(
                                        todayCheckin,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    _todayStatusIcon(todayCheckin),
                                    color: _todayStatusColor(todayCheckin),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _HomeAntiVisionCard(
                            record: latestRestructureAsync.valueOrNull,
                            onTap: () => context.push(AppRoutes.restructureHub),
                          ),
                          const SizedBox(height: 16),
                          _HomeInterruptCard(
                            settings: vacuumSettingsAsync.valueOrNull,
                            todayCount:
                                (todayInterruptAsync.valueOrNull ?? const [])
                                    .length,
                            onTap: () =>
                                context.push(AppRoutes.daytimeInterrupt),
                          ),
                          const SizedBox(height: 16),
                          _HomeFeedbackLoopCard(
                            feedbacks:
                                actionFeedbacksAsync.valueOrNull ??
                                const <ActionFeedback>[],
                            onTap: () => context.push(AppRoutes.actionFeedback),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: latestSample == null
                                ? const SizedBox.shrink()
                                : Container(
                                    key: ValueKey(latestSample.id),
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCFCFA),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(0xFFEAEAE5),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _sampleSourceIcon(
                                                latestSample.sourceType,
                                              ),
                                              size: 16,
                                              color: _sampleSourceColor(
                                                latestSample,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '最近一次惯性样本',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFF8E8E93,
                                                    ),
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              _formatSampleTime(
                                                latestSample.createdAt,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFF8E8E93,
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          latestSample.statusTag.isEmpty
                                              ? _sampleSourceLabel(
                                                  latestSample.sourceType,
                                                )
                                              : latestSample.statusTag,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: _sampleSourceColor(
                                                  latestSample,
                                                ),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          latestSample.content,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: const Color(0xFF5B5B5B),
                                                height: 1.5,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          weeklyReviewAsync.when(
                            data: (summary) => GestureDetector(
                              onTap: () => context.push(
                                _insightsLocation(source: 'weekly_summary'),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FBF8),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFE2ECE6),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '本周状态摘要',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF819B8E,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            summary.summaryTitle,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF2D2D2D,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            summary.summaryBody,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF5B5B5B,
                                                  ),
                                                  height: 1.5,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          weeklyReviewAsync.when(
                            data: (summary) => _HomePositiveSignalCard(
                              summary: summary,
                              onTap: () => context.push(
                                _insightsLocation(
                                  filter: summary.vacuumFocusCount > 0
                                      ? 'vacuum_focus'
                                      : 'all',
                                  source: 'positive_signal',
                                ),
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          weeklyReviewAsync.when(
                            data: (summary) => vacuumFocusStateAsync.when(
                              data: (focusState) {
                                final suggestion = _buildHomeSuggestion(
                                  todayCheckin: todayCheckin,
                                  latestSample: latestSample,
                                  focusState: focusState,
                                  summary: summary,
                                  minAction: minAction,
                                );
                                return _HomeSmartSuggestionCard(
                                  suggestion: suggestion,
                                  onTap: () => context.push(suggestion.route),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          vacuumSettingsAsync.when(
                            data: (settings) => vacuumFocusStateAsync.when(
                              data: (focusState) => _VacuumRhythmCard(
                                settings: settings,
                                focusState: focusState,
                                minAction: minAction,
                                onTap: () =>
                                    context.push(AppRoutes.vacuumFocus),
                                onToggleFocus: () async {
                                  final repository = ref.read(
                                    userProfileRepositoryProvider,
                                  );
                                  if (focusState.isActive) {
                                    await repository.stopVacuumFocus();
                                  } else {
                                    await repository.startVacuumFocus(settings);
                                  }
                                  invalidateHomeSurface(ref);
                                },
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.dailyCheckin),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(checkinButtonLabel),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    todayStatusDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 110,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 8,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.push(AppRoutes.sos),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF0F0F0)),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      color: Color(0xFF819B8E),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _todayStatusLabel(DailyCheckin? checkin) {
  final copy = CopyStrategy.home();
  if (checkin == null) {
    return copy.todayStatusCheckinMissing;
  }

  switch (checkin.matchStatus) {
    case 'match':
      return copy.todayStatusMatch;
    case 'partial':
      return copy.todayStatusPartial;
    case 'full_deviation':
      return copy.todayStatusFullDeviation;
    default:
      return copy.todayStatusGeneric;
  }
}

String _todayStatusDescription(DailyCheckin? checkin) {
  final copy = CopyStrategy.home();
  if (checkin == null) {
    return copy.todayStatusEmptyHint;
  }

  if (checkin.systemComment.isNotEmpty) {
    return checkin.systemComment;
  }

  return copy.todayStatusRecordedHint;
}

Color _todayStatusColor(DailyCheckin? checkin) {
  switch (checkin?.matchStatus) {
    case 'match':
      return const Color(0xFF819B8E);
    case 'partial':
      return const Color(0xFFC2A878);
    case 'full_deviation':
      return const Color(0xFF8E8E93);
    default:
      return const Color(0xFF8E8E93);
  }
}

Color _todayStatusBackground(DailyCheckin? checkin) {
  switch (checkin?.matchStatus) {
    case 'match':
      return const Color(0xFFE8F0EC);
    case 'partial':
      return const Color(0xFFF9F5EC);
    case 'full_deviation':
      return const Color(0xFFF0F0F0);
    default:
      return const Color(0xFFF2F2F2);
  }
}

IconData _todayStatusIcon(DailyCheckin? checkin) {
  switch (checkin?.matchStatus) {
    case 'match':
      return Icons.check_circle_outline;
    case 'partial':
      return Icons.adjust_rounded;
    case 'full_deviation':
      return Icons.cloud_queue_rounded;
    default:
      return Icons.schedule_rounded;
  }
}

String _sampleSourceLabel(String sourceType) {
  final copy = CopyStrategy.home();
  switch (sourceType) {
    case 'sos':
      return copy.sampleSourceSos;
    case 'daily_checkin':
      return copy.sampleSourceDailyDeviation;
    case 'manual':
      return copy.sampleSourceRestructure;
    case 'vacuum_focus':
      return copy.sampleSourceVacuumFocus;
    default:
      return copy.sampleSourceGeneric;
  }
}

Color _sampleSourceColor(InertiaSample sample) {
  if (sample.sourceType == 'sos') {
    return const Color(0xFF819B8E);
  }

  if (sample.statusTag.contains('部分')) {
    return const Color(0xFFC2A878);
  }

  if (sample.statusTag.contains('完全')) {
    return const Color(0xFF8E8E93);
  }

  return const Color(0xFF819B8E);
}

IconData _sampleSourceIcon(String sourceType) {
  switch (sourceType) {
    case 'sos':
      return Icons.monitor_heart_outlined;
    case 'daily_checkin':
      return Icons.auto_graph_rounded;
    case 'manual':
      return Icons.self_improvement_outlined;
    case 'vacuum_focus':
      return Icons.air_rounded;
    default:
      return Icons.eco_outlined;
  }
}

String _formatSampleTime(DateTime value) {
  final now = DateTime.now();
  final diff = now.difference(value);
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  if (diff.inDays == 0) {
    return '今天 $hour:$minute';
  }

  if (diff.inDays == 1) {
    return '昨天 $hour:$minute';
  }

  return '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute';
}

class _HomeAntiVisionCard extends StatelessWidget {
  const _HomeAntiVisionCard({required this.record, required this.onTap});

  final RestructureArchiveRecord? record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = CopyStrategy.homeAntiVision();
    final antiVision = (record?.antiVision ?? '').trim();
    final vision = (record?.visionText ?? '').trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF6F3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0E2DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E4DC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    copy.badge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFB08F7E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8E8E93),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              copy.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF2D2D2D),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (antiVision.isEmpty)
              Text(
                copy.emptyHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8E8E93),
                  height: 1.5,
                ),
              )
            else ...[
              Text(
                copy.bodyPrefix,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 6),
              Text(
                antiVision,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5B5B5B),
                  height: 1.6,
                ),
              ),
              if (vision.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${copy.visionPrefix}$vision',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF819B8E),
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeInterruptCard extends StatelessWidget {
  const _HomeInterruptCard({
    required this.settings,
    required this.todayCount,
    required this.onTap,
  });

  final VacuumModeSettings? settings;
  final int todayCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = CopyStrategy.daytimeInterrupt();
    final enabled = settings?.interruptEnabled ?? true;
    final times = settings?.interruptTimeList ?? const <String>[];
    final next = _nextInterruptTime(times);
    final summary = !enabled
        ? copy.disabledTitle
        : todayCount > 0
        ? CopyStrategy.daytimeInterruptRecorded(todayCount)
        : next == null
        ? copy.pendingLabel
        : '下一个时点：$next';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0EC),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.timelapse_rounded,
                size: 20,
                color: Color(0xFF819B8E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8E8E93),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93)),
          ],
        ),
      ),
    );
  }
}

class _HomeFeedbackLoopCard extends StatelessWidget {
  const _HomeFeedbackLoopCard({required this.feedbacks, required this.onTap});

  final List<ActionFeedback> feedbacks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = CopyStrategy.actionFeedback();
    final latest = feedbacks.isEmpty ? null : feedbacks.first;
    final summary = latest == null
        ? copy.historyEmpty
        : _feedbackPreview(latest, copy);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0EC),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.loop_rounded,
                size: 20,
                color: Color(0xFF819B8E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8E8E93),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93)),
          ],
        ),
      ),
    );
  }
}

String _feedbackPreview(ActionFeedback feedback, ActionFeedbackCopy copy) {
  final attempted = feedback.attempted.trim();
  if (attempted.isNotEmpty) {
    return '最近一次尝试：$attempted';
  }

  final happened = feedback.happened.trim();
  if (happened.isNotEmpty) {
    return '最近一次观察：$happened';
  }

  return copy.savedBody;
}

String? _nextInterruptTime(List<String> times) {
  if (times.isEmpty) {
    return null;
  }

  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;
  for (final time in times) {
    final parts = time.split(':');
    if (parts.length != 2) {
      continue;
    }
    final minutes =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    if (minutes >= nowMinutes) {
      return time;
    }
  }

  return times.first;
}

class _VacuumRhythmCard extends StatelessWidget {
  const _VacuumRhythmCard({
    required this.settings,
    required this.focusState,
    required this.minAction,
    required this.onTap,
    required this.onToggleFocus,
  });

  final VacuumModeSettings settings;
  final VacuumFocusState focusState;
  final String minAction;
  final VoidCallback onTap;
  final Future<void> Function() onToggleFocus;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2321),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2E3934)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前真空节奏',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF9DB3A7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    focusState.isActive
                        ? '专注进行中'
                        : '${settings.focusWindowMinutes} 分钟安静区',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFF7F7F5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _vacuumSummary(settings, focusState, minAction),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFD5DDD8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _VacuumTag(
                        label: settings.noiseCutEnabled ? '降噪开启' : '降噪关闭',
                      ),
                      _VacuumTag(
                        label: settings.gentleReminderEnabled ? '温和提醒' : '无提醒',
                      ),
                      if (_shouldShowVacuumReturnPrompt(focusState))
                        _VacuumTag(label: '已完成上一段专注'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: onToggleFocus,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0x1AF7F7F5),
                      foregroundColor: const Color(0xFFF7F7F5),
                    ),
                    child: Text(focusState.isActive ? '结束这段专注' : '从首页开始专注'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD5DDD8)),
          ],
        ),
      ),
    );
  }
}

class _HomePositiveSignalCard extends StatelessWidget {
  const _HomePositiveSignalCard({required this.summary, required this.onTap});

  final WeeklyReviewSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (summary.vacuumFocusCount == 0 && summary.matchCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDDEAF2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2F7),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.air_rounded,
                size: 18,
                color: Color(0xFF6E8FA3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本周正向回流',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF6E8FA3),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.positiveSignalTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.positiveSignalBody,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5B5B5B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93)),
          ],
        ),
      ),
    );
  }
}

class _HomeSmartSuggestionCard extends StatelessWidget {
  const _HomeSmartSuggestionCard({
    required this.suggestion,
    required this.onTap,
  });

  final _HomeSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: suggestion.backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: suggestion.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: suggestion.badgeColor,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(
                suggestion.icon,
                size: 18,
                color: suggestion.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '现在先做这个',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: suggestion.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    suggestion.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    suggestion.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5B5B5B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: suggestion.badgeColor,
                      foregroundColor: suggestion.accentColor,
                    ),
                    child: Text(suggestion.actionLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSuggestion {
  const _HomeSuggestion({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.route,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.badgeColor,
  });

  final String title;
  final String body;
  final String actionLabel;
  final String route;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color badgeColor;
}

class _VacuumTag extends StatelessWidget {
  const _VacuumTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AF7F7F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33F7F7F5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFFF7F7F5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _vacuumSummary(
  VacuumModeSettings settings,
  VacuumFocusState focusState,
  String minAction,
) {
  final copy = CopyStrategy.home();
  if (focusState.isActive) {
    final remainingMinutes = focusState.remainingMinutes;
    final remainingText = remainingMinutes == null
        ? copy.vacuumActiveOngoing
        : remainingMinutes == 0
        ? copy.vacuumActiveEnded
        : CopyStrategy.homeVacuumRemaining(remainingMinutes);
    return '$remainingText · ${settings.focusRhythmLabel}';
  }

  if (_shouldShowVacuumReturnPrompt(focusState)) {
    return CopyStrategy.homeVacuumReturnPrompt(minAction);
  }

  final reminderPart = settings.gentleReminderEnabled
      ? CopyStrategy.homeVacuumReminder(settings.reminderTime)
      : copy.vacuumReminderOff;
  final noisePart = settings.noiseCutEnabled
      ? copy.vacuumNoiseOn
      : copy.vacuumNoiseOff;

  return '$reminderPart · ${settings.focusRhythmLabel} · $noisePart';
}

bool _shouldShowVacuumReturnPrompt(VacuumFocusState focusState) {
  final endedAt = focusState.lastEndedAt;
  if (focusState.isActive || endedAt == null) {
    return false;
  }

  return DateTime.now().difference(endedAt).inMinutes <= 180;
}

_HomeSuggestion _buildHomeSuggestion({
  required DailyCheckin? todayCheckin,
  required InertiaSample? latestSample,
  required VacuumFocusState focusState,
  required WeeklyReviewSummary summary,
  required String minAction,
}) {
  if (focusState.isActive) {
    final remainingMinutes = focusState.remainingMinutes;
    final remainingText = remainingMinutes == null
        ? '这一段专注已经开始，先别切走。'
        : remainingMinutes == 0
        ? '这段专注已经到点，可以收尾后回到今天的动作。'
        : '预计还有 $remainingMinutes 分钟，先把这一段安静区走完。';
    final copy = NeutralCopyEngine.homeFocusActive(remainingText);
    return _HomeSuggestion(
      title: copy.title,
      body: copy.body,
      actionLabel: copy.actionLabel,
      route: AppRoutes.vacuumFocus,
      icon: Icons.air_rounded,
      accentColor: Color(0xFF6E8FA3),
      backgroundColor: Color(0xFFF4F8FB),
      borderColor: Color(0xFFDDEAF2),
      badgeColor: Color(0xFFEAF2F7),
    );
  }

  if (todayCheckin == null) {
    final copy = NeutralCopyEngine.homeNeedCheckin(
      justEndedFocus: _shouldShowVacuumReturnPrompt(focusState),
    );
    return _HomeSuggestion(
      title: copy.title,
      body: copy.body,
      actionLabel: copy.actionLabel,
      route: AppRoutes.dailyCheckin,
      icon: Icons.check_circle_outline_rounded,
      accentColor: const Color(0xFF819B8E),
      backgroundColor: const Color(0xFFF4FAF6),
      borderColor: const Color(0xFFDDECE3),
      badgeColor: const Color(0xFFE8F0EC),
    );
  }

  if (latestSample case final sample? when sample.sourceType == 'sos') {
    final copy = NeutralCopyEngine.homeAfterSos(minAction);
    return _HomeSuggestion(
      title: copy.title,
      body: copy.body,
      actionLabel: copy.actionLabel,
      route: AppRoutes.vacuumFocus,
      icon: Icons.air_rounded,
      accentColor: const Color(0xFF6E8FA3),
      backgroundColor: const Color(0xFFF4F8FB),
      borderColor: const Color(0xFFDDEAF2),
      badgeColor: const Color(0xFFEAF2F7),
    );
  }

  if (latestSample case final sample?
      when sample.sourceType == 'vacuum_focus' &&
          _shouldShowVacuumReturnPrompt(focusState)) {
    final copy = NeutralCopyEngine.homeAfterVacuumReturn(minAction);
    return _HomeSuggestion(
      title: copy.title,
      body: copy.body,
      actionLabel: copy.actionLabel,
      route: _insightsLocation(
        filter: 'vacuum_focus',
        source: 'home_suggestion',
      ),
      icon: Icons.playlist_add_check_circle_rounded,
      accentColor: const Color(0xFF819B8E),
      backgroundColor: const Color(0xFFF6FAF7),
      borderColor: const Color(0xFFDDECE3),
      badgeColor: const Color(0xFFE8F0EC),
    );
  }

  if (todayCheckin.matchStatus == 'full_deviation') {
    final copy = NeutralCopyEngine.homeFullDeviation(minAction);
    return _HomeSuggestion(
      title: copy.title,
      body: copy.body,
      actionLabel: copy.actionLabel,
      route: AppRoutes.vacuumFocus,
      icon: Icons.restart_alt_rounded,
      accentColor: const Color(0xFF6E8FA3),
      backgroundColor: const Color(0xFFF4F8FB),
      borderColor: const Color(0xFFDDEAF2),
      badgeColor: const Color(0xFFEAF2F7),
    );
  }

  if (todayCheckin.matchStatus == 'partial') {
    final copy = NeutralCopyEngine.homePartialDeviation(minAction);
    return _HomeSuggestion(
      title: copy.title,
      body: copy.body,
      actionLabel: copy.actionLabel,
      route: _insightsLocation(
        filter: 'daily_deviation',
        source: 'home_suggestion',
      ),
      icon: Icons.adjust_rounded,
      accentColor: const Color(0xFFC2A878),
      backgroundColor: const Color(0xFFFCF8F1),
      borderColor: const Color(0xFFF0E5CF),
      badgeColor: const Color(0xFFF9F5EC),
    );
  }

  if (todayCheckin.matchStatus == 'match') {
    final copy = NeutralCopyEngine.homeMatch(minAction);
    return _HomeSuggestion(
      title: copy.title,
      body: copy.body,
      actionLabel: copy.actionLabel,
      route: _insightsLocation(source: 'home_suggestion'),
      icon: Icons.trending_up_rounded,
      accentColor: const Color(0xFF819B8E),
      backgroundColor: const Color(0xFFF6FAF7),
      borderColor: const Color(0xFFDDECE3),
      badgeColor: const Color(0xFFE8F0EC),
    );
  }

  if (latestSample case final sample?
      when sample.sourceType == 'daily_checkin') {
    final copy = NeutralCopyEngine.homeRecentDailyDeviation(minAction);
    return _HomeSuggestion(
      title: copy.title,
      body: copy.body,
      actionLabel: copy.actionLabel,
      route: AppRoutes.vacuumFocus,
      icon: Icons.air_rounded,
      accentColor: const Color(0xFF6E8FA3),
      backgroundColor: const Color(0xFFF4F8FB),
      borderColor: const Color(0xFFDDEAF2),
      badgeColor: const Color(0xFFEAF2F7),
    );
  }

  if (summary.vacuumFocusCount > 0 || summary.matchCount > 0) {
    final copy = NeutralCopyEngine.homeWeeklyPositive(
      vacuumFocusCount: summary.vacuumFocusCount,
      matchCount: summary.matchCount,
      minAction: minAction,
    );
    return _HomeSuggestion(
      title: copy.title,
      body: copy.body,
      actionLabel: copy.actionLabel,
      route: _insightsLocation(
        filter: summary.vacuumFocusCount > 0 ? 'vacuum_focus' : 'all',
        source: 'home_suggestion',
      ),
      icon: Icons.trending_up_rounded,
      accentColor: const Color(0xFF819B8E),
      backgroundColor: const Color(0xFFF6FAF7),
      borderColor: const Color(0xFFDDECE3),
      badgeColor: const Color(0xFFE8F0EC),
    );
  }

  final copy = NeutralCopyEngine.homeFallback();
  return _HomeSuggestion(
    title: copy.title,
    body: copy.body,
    actionLabel: copy.actionLabel,
    route: AppRoutes.vacuumFocus,
    icon: Icons.air_rounded,
    accentColor: const Color(0xFF6E8FA3),
    backgroundColor: const Color(0xFFF4F8FB),
    borderColor: const Color(0xFFDDEAF2),
    badgeColor: const Color(0xFFEAF2F7),
  );
}

String _insightsLocation({String filter = 'all', String? source}) {
  final queryParameters = <String, String>{};
  if (filter != 'all') {
    queryParameters['filter'] = filter;
  }
  if (source != null && source.isNotEmpty) {
    queryParameters['source'] = source;
  }
  if (queryParameters.isEmpty) {
    return AppRoutes.insights;
  }

  return '${AppRoutes.insights}?${Uri(queryParameters: queryParameters).query}';
}
