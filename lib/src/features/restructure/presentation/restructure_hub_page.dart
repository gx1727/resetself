import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/app_controller.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/identity_anchor.dart';
import '../../../data/models/restructure_archive_record.dart';
import '../../../data/models/yearly_archive_record.dart';
import '../../../data/models/yearly_report_summary.dart';
import 'restructure_restart_sheet.dart';

final restructureArchiveProvider =
    FutureProvider.autoDispose<List<RestructureArchiveRecord>>((ref) {
  return ref.watch(userProfileRepositoryProvider).getRestructureArchiveRecords();
});

final yearlyArchiveProvider =
    FutureProvider.autoDispose<List<YearlyArchiveRecord>>((ref) {
  return ref.watch(userProfileRepositoryProvider).getYearlyArchiveRecords();
});

final yearlyReportProvider =
    FutureProvider.autoDispose<List<YearlyReportSummary>>((ref) {
  return ref.watch(userProfileRepositoryProvider).getYearlyReportSummaries();
});

class RestructureHubPage extends ConsumerWidget {
  const RestructureHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appControllerProvider).profile;
    final archiveAsync = ref.watch(restructureArchiveProvider);
    final yearlyArchiveAsync = ref.watch(yearlyArchiveProvider);
    final yearlyReportAsync = ref.watch(yearlyReportProvider);
    final anchorsAsync = ref.watch(activeIdentityAnchorsProvider);
    final currentAnchorAsync = ref.watch(currentIdentityAnchorProvider);
    final copy = NeutralCopyEngine.restructureArchivePage();

    return AppPageScaffold(
      title: copy.title,
      subtitle: copy.subtitle,
      child: archiveAsync.when(
        data: (records) => yearlyArchiveAsync.when(
          data: (yearlyArchives) => yearlyReportAsync.when(
            data: (yearlyReports) {
            final latestRecord = records.where((record) => record.isLatest).firstOrNull;
            final historyRecords = records.where((record) => !record.isLatest).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CurrentIdentityCard(
                  identityText: profile.identityText,
                  minAction: profile.todayMinAction,
                  latestRecord: latestRecord,
                  onTapRefresh: () => openRestructureRestartFlow(context, ref),
                ),
                if (latestRecord != null) ...[
                  const SizedBox(height: 16),
                  _GameLoopCard(record: latestRecord),
                ],
                const SizedBox(height: 16),
                anchorsAsync.when(
                  data: (anchors) => currentAnchorAsync.when(
                    data: (current) => _IdentityLibraryCard(
                      anchors: anchors,
                      currentId: current?.id,
                      onSelect: (anchor) async {
                        final anchorId = anchor.id;
                        if (anchorId == null) {
                          return;
                        }
                        final repository =
                            ref.read(userProfileRepositoryProvider);
                        await repository.setCurrentIdentityAnchor(anchorId);
                        await repository.syncIdentityTextFromCurrentAnchor();
                        ref.invalidate(activeIdentityAnchorsProvider);
                        ref.invalidate(currentIdentityAnchorProvider);
                        await ref.read(appControllerProvider).reloadProfile();
                      },
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                if (historyRecords.isEmpty)
                  const _ArchiveEmptyCard()
                else
                  ...[
                    Text(
                      copy.historyTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final record in historyRecords) ...[
                      _ArchiveRecordCard(record: record),
                      const SizedBox(height: 12),
                    ],
                  ],
                const SizedBox(height: 8),
                if (yearlyArchives.isEmpty)
                  const _YearlyArchiveEmptyCard()
                else
                  ...[
                    if (yearlyReports.isNotEmpty) ...[
                      Text(
                        copy.yearlyReportTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final report in yearlyReports) ...[
                        _YearlyReportCard(report: report),
                        const SizedBox(height: 12),
                      ],
                    ],
                    Text(
                      copy.yearlyArchiveTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final archive in yearlyArchives) ...[
                      _YearlyArchiveCard(archive: archive),
                      const SizedBox(height: 12),
                    ],
                  ],
              ],
            );
            },
            loading: () => Text(
              copy.yearlyReportLoading,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E93),
              ),
            ),
            error: (error, stackTrace) => Text(
              copy.yearlyReportError,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E93),
                height: 1.6,
              ),
            ),
          ),
          loading: () => Text(
            copy.yearlyLoading,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8E8E93),
            ),
          ),
          error: (error, stackTrace) => Text(
            copy.yearlyError,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8E8E93),
              height: 1.6,
            ),
          ),
        ),
        loading: () => Text(
          copy.historyLoading,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF8E8E93),
          ),
        ),
        error: (error, stackTrace) => Text(
          copy.historyError,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF8E8E93),
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class _CurrentIdentityCard extends StatelessWidget {
  const _CurrentIdentityCard({
    required this.identityText,
    required this.minAction,
    required this.latestRecord,
    required this.onTapRefresh,
  });

  final String identityText;
  final String minAction;
  final RestructureArchiveRecord? latestRecord;
  final VoidCallback onTapRefresh;

  @override
  Widget build(BuildContext context) {
    final copy = NeutralCopyEngine.restructureArchivePage();
    final displayedIdentity = identityText.trim().isEmpty
        ? '我是一个看重长远价值的人'
        : identityText.trim();
    final displayedAction = minAction.trim().isEmpty ? '清理办公桌面 5 分钟' : minAction.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0EC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              copy.currentIdentityBadge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF819B8E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayedIdentity,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF2D2D2D),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${copy.minActionLabel}：$displayedAction',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5B5B5B),
              height: 1.6,
            ),
          ),
          if (latestRecord != null) ...[
            const SizedBox(height: 14),
            Text(
              _latestRecordSummary(latestRecord!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8E8E93),
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onTapRefresh,
            child: Text(copy.refreshIdentityLabel),
          ),
        ],
      ),
    );
  }
}

class _GameLoopCard extends StatelessWidget {
  const _GameLoopCard({required this.record});

  final RestructureArchiveRecord record;

  @override
  Widget build(BuildContext context) {
    final archiveCopy = CopyStrategy.archive();
    final pageCopy = NeutralCopyEngine.restructureArchivePage();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            archiveCopy.gameSectionTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          _ArchiveField(
            label: archiveCopy.fieldAntiVision,
            value: record.antiVision,
          ),
          const SizedBox(height: 10),
          _ArchiveField(
            label: archiveCopy.fieldVision,
            value: record.visionText,
          ),
          const SizedBox(height: 10),
          _ArchiveField(
            label: archiveCopy.fieldYearGoal,
            value: record.yearGoal,
          ),
          const SizedBox(height: 10),
          _ArchiveField(
            label: archiveCopy.fieldMonthProject,
            value: record.monthProject,
          ),
          const SizedBox(height: 10),
          _ArchiveField(
            label: pageCopy.minActionLabel,
            value: record.minActionDraft,
          ),
          const SizedBox(height: 10),
          _ArchiveField(
            label: archiveCopy.fieldConstraints,
            value: record.constraints,
          ),
        ],
      ),
    );
  }
}

class _IdentityLibraryCard extends StatelessWidget {
  const _IdentityLibraryCard({
    required this.anchors,
    required this.currentId,
    required this.onSelect,
  });

  final List<IdentityAnchor> anchors;
  final int? currentId;
  final ValueChanged<IdentityAnchor> onSelect;

  @override
  Widget build(BuildContext context) {
    if (anchors.isEmpty) {
      return const SizedBox.shrink();
    }

    final archiveCopy = CopyStrategy.archive();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            archiveCopy.anchorSectionTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 14),
          for (final anchor in anchors) ...[
            GestureDetector(
              onTap: () => onSelect(anchor),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: anchor.id == currentId
                      ? const Color(0xFFF4FAF6)
                      : const Color(0xFFFCFCFA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: anchor.id == currentId
                        ? const Color(0xFFC7DED2)
                        : const Color(0xFFEAEAE5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        anchor.anchorText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2D2D2D),
                          height: 1.5,
                          fontWeight: anchor.id == currentId
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (anchor.id == currentId) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.radio_button_checked,
                        size: 18,
                        color: Color(0xFF819B8E),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchiveEmptyCard extends StatelessWidget {
  const _ArchiveEmptyCard();

  @override
  Widget build(BuildContext context) {
    final copy = NeutralCopyEngine.restructureArchivePage();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.historyEmptyTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF2D2D2D),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.historyEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E93),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearlyArchiveEmptyCard extends StatelessWidget {
  const _YearlyArchiveEmptyCard();

  @override
  Widget build(BuildContext context) {
    final copy = NeutralCopyEngine.restructureArchivePage();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.yearlyEmptyTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF2D2D2D),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.yearlyEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E93),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveRecordCard extends StatelessWidget {
  const _ArchiveRecordCard({required this.record});

  final RestructureArchiveRecord record;

  @override
  Widget build(BuildContext context) {
    final copy = NeutralCopyEngine.restructureArchivePage();
    final archiveCopy = CopyStrategy.archive();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _archiveRecordTitle(record),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF6E8FA3),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatRecordTime(record),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ArchiveField(label: archiveCopy.fieldIdentity, value: record.identityDraft),
            const SizedBox(height: 10),
            _ArchiveField(label: copy.minActionLabel, value: record.minActionDraft),
            if (record.beliefDraft.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ArchiveField(label: archiveCopy.fieldBelief, value: record.beliefDraft),
            ],
            if (record.fearContent.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ArchiveField(label: archiveCopy.fieldFear, value: record.fearContent),
            ],
            if (record.antiVision.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ArchiveField(label: archiveCopy.fieldAntiVision, value: record.antiVision),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArchiveField extends StatelessWidget {
  const _ArchiveField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty ? NeutralCopyEngine.archiveFieldEmpty() : value.trim(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF2D2D2D),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _YearlyArchiveCard extends StatelessWidget {
  const _YearlyArchiveCard({required this.archive});

  final YearlyArchiveRecord archive;

  @override
  Widget build(BuildContext context) {
    final copy = NeutralCopyEngine.restructureArchivePage();
    final archiveCopy = CopyStrategy.archive();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0EC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${archive.archiveYear} 年',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF819B8E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatYearlyArchiveTime(archive),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ArchiveField(label: archiveCopy.fieldYearlyIdentity, value: archive.identitySnapshot),
            const SizedBox(height: 10),
            _ArchiveField(label: copy.yearlyBeliefLabel, value: archive.beliefSnapshot),
            const SizedBox(height: 10),
            _ArchiveField(label: copy.yearlySampleCountLabel, value: '${archive.sampleCount} 条'),
            const SizedBox(height: 10),
            _ArchiveField(label: copy.yearlyStabilityLabel, value: archive.checkinStability),
          ],
        ),
      ),
    );
  }
}

class _YearlyReportCard extends StatelessWidget {
  const _YearlyReportCard({required this.report});

  final YearlyReportSummary report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDECE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0EC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${report.archiveYear} 年变化报告',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF819B8E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF2D2D2D),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5B5B5B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.highlight,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF819B8E),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

String _latestRecordSummary(RestructureArchiveRecord record) {
  final year = record.createYear?.toString() ?? '本期';
  return NeutralCopyEngine.restructureLatestRecordSummary(
    periodLabel: year,
    minAction: record.minActionDraft,
  );
}

String _archiveRecordTitle(RestructureArchiveRecord record) {
  return NeutralCopyEngine.restructureArchiveRecordTitle(
    record.createYear?.toString(),
  );
}

String _formatRecordTime(RestructureArchiveRecord record) {
  return NeutralCopyEngine.restructureArchiveRecordTime(record.createdAt);
}

String _formatYearlyArchiveTime(YearlyArchiveRecord archive) {
  return NeutralCopyEngine.restructureYearlyArchiveTime(archive.createdAt);
}
