import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/morning_archive.dart';
import 'exploration_review_sheet.dart';
import 'restructure_restart_sheet.dart';

Future<void> showMorningHistory(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _MorningHistorySheet(),
    );

class _MorningHistorySheet extends ConsumerStatefulWidget {
  const _MorningHistorySheet();
  @override
  ConsumerState<_MorningHistorySheet> createState() => _MorningHistoryState();
}

class _MorningHistoryState extends ConsumerState<_MorningHistorySheet> {
  List<MorningArchive> _archives = [];
  bool _loading = true;
  bool _failed = false;
  bool _restoring = false;
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
      final archives = await ref
          .read(userProfileRepositoryProvider)
          .getMorningArchives();
      if (mounted) {
        setState(() {
          _archives = archives;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _restore(MorningArchive archive) async {
    if (_restoring ||
        await confirmMorningReplacement(context, restoring: true) != true ||
        !mounted) {
      return;
    }
    setState(() => _restoring = true);
    try {
      await ref
          .read(userProfileRepositoryProvider)
          .archiveCurrentMorningAndStartNew(restoreArchiveId: archive.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('原稿已恢复，可继续晨间探索。')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _restoring = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('恢复失败，当前原稿和草稿仍保留，请重试。')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_restoring,
    child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Text('晨间原稿归档', style: Theme.of(context).textTheme.titleLarge),
          const Text('每次归档独立保留原文和标记；可以回看相关日期的观察，也可以恢复后继续写。'),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_failed)
            TextButton(onPressed: _load, child: const Text('归档读取失败，点此重试'))
          else if (_archives.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('还没有归档的晨稿。开始新探索时可保留当前稿。'),
            )
          else
            for (final archive in _archives)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '原稿 #${archive.id} · ${formatObservationTime(archive.archivedAt)}',
                      ),
                      Text(
                        '${archive.answers.length} 个回答 · ${archive.reviewKeys.length} 个待回看问题',
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: _restoring
                                ? null
                                : () => showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    showDragHandle: true,
                                    builder: (_) => ExplorationReviewSheet(
                                      archive: archive,
                                      includeObservations: true,
                                      onEditMorning: () {},
                                      onAddObservation: () {},
                                    ),
                                  ),
                            child: const Text('查看原稿与观察'),
                          ),
                          TextButton(
                            onPressed: _restoring
                                ? null
                                : () => _restore(archive),
                            child: const Text('恢复为当前稿'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
