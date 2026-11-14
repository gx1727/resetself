import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/inertia_sample.dart';
import '../../../data/models/morning_question.dart';
import '../../../data/models/morning_archive.dart';

Future<void> showExplorationReview(
  BuildContext context, {
  bool includeObservations = true,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => ExplorationReviewSheet(
    includeObservations: includeObservations,
    onEditMorning: () {
      Navigator.of(context).pop();
      context.push(AppRoutes.restructureMorning);
    },
    onAddObservation: () {
      Navigator.of(context).pop();
      context.push(AppRoutes.daytimeInterrupt);
    },
  ),
);

class ExplorationReviewSheet extends ConsumerStatefulWidget {
  const ExplorationReviewSheet({
    required this.includeObservations,
    required this.onEditMorning,
    required this.onAddObservation,
    super.key,
    this.archive,
  });

  final bool includeObservations;
  final VoidCallback onEditMorning;
  final VoidCallback onAddObservation;
  final MorningArchive? archive;

  @override
  ConsumerState<ExplorationReviewSheet> createState() =>
      _ExplorationReviewSheetState();
}

class _ExplorationReviewSheetState
    extends ConsumerState<ExplorationReviewSheet> {
  DateTimeRange? _range;
  Map<String, String> _answers = {};
  Set<String> _reviewKeys = {};
  List<InertiaSample> _observations = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final repository = ref.read(userProfileRepositoryProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_range == null) {
        final started =
            widget.archive?.startedAt ??
            widget.archive?.archivedAt ??
            await repository.getMorningExplorationStartedAt();
        final local = started?.toLocal() ?? today;
        final start = DateTime(local.year, local.month, local.day);
        final archivedDay = widget.archive == null
            ? today
            : DateUtils.dateOnly(widget.archive!.archivedAt.toLocal());
        final end = archivedDay.isAfter(today) ? today : archivedDay;
        _range = DateTimeRange(
          start: start.isAfter(end) ? end : start,
          end: end,
        );
      }
      final answers =
          widget.archive?.answers ?? await repository.getMorningAnswers();
      final reviewKeys =
          widget.archive?.reviewKeys ?? await repository.getMorningReviewKeys();
      final observations = widget.includeObservations
          ? await repository.getInterruptReflections(
              start: _range!.start,
              end: _range!.end,
            )
          : <InertiaSample>[];
      if (!mounted) return;
      setState(() {
        _answers = answers;
        _reviewKeys = reviewKeys;
        _observations = observations;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _selectRange() async {
    final now = DateTime.now();
    final first = _range!.start.isBefore(DateTime(2000))
        ? _range!.start
        : DateTime(2000);
    final range = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
      helpText: '选择观察日期范围',
    );
    if (!mounted || range == null) return;
    _range = range;
    await _load();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .75,
    maxChildSize: .95,
    builder: (context, scrollController) => ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text(
          widget.includeObservations ? '晚间综合前的回顾' : '回看晨间原稿',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text('回看自己写下的解释。哪些观察支持它，哪些让你想重新考虑？'),
        if (_range != null && widget.includeObservations)
          TextButton.icon(
            onPressed: _loading ? null : _selectRange,
            icon: const Icon(Icons.date_range),
            label: Text('观察范围：${_day(_range!.start)}—${_day(_range!.end)}'),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_failed)
          TextButton(onPressed: _load, child: const Text('材料读取失败，点此重试'))
        else ...[
          const SizedBox(height: 16),
          Text('晨间原稿', style: Theme.of(context).textTheme.titleMedium),
          Text(
            widget.archive == null
                ? '当前保存的一份探索原稿；修改会更新这份原稿。'
                : '历史归档 #${widget.archive!.id}；下面的日期范围可调整，观察与原稿的关系由你核对。',
          ),
          const SizedBox(height: 8),
          if (_answers.values.every((value) => value.trim().isEmpty))
            const Text('尚无晨间原稿。可以补充，也可以稍后回来。'),
          for (final question in MorningQuestion.all)
            if ((_answers[question.key] ?? '').trim().isNotEmpty ||
                _reviewKeys.contains(question.key))
              _MaterialEntry(
                label:
                    '${_reviewKeys.contains(question.key) ? '待回看 · ' : ''}${question.order}. ${question.question}',
                value: (_answers[question.key] ?? '').trim().isEmpty
                    ? '尚未回答，可以稍后再想。'
                    : _answers[question.key]!,
              ),
          if (widget.archive == null)
            OutlinedButton(
              onPressed: widget.onEditMorning,
              child: const Text('补充／修改晨间原稿'),
            ),
          if (widget.includeObservations) ...[
            const SizedBox(height: 20),
            Text('日间观察', style: Theme.of(context).textTheme.titleMedium),
            const Text('以下是所选日期范围的记录，可自行核对与当前探索的关系。'),
            if (_observations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('这段时间尚无日间记录。可调整范围，或凭实际经历继续综合。'),
              ),
            for (final observation in _observations)
              _MaterialEntry(
                label:
                    '${formatObservationTime(observation.createdAt)}'
                    ' · ${observation.statusTag}\n'
                    '${observation.promptSnapshot ?? '未记录问题'}',
                value: observation.content,
              ),
            if (widget.archive == null)
              OutlinedButton(
                onPressed: widget.onAddObservation,
                child: const Text('补记一次日间观察'),
              ),
          ],
        ],
      ],
    ),
  );
}

String _day(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String formatObservationTime(DateTime value) {
  final local = value.toLocal();
  return '${_day(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class _MaterialEntry extends StatelessWidget {
  const _MaterialEntry({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(value),
        ],
      ),
    ),
  );
}
