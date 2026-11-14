import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../core/widgets/draft_navigation_guard.dart';
import '../../../core/widgets/draft_save_controller.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/morning_question.dart';
import '../../../data/models/morning_archive.dart';

/// 晨间「心理挖掘」：完整引导原文第一部分的问题。
///
/// 这一页保存的是「探索原稿」，与晚间综合后的结论分开存储。
/// 原文建议留出 15–30 分钟，一次坐下来回答；答不出可以之后再回来补充。
class RestructureMorningPage extends ConsumerStatefulWidget {
  const RestructureMorningPage({super.key});

  @override
  ConsumerState<RestructureMorningPage> createState() =>
      _RestructureMorningPageState();
}

class _RestructureMorningPageState
    extends ConsumerState<RestructureMorningPage> {
  final Map<String, TextEditingController> _controllers = {
    for (final question in MorningQuestion.all)
      question.key: TextEditingController(),
  };
  final _exitKey = GlobalKey<DraftNavigationGuardState>();
  late final DraftSaveController<MorningDraftSnapshot> _saver;
  Set<String> _reviewKeys = {};
  bool _loadFailed = false;

  bool _isLoading = true;
  bool _isFinishing = false;
  int _answeredCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final repository = ref.read(userProfileRepositoryProvider);
    _saver = DraftSaveController(
      write: (snapshot) => repository.saveMorningAnswers(
        snapshot.answers,
        reviewKeys: snapshot.reviewKeys,
      ),
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    unawaited(_loadSavedAnswers());
  }

  @override
  void dispose() {
    _saver.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedAnswers() async {
    try {
      final answers = await ref
          .read(userProfileRepositoryProvider)
          .getMorningAnswers();
      final reviewKeys = await ref
          .read(userProfileRepositoryProvider)
          .getMorningReviewKeys();

      if (!mounted) return;
      for (final entry in answers.entries) {
        final controller = _controllers[entry.key];
        if (controller != null) {
          controller.text = entry.value;
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _reviewKeys = reviewKeys;
        _loadFailed = false;
        _errorMessage = null;
        _answeredCount = _countAnswered();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadFailed = true;
        _errorMessage = '晨间原稿读取失败。请重试取回，避免覆盖已有内容。';
      });
    }
  }

  int _countAnswered() {
    return _controllers.values
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
  }

  void _onChanged(String key, String value) {
    setState(() {
      _answeredCount = _countAnswered();
    });

    _saveSnapshot();
  }

  void _saveSnapshot() {
    _saver.update(
      MorningDraftSnapshot({
        for (final entry in _controllers.entries) entry.key: entry.value.text,
      }, _reviewKeys),
    );
  }

  Future<bool> _flushAll() => _saver.flush();

  Future<void> _handleFinish() async {
    if (_isFinishing) {
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    final saved = await _flushAll();

    if (!mounted) {
      return;
    }

    setState(() {
      _isFinishing = false;
    });

    if (saved) await _showNextPhaseSheet();
  }

  Future<void> _showNextPhaseSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF7F7F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '晨间探索原稿已保存',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '接下来是白天：用几次短暂停顿，观察自己在真实生活里怎样行动；\n'
                  '晚上再回到综合，把今天的观察变成方向。',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B6B6B),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.daytimeInterrupt);
                  },
                  child: const Text('进入日间打断（白天观察）'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.restructureSetup);
                  },
                  child: const Text('直接进入晚间综合'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('先停在这里，稍后继续'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraftNavigationGuard(
      key: _exitKey,
      save: _flushAll,
      ready: !_isLoading && !_loadFailed,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F5),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _exitKey.currentState?.leave(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        size: 28,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '已回答 $_answeredCount / ${MorningQuestion.all.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF8E8E93),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isFinishing
                          ? null
                          : () => _exitKey.currentState?.leave(),
                      child: const Text('稍后继续'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Text(
                          '正在取回你上次的晨间思绪...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF8E8E93)),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        children: [
                          _buildIntroCard(context),
                          const SizedBox(height: 20),
                          for (final question in MorningQuestion.all) ...[
                            _buildQuestionCard(context, question),
                            const SizedBox(height: 18),
                          ],
                        ],
                      ),
              ),
              if (_errorMessage != null || _saver.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage ?? '原稿未保存成功，内容仍在页面里，请重试。',
                    style: const TextStyle(color: Color(0xFF8E8E93)),
                  ),
                ),
              if (_loadFailed || _saver.error != null)
                TextButton(
                  onPressed: _loadFailed ? _loadSavedAnswers : _flushAll,
                  child: const Text('重试'),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FilledButton(
                    onPressed: _isLoading || _loadFailed || _isFinishing
                        ? null
                        : _handleFinish,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isFinishing ? '正在保存...' : '完成晨间挖掘'),
                        const SizedBox(width: 8),
                        if (_isFinishing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
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

  Widget _buildIntroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '晨间 · 心理挖掘',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF819B8E),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '这些问题是用来帮你产生答案的，不是让你直接给出结论。\n'
            '建议留出 15–30 分钟，一次坐下来回答；答不出可以先跳过，之后再回来补充。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B6B6B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text('先写下你的解释。白天可以用实际发生的事情再核对它。'),
          if (_saver.isDirty || _saver.isSaving) ...[
            const SizedBox(height: 8),
            Text(_saver.isSaving ? '正在保存原稿…' : '有待保存的改动'),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, MorningQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${question.order}.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF819B8E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question.question,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2D2D2D),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilterChip(
          key: ValueKey('review-${question.key}'),
          label: const Text('待回看'),
          selected: _reviewKeys.contains(question.key),
          onSelected: _loadFailed || _isFinishing
              ? null
              : (selected) {
                  setState(() {
                    if (selected) {
                      _reviewKeys.add(question.key);
                    } else {
                      _reviewKeys.remove(question.key);
                    }
                  });
                  _saveSnapshot();
                },
        ),
        TextField(
          enabled: !_loadFailed && !_isFinishing,
          controller: _controllers[question.key],
          maxLines: 5,
          minLines: 3,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF2D2D2D),
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: question.hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0x668E8E93),
              height: 1.6,
            ),
          ),
          onChanged: (value) => _onChanged(question.key, value),
        ),
      ],
    );
  }
}
