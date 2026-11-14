import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/deviation_pattern.dart';
import '../../../data/models/insight_trend_summary.dart';
import '../../../data/models/inertia_sample.dart';
import '../../../data/models/weekly_review_summary.dart';
import '../../restructure/presentation/restructure_restart_sheet.dart';

enum SampleFilter {
  all('全部'),
  dailyDeviation('每日偏离'),
  sos('SOS'),
  restructure('首次重构'),
  vacuumFocus('真空专注');

  const SampleFilter(this.label);

  final String label;

  String get queryValue => switch (this) {
        SampleFilter.all => 'all',
        SampleFilter.dailyDeviation => 'daily_deviation',
        SampleFilter.sos => 'sos',
        SampleFilter.restructure => 'restructure',
        SampleFilter.vacuumFocus => 'vacuum_focus',
      };

  static SampleFilter? fromQueryValue(String? value) {
    return switch (value) {
      'all' => SampleFilter.all,
      'daily_deviation' => SampleFilter.dailyDeviation,
      'sos' => SampleFilter.sos,
      'restructure' => SampleFilter.restructure,
      'vacuum_focus' => SampleFilter.vacuumFocus,
      _ => null,
    };
  }
}

enum InsightEntrySource {
  homeArchive('首页样本入口'),
  weeklySummary('首页本周摘要'),
  positiveSignal('首页正向回流'),
  homeSuggestion('首页建议卡');

  const InsightEntrySource(this.label);

  final String label;

  String get queryValue => switch (this) {
        InsightEntrySource.homeArchive => 'home_archive',
        InsightEntrySource.weeklySummary => 'weekly_summary',
        InsightEntrySource.positiveSignal => 'positive_signal',
        InsightEntrySource.homeSuggestion => 'home_suggestion',
      };

  static InsightEntrySource? fromQueryValue(String? value) {
    return switch (value) {
      'home_archive' => InsightEntrySource.homeArchive,
      'weekly_summary' => InsightEntrySource.weeklySummary,
      'positive_signal' => InsightEntrySource.positiveSignal,
      'home_suggestion' => InsightEntrySource.homeSuggestion,
      _ => null,
    };
  }
}

final recentSamplesProvider =
    FutureProvider.autoDispose.family<List<InertiaSample>, SampleFilter>((
  ref,
  filter,
) {
  return ref.watch(userProfileRepositoryProvider).getRecentSamples(
        sourceType: switch (filter) {
          SampleFilter.all => null,
          SampleFilter.dailyDeviation => 'daily_checkin',
          SampleFilter.sos => 'sos',
          SampleFilter.restructure => 'manual',
          SampleFilter.vacuumFocus => 'vacuum_focus',
        },
      );
});

final weeklyReviewProvider =
    FutureProvider.autoDispose<WeeklyReviewSummary>((ref) {
  return ref.watch(userProfileRepositoryProvider).getWeeklyReviewSummary();
});

final topDeviationPatternsProvider =
    FutureProvider.autoDispose<List<DeviationPattern>>((ref) {
  return ref.watch(userProfileRepositoryProvider).getTopDeviationPatterns();
});

final insightTrendSummaryProvider =
    FutureProvider.autoDispose<InsightTrendSummary>((ref) {
  return ref.watch(userProfileRepositoryProvider).getInsightTrendSummary();
});

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  SampleFilter _selectedFilter = SampleFilter.all;
  String? _appliedFilterKey;
  InsightEntrySource? _entrySource;
  String? _appliedSourceKey;

  void _handleFilterSelected(SampleFilter filter) {
    if (filter == _selectedFilter) {
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _appliedFilterKey =
          filter == SampleFilter.all ? null : filter.queryValue;
    });
    // 筛选是同一页面内的维度切换，用 replace 仅替换当前路由，保留返回栈。
    context.replace(_insightsLocation(filter, source: _entrySource));
  }

  /// 进入 24h 重构前弹出选择层；其它入口保持直接跳转。
  void _goToRoute(BuildContext context, String route) {
    if (route == AppRoutes.restructureSetup) {
      openRestructureRestartFlow(context, ref);
      return;
    }

    if (route == AppRoutes.home) {
      context.go(route);
      return;
    }

    context.push(route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final queryParameters = GoRouterState.of(context).uri.queryParameters;
    final filterKey = queryParameters['filter'];
    final sourceKey = queryParameters['source'];
    if (_appliedFilterKey == filterKey && _appliedSourceKey == sourceKey) {
      return;
    }

    _appliedFilterKey = filterKey;
    _appliedSourceKey = sourceKey;
    final nextFilter = filterKey == null
        ? SampleFilter.all
        : SampleFilter.fromQueryValue(filterKey);
    final nextSource = InsightEntrySource.fromQueryValue(sourceKey);
    if (nextFilter != null &&
        (nextFilter != _selectedFilter || nextSource != _entrySource)) {
      setState(() {
        _selectedFilter = nextFilter;
        _entrySource = nextSource;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final samplesAsync = ref.watch(recentSamplesProvider(_selectedFilter));
    final weeklyReviewAsync = ref.watch(weeklyReviewProvider);
    final topPatternsAsync = ref.watch(topDeviationPatternsProvider);
    final trendSummaryAsync = ref.watch(insightTrendSummaryProvider);
    final weeklySummary = weeklyReviewAsync.valueOrNull;
    final trendSummary = trendSummaryAsync.valueOrNull;
    final insightsCopy = CopyStrategy.insights();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      size: 28,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      insightsCopy.pageTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2D2D2D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: SampleFilter.values.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = SampleFilter.values[index];
                    final isSelected = filter == _selectedFilter;

                    return ChoiceChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      onSelected: (_) => _handleFilterSelected(filter),
                      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? const Color(0xFF819B8E)
                            : const Color(0xFF8E8E93),
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: const Color(0xFFE8F0EC),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE5E5EA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: samplesAsync.when(
                  data: (samples) => ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (_entrySource case final entrySource?) ...[
                        _InsightEntrySourceCard(
                          source: entrySource,
                          filter: _selectedFilter,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _FilterContextCard(
                        filter: _selectedFilter,
                        weeklySummary: weeklySummary,
                        trendSummary: trendSummary,
                      ),
                      const SizedBox(height: 16),
                      if (_showsWeeklyReview(_selectedFilter))
                        weeklyReviewAsync.when(
                        data: (summary) => _WeeklyReviewCard(summary: summary),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),
                      if (_showsWeeklyReview(_selectedFilter))
                        const SizedBox(height: 16),
                      if (_showsPositiveSignal(_selectedFilter))
                        weeklyReviewAsync.when(
                        data: (summary) => _PositiveSignalCard(summary: summary),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),
                      if (_showsPositiveSignal(_selectedFilter))
                        const SizedBox(height: 16),
                      if (_showsDeviationPatterns(_selectedFilter))
                        topPatternsAsync.when(
                        data: (patterns) => _DeviationPatternCard(patterns: patterns),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),
                      if (_showsDeviationPatterns(_selectedFilter))
                        const SizedBox(height: 16),
                      if (_showsTrendSummary(_selectedFilter))
                        trendSummaryAsync.when(
                        data: (summary) => _TrendSummaryCard(summary: summary),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),
                      if (_showsTrendSummary(_selectedFilter))
                        const SizedBox(height: 16),
                      Text(
                        _filterLeadText(_selectedFilter),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8E8E93),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (samples.isEmpty)
                        _InsightEmptyStateCard(
                          filter: _selectedFilter,
                          onTap: () => _goToRoute(
                            context,
                            _emptyStateAction(_selectedFilter).route,
                          ),
                        )
                      else
                        for (final (index, sample) in samples.indexed) ...[
                          if (index > 0) const SizedBox(height: 12),
                          _InsightCard(
                            statusLabel: sample.statusTag.isEmpty
                                ? _defaultStatusLabel(sample.sourceType)
                                : sample.statusTag,
                            statusColor: _statusColor(
                              sample.statusTag,
                              sample.sourceType,
                            ),
                            statusBackground: _statusBackground(
                              sample.statusTag,
                              sample.sourceType,
                            ),
                            timeLabel: _formatTimeLabel(sample.createdAt),
                            description: sample.content.isEmpty
                                ? '这条记录没有写下内容。'
                                : sample.content,
                            faded: sample.sourceType == 'daily_checkin',
                          ),
                        ],
                      if (samples.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _InsightFollowupCard(
                          filter: _selectedFilter,
                          entrySource: _entrySource,
                          onTap: () => _goToRoute(
                            context,
                            _followupAction(
                              _selectedFilter,
                              source: _entrySource,
                            ).route,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          insightsCopy.footer,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0x998E8E93),
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading: () => Center(
                    child: Text(
                      insightsCopy.loadingHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0x998E8E93),
                      ),
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      insightsCopy.errorHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8E8E93),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _emptyStateText(SampleFilter filter) {
  switch (filter) {
    case SampleFilter.all:
      return '这里还是一张白纸。开始记录后，它会慢慢有内容。';
    case SampleFilter.dailyDeviation:
      return '最近 7 天还没有记录到每日偏离，新的惯性正在慢慢成形。';
    case SampleFilter.sos:
      return '最近 7 天你还没有触发 SOS，这也是一种稳定的证据。';
    case SampleFilter.restructure:
      return '这一期的身份重构记录还没有沉淀到这里。';
    case SampleFilter.vacuumFocus:
      return '最近 7 天还没有专注完成样本，先完成一段安静区也会被记录在这里。';
  }
}

class _InsightEmptyStateCard extends StatelessWidget {
  const _InsightEmptyStateCard({
    required this.filter,
    required this.onTap,
  });

  final SampleFilter filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final action = _emptyStateAction(filter);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _emptyStateText(filter),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E93),
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action.label),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightFollowupCard extends StatelessWidget {
  const _InsightFollowupCard({
    required this.filter,
    required this.entrySource,
    required this.onTap,
  });

  final SampleFilter filter;
  final InsightEntrySource? entrySource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final action = _followupAction(filter, source: entrySource);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAEAE5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0EC),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              action.icon,
              size: 18,
              color: action.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _followupEyebrow(entrySource),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: action.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5B5B5B),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(action.label),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateAction {
  const _EmptyStateAction({
    required this.label,
    required this.route,
  });

  final String label;
  final String route;
}

class _FollowupAction {
  const _FollowupAction({
    required this.title,
    required this.body,
    required this.label,
    required this.route,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String body;
  final String label;
  final String route;
  final IconData icon;
  final Color accentColor;
}

class _InsightEntrySourceCard extends StatelessWidget {
  const _InsightEntrySourceCard({
    required this.source,
    required this.filter,
  });

  final InsightEntrySource source;
  final SampleFilter filter;

  @override
  Widget build(BuildContext context) {
    final config = _entrySourceConfig(source, filter);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: config.badgeColor,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              config.icon,
              size: 18,
              color: config.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.eyebrow,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: config.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  config.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  config.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5B5B5B),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightEntrySourceConfig {
  const _InsightEntrySourceConfig({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.badgeColor,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color badgeColor;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.timeLabel,
    this.faded = false,
  });

  final String description;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String timeLabel;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.72 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (statusLabel == '真空专注' || statusLabel == '专注完成') ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.air_rounded,
                      size: 16,
                      color: Color(0xFF6E8FA3),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2D2D2D),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterContextCard extends StatelessWidget {
  const _FilterContextCard({
    required this.filter,
    this.weeklySummary,
    this.trendSummary,
  });

  final SampleFilter filter;
  final WeeklyReviewSummary? weeklySummary;
  final InsightTrendSummary? trendSummary;

  @override
  Widget build(BuildContext context) {
    final config = _filterContextConfig(filter, weeklySummary, trendSummary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: config.badgeColor,
              borderRadius: BorderRadius.circular(19),
            ),
            alignment: Alignment.center,
            child: Icon(
              config.icon,
              size: 18,
              color: config.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.eyebrow,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: config.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  config.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  config.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5B5B5B),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterContextConfig {
  const _FilterContextConfig({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.badgeColor,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color badgeColor;
}

class _WeeklyReviewCard extends StatelessWidget {
  const _WeeklyReviewCard({required this.summary});

  final WeeklyReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '本周复盘',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF819B8E),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Spacer(),
                Text(
                  '最近 7 天',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8E8E93),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              summary.summaryTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              summary.summaryBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5B5B5B),
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(label: '匹配', value: summary.matchCount.toString()),
                _StatPill(label: '部分偏离', value: summary.partialCount.toString()),
                _StatPill(label: '完全偏离', value: summary.fullDeviationCount.toString()),
                _StatPill(label: 'SOS', value: summary.sosCount.toString()),
                _StatPill(
                  label: '真空专注',
                  value: summary.vacuumFocusCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PositiveSignalCard extends StatelessWidget {
  const _PositiveSignalCard({required this.summary});

  final WeeklyReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '正向回流信号',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF6E8FA3),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Spacer(),
                Text(
                  '最近 7 天',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8E8E93),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              summary.positiveSignalTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              summary.positiveSignalBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5B5B5B),
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(label: '完全匹配', value: summary.matchCount.toString()),
                _StatPill(
                  label: '真空专注',
                  value: summary.vacuumFocusCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviationPatternCard extends StatelessWidget {
  const _DeviationPatternCard({required this.patterns});

  final List<DeviationPattern> patterns;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F5EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '高频偏离模式',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFC2A878),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Spacer(),
                Text(
                  '最近 7 天',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8E8E93),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              patterns.isEmpty
                  ? '最近 7 天还没有形成明显的偏离模式'
                  : '最近最常出现的拉扯，已经开始变得可识别',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              patterns.isEmpty
                  ? '继续记录就好，样本足够时这些模式会更清楚。'
                  : '不急着解决全部问题，先反复看见最常出现的那几种模式。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5B5B5B),
                    height: 1.6,
                  ),
            ),
            if (patterns.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final (index, pattern) in patterns.indexed) ...[
                if (index > 0) const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFCFA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEAEAE5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: pattern.sourceType == 'sos'
                              ? const Color(0xFFE8F0EC)
                              : const Color(0xFFF9F5EC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: pattern.sourceType == 'sos'
                                    ? const Color(0xFF819B8E)
                                    : const Color(0xFFC2A878),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pattern.label,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: const Color(0xFF2D2D2D),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pattern.summary,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF8E8E93),
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF5B5B5B),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TrendSummaryCard extends StatelessWidget {
  const _TrendSummaryCard({required this.summary});

  final InsightTrendSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '样本来源分布',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              summary.dominantLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5B5B5B),
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(
                  label: '每日偏离',
                  value: summary.dailyDeviationCount.toString(),
                ),
                _StatPill(label: 'SOS', value: summary.sosCount.toString()),
                _StatPill(
                  label: '首次重构',
                  value: summary.restructureCount.toString(),
                ),
                _StatPill(
                  label: '真空专注',
                  value: summary.vacuumFocusCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _defaultStatusLabel(String sourceType) {
  final copy = CopyStrategy.insights();
  switch (sourceType) {
    case 'sos':
      return copy.defaultStatusSos;
    case 'manual':
      return copy.defaultStatusManual;
    case 'vacuum_focus':
      return copy.defaultStatusVacuumFocus;
    default:
      return copy.defaultStatusGeneric;
  }
}

Color _statusColor(String statusTag, String sourceType) {
  if (sourceType == 'sos') {
    return const Color(0xFF819B8E);
  }

  if (sourceType == 'vacuum_focus') {
    return const Color(0xFF6E8FA3);
  }

  if (statusTag.contains('部分')) {
    return const Color(0xFFC2A878);
  }

  if (statusTag.contains('完全')) {
    return const Color(0xFF8E8E93);
  }

  return const Color(0xFF819B8E);
}

Color _statusBackground(String statusTag, String sourceType) {
  if (sourceType == 'sos') {
    return const Color(0xFFE8F0EC);
  }

  if (sourceType == 'vacuum_focus') {
    return const Color(0xFFEAF2F7);
  }

  if (statusTag.contains('部分')) {
    return const Color(0xFFF9F5EC);
  }

  if (statusTag.contains('完全')) {
    return const Color(0xFFF0F0F0);
  }

  return const Color(0xFFE8F0EC);
}

bool _showsWeeklyReview(SampleFilter filter) {
  return switch (filter) {
    SampleFilter.all || SampleFilter.restructure => true,
    _ => false,
  };
}

bool _showsPositiveSignal(SampleFilter filter) {
  return switch (filter) {
    SampleFilter.all || SampleFilter.vacuumFocus => true,
    _ => false,
  };
}

bool _showsDeviationPatterns(SampleFilter filter) {
  return switch (filter) {
    SampleFilter.all || SampleFilter.dailyDeviation || SampleFilter.sos => true,
    _ => false,
  };
}

bool _showsTrendSummary(SampleFilter filter) {
  return switch (filter) {
    SampleFilter.all || SampleFilter.restructure || SampleFilter.vacuumFocus =>
      true,
    _ => false,
  };
}

String _filterLeadText(SampleFilter filter) {
  return NeutralCopyEngine.insightsFilterLead(filter.queryValue);
}

_FilterContextConfig _filterContextConfig(
  SampleFilter filter,
  WeeklyReviewSummary? weeklySummary,
  InsightTrendSummary? trendSummary,
) {
  final copy = NeutralCopyEngine.insightsFilterContext(
    filterKey: filter.queryValue,
    partialCount: weeklySummary?.partialCount ?? 0,
    fullDeviationCount: weeklySummary?.fullDeviationCount ?? 0,
    sosCount: weeklySummary?.sosCount ?? 0,
    restructureCount: trendSummary?.restructureCount ?? 0,
    focusCount: weeklySummary?.vacuumFocusCount ?? 0,
  );
  switch (filter) {
    case SampleFilter.dailyDeviation:
      return _FilterContextConfig(
        eyebrow: copy.eyebrow,
        title: copy.title,
        body: copy.body,
        icon: Icons.adjust_rounded,
        accentColor: const Color(0xFFC2A878),
        backgroundColor: const Color(0xFFFCF8F1),
        borderColor: const Color(0xFFF0E5CF),
        badgeColor: const Color(0xFFF9F5EC),
      );
    case SampleFilter.sos:
      return _FilterContextConfig(
        eyebrow: copy.eyebrow,
        title: copy.title,
        body: copy.body,
        icon: Icons.monitor_heart_outlined,
        accentColor: const Color(0xFF819B8E),
        backgroundColor: const Color(0xFFF4FAF6),
        borderColor: const Color(0xFFDDECE3),
        badgeColor: const Color(0xFFE8F0EC),
      );
    case SampleFilter.restructure:
      return _FilterContextConfig(
        eyebrow: copy.eyebrow,
        title: copy.title,
        body: copy.body,
        icon: Icons.self_improvement_outlined,
        accentColor: const Color(0xFF819B8E),
        backgroundColor: const Color(0xFFF6FAF7),
        borderColor: const Color(0xFFDDECE3),
        badgeColor: const Color(0xFFE8F0EC),
      );
    case SampleFilter.vacuumFocus:
      return _FilterContextConfig(
        eyebrow: copy.eyebrow,
        title: copy.title,
        body: copy.body,
        icon: Icons.air_rounded,
        accentColor: const Color(0xFF6E8FA3),
        backgroundColor: const Color(0xFFF4F8FB),
        borderColor: const Color(0xFFDDEAF2),
        badgeColor: const Color(0xFFEAF2F7),
      );
    case SampleFilter.all:
      return _FilterContextConfig(
        eyebrow: copy.eyebrow,
        title: copy.title,
        body: copy.body,
        icon: Icons.library_books_outlined,
        accentColor: const Color(0xFF819B8E),
        backgroundColor: const Color(0xFFF6FAF7),
        borderColor: const Color(0xFFDDECE3),
        badgeColor: const Color(0xFFE8F0EC),
      );
  }
}

_EmptyStateAction _emptyStateAction(SampleFilter filter) {
  switch (filter) {
    case SampleFilter.all:
      return const _EmptyStateAction(
        label: '回首页继续最小动作',
        route: AppRoutes.home,
      );
    case SampleFilter.dailyDeviation:
      return const _EmptyStateAction(
        label: '回首页做今日校验',
        route: AppRoutes.dailyCheckin,
      );
    case SampleFilter.sos:
      return const _EmptyStateAction(
        label: '先进入一段真空专注',
        route: AppRoutes.vacuumFocus,
      );
    case SampleFilter.restructure:
      return const _EmptyStateAction(
        label: '回到 24h 重构',
        route: AppRoutes.restructureSetup,
      );
    case SampleFilter.vacuumFocus:
      return const _EmptyStateAction(
        label: '开始一段真空专注',
        route: AppRoutes.vacuumFocus,
      );
  }
}

_FollowupAction _followupAction(
  SampleFilter filter, {
  InsightEntrySource? source,
}) {
  final copy = NeutralCopyEngine.insightsFollowup(
    filterKey: filter.queryValue,
    sourceKey: source?.queryValue,
  );
  switch (filter) {
    case SampleFilter.all:
      return _FollowupAction(
        title: copy.title,
        body: copy.body,
        label: copy.label,
        route: AppRoutes.home,
        icon: Icons.home_outlined,
        accentColor: source == InsightEntrySource.positiveSignal
            ? const Color(0xFF6E8FA3)
            : const Color(0xFF819B8E),
      );
    case SampleFilter.dailyDeviation:
      return _FollowupAction(
        title: copy.title,
        body: copy.body,
        label: copy.label,
        route: AppRoutes.dailyCheckin,
        icon: Icons.check_circle_outline_rounded,
        accentColor: source == InsightEntrySource.homeSuggestion
            ? const Color(0xFFC2A878)
            : const Color(0xFFC2A878),
      );
    case SampleFilter.sos:
      return _FollowupAction(
        title: copy.title,
        body: copy.body,
        label: copy.label,
        route: AppRoutes.vacuumFocus,
        icon: Icons.air_rounded,
        accentColor: const Color(0xFF819B8E),
      );
    case SampleFilter.restructure:
      return _FollowupAction(
        title: copy.title,
        body: copy.body,
        label: copy.label,
        route: AppRoutes.restructureSetup,
        icon: Icons.self_improvement_outlined,
        accentColor: const Color(0xFF819B8E),
      );
    case SampleFilter.vacuumFocus:
      return _FollowupAction(
        title: copy.title,
        body: copy.body,
        label: copy.label,
        route: AppRoutes.home,
        icon: Icons.playlist_add_check_circle_rounded,
        accentColor: const Color(0xFF6E8FA3),
      );
  }
}

String _followupEyebrow(InsightEntrySource? source) {
  return NeutralCopyEngine.insightsFollowupEyebrow(source?.queryValue);
}

_InsightEntrySourceConfig _entrySourceConfig(
  InsightEntrySource source,
  SampleFilter filter,
) {
  final filterLabel = filter.label;
  final copy = NeutralCopyEngine.insightsEntrySource(
    sourceKey: source.queryValue,
    filterLabel: filterLabel,
  );

  switch (source) {
    case InsightEntrySource.homeArchive:
      return _InsightEntrySourceConfig(
        eyebrow: copy.eyebrow,
        title: copy.title,
        body: copy.body,
        icon: Icons.archive_outlined,
        accentColor: Color(0xFF819B8E),
        backgroundColor: Color(0xFFF6FAF7),
        borderColor: Color(0xFFDDECE3),
        badgeColor: Color(0xFFE8F0EC),
      );
    case InsightEntrySource.weeklySummary:
      return _InsightEntrySourceConfig(
        eyebrow: copy.eyebrow,
        title: copy.title,
        body: copy.body,
        icon: Icons.stacked_bar_chart_rounded,
        accentColor: const Color(0xFF819B8E),
        backgroundColor: const Color(0xFFF6FAF7),
        borderColor: const Color(0xFFDDECE3),
        badgeColor: const Color(0xFFE8F0EC),
      );
    case InsightEntrySource.positiveSignal:
      return _InsightEntrySourceConfig(
        eyebrow: copy.eyebrow,
        title: copy.title,
        body: copy.body,
        icon: Icons.air_rounded,
        accentColor: const Color(0xFF6E8FA3),
        backgroundColor: const Color(0xFFF4F8FB),
        borderColor: const Color(0xFFDDEAF2),
        badgeColor: const Color(0xFFEAF2F7),
      );
    case InsightEntrySource.homeSuggestion:
      return _InsightEntrySourceConfig(
        eyebrow: copy.eyebrow,
        title: copy.title,
        body: copy.body,
        icon: Icons.arrow_outward_rounded,
        accentColor: const Color(0xFF819B8E),
        backgroundColor: const Color(0xFFF6FAF7),
        borderColor: const Color(0xFFDDECE3),
        badgeColor: const Color(0xFFE8F0EC),
      );
  }
}

String _insightsLocation(
  SampleFilter filter, {
  InsightEntrySource? source,
}) {
  final queryParameters = <String, String>{};
  if (filter != SampleFilter.all) {
    queryParameters['filter'] = filter.queryValue;
  }
  if (source != null) {
    queryParameters['source'] = source.queryValue;
  }
  if (queryParameters.isEmpty) {
    return AppRoutes.insights;
  }

  return '${AppRoutes.insights}?${Uri(queryParameters: queryParameters).query}';
}

String _formatTimeLabel(DateTime createdAt) {
  final hourMinute = CopyStrategy.insightsHourMinute(createdAt);
  final now = DateTime.now();
  final difference = now.difference(createdAt);

  if (difference.inDays == 0) {
    return CopyStrategy.insightsTodayTime(hourMinute);
  }

  if (difference.inDays == 1) {
    return CopyStrategy.insightsYesterdayTime(hourMinute);
  }

  final month = createdAt.month.toString().padLeft(2, '0');
  final day = createdAt.day.toString().padLeft(2, '0');
  return CopyStrategy.insightsMonthDayTime('$month-$day', hourMinute);
}
