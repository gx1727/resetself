import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/deviation_pattern.dart';
import '../../../data/models/insight_trend_summary.dart';
import '../../../data/models/inertia_sample.dart';
import '../../../data/models/weekly_review_summary.dart';

enum SampleFilter {
  all('全部'),
  dailyDeviation('每日偏离'),
  sos('SOS'),
  restructure('首次重构');

  const SampleFilter(this.label);

  final String label;
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

  @override
  Widget build(BuildContext context) {
    final samplesAsync = ref.watch(recentSamplesProvider(_selectedFilter));
    final weeklyReviewAsync = ref.watch(weeklyReviewProvider);
    final topPatternsAsync = ref.watch(topDeviationPatternsProvider);
    final trendSummaryAsync = ref.watch(insightTrendSummaryProvider);

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
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      size: 28,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '惯性样本库',
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
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
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
                      weeklyReviewAsync.when(
                        data: (summary) => _WeeklyReviewCard(summary: summary),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      topPatternsAsync.when(
                        data: (patterns) => _DeviationPatternCard(patterns: patterns),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      trendSummaryAsync.when(
                        data: (summary) => _TrendSummaryCard(summary: summary),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '偏差=迭代数据，偏差≠失败。\n这里记录了最近 7 天被旧惯性拉扯的时刻。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8E8E93),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (samples.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _emptyStateText(_selectedFilter),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF8E8E93),
                                height: 1.7,
                              ),
                            ),
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
                                ? '系统记录了一次旧惯性波动。'
                                : sample.content,
                            faded: sample.sourceType == 'daily_checkin',
                          ),
                        ],
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          '只展示最近 7 天的样本数据',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0x998E8E93),
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading: () => Center(
                    child: Text(
                      '样本库正在慢慢浮现...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0x998E8E93),
                      ),
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      '样本库暂时没有展开，但你的本地数据仍是安全的。',
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
      return '这是一张白纸，等待你第一次看见旧惯性出现的样子。';
    case SampleFilter.dailyDeviation:
      return '最近 7 天还没有记录到每日偏离，新的惯性正在慢慢成形。';
    case SampleFilter.sos:
      return '最近 7 天你还没有触发 SOS，这也是一种稳定的证据。';
    case SampleFilter.restructure:
      return '这一期的身份重构记录还没有沉淀到这里。';
  }
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
                  ? '继续记录就好，系统会在样本足够时把旧惯性慢慢显影出来。'
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _defaultStatusLabel(String sourceType) {
  switch (sourceType) {
    case 'sos':
      return 'SOS急救';
    case 'manual':
      return '首次重构';
    default:
      return '惯性样本';
  }
}

Color _statusColor(String statusTag, String sourceType) {
  if (sourceType == 'sos') {
    return const Color(0xFF819B8E);
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

  if (statusTag.contains('部分')) {
    return const Color(0xFFF9F5EC);
  }

  if (statusTag.contains('完全')) {
    return const Color(0xFFF0F0F0);
  }

  return const Color(0xFFE8F0EC);
}

String _formatTimeLabel(DateTime createdAt) {
  final now = DateTime.now();
  final difference = now.difference(createdAt);

  if (difference.inDays == 0) {
    return '今天 ${_formatHourMinute(createdAt)}';
  }

  if (difference.inDays == 1) {
    return '昨天 ${_formatHourMinute(createdAt)}';
  }

  final month = createdAt.month.toString().padLeft(2, '0');
  final day = createdAt.day.toString().padLeft(2, '0');
  return '$month-$day ${_formatHourMinute(createdAt)}';
}

String _formatHourMinute(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
