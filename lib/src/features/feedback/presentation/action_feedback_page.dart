import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../core/widgets/direction_summary.dart';
import '../../../core/widgets/min_action_editor.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/action_feedback.dart';
import '../application/action_feedback_providers.dart';
import '../../home/application/home_providers.dart';

/// 行动反馈：用产品记录模板支持原文 V 的反馈循环。
///
/// 模板：「尝试了什么 → 发生了什么 → 得到什么认识 → 下一次调整什么」。
/// 页面只负责记录与回看，不生成分数或与他人比较。
class ActionFeedbackPage extends ConsumerStatefulWidget {
  const ActionFeedbackPage({super.key});

  @override
  ConsumerState<ActionFeedbackPage> createState() => _ActionFeedbackPageState();
}

class _ActionFeedbackPageState extends ConsumerState<ActionFeedbackPage> {
  final TextEditingController _attemptedController = TextEditingController();
  final TextEditingController _happenedController = TextEditingController();
  final TextEditingController _insightController = TextEditingController();
  final TextEditingController _adjustmentController = TextEditingController();

  bool _isSaving = false;
  bool _justSaved = false;
  String? _errorMessage;
  String? _referenceSnapshot;
  bool _referenceCaptured = false;
  String _lastAdjustment = '';

  @override
  void dispose() {
    _attemptedController.dispose();
    _happenedController.dispose();
    _insightController.dispose();
    _adjustmentController.dispose();
    super.dispose();
  }

  bool get _hasAnyInput =>
      _attemptedController.text.trim().isNotEmpty ||
      _happenedController.text.trim().isNotEmpty ||
      _insightController.text.trim().isNotEmpty ||
      _adjustmentController.text.trim().isNotEmpty;

  Future<void> _handleSave() async {
    if (_isSaving) {
      return;
    }

    final copy = CopyStrategy.actionFeedback();

    if (!_hasAnyInput) {
      setState(() {
        _errorMessage = copy.emptyHint;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(userProfileRepositoryProvider)
          .saveActionFeedback(
            attempted: _attemptedController.text,
            happened: _happenedController.text,
            insight: _insightController.text,
            adjustment: _adjustmentController.text,
            directionSnapshot: _referenceSnapshot,
          );

      ref.invalidate(recentActionFeedbacksProvider);
      ref.invalidate(latestActionFeedbackProvider);

      if (!mounted) {
        return;
      }

      _lastAdjustment = _adjustmentController.text.trim();
      _attemptedController.clear();
      _happenedController.clear();
      _insightController.clear();
      _adjustmentController.clear();
      setState(() {
        _justSaved = true;
        _referenceCaptured = false;
        _referenceSnapshot = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '这次反馈没有记下来，你可以再点一次。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _handleFieldChanged(String _) {
    setState(() {
      if (!_referenceCaptured && _hasAnyInput) {
        final record = ref.read(latestRestructureRecordProvider).valueOrNull;
        _referenceSnapshot = record == null
            ? null
            : directionSnapshot(
                record,
                minAction: ref
                    .read(appControllerProvider)
                    .profile
                    .todayMinAction,
              );
        _referenceCaptured = true;
      }
      _justSaved = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = CopyStrategy.actionFeedback();
    final feedbackAsync = ref.watch(recentActionFeedbacksProvider);
    final records = feedbackAsync.valueOrNull ?? const <ActionFeedback>[];
    final directionAsync = ref.watch(latestRestructureRecordProvider);

    return AppPageScaffold(
      title: copy.title,
      subtitle: copy.subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_referenceCaptured)
            ExpansionTile(
              title: const Text('这次记录参考的方向'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _referenceSnapshot ?? '开始记录时没有可用方向。仍可保存自己的尝试与观察。',
                  ),
                ),
              ],
            )
          else if (directionAsync.valueOrNull != null)
            DirectionSummary(record: directionAsync.valueOrNull!, title: '当前方向')
          else if (directionAsync.hasError)
            TextButton(
              onPressed: () => ref.invalidate(latestRestructureRecordProvider),
              child: const Text('方向读取失败，点此重试；仍可记录反馈'),
            )
          else
            const Text('可以先记录尝试与观察，方向也可以稍后建立。'),
          const SizedBox(height: 12),
          _FeedbackFormCard(
            copy: copy,
            attemptedController: _attemptedController,
            happenedController: _happenedController,
            insightController: _insightController,
            adjustmentController: _adjustmentController,
            isSaving: _isSaving,
            canSave: _hasAnyInput,
            justSaved: _justSaved,
            errorMessage: _errorMessage,
            onChanged: _handleFieldChanged,
            onSave: _handleSave,
          ),
          if (_justSaved) ...[
            if (_lastAdjustment.isNotEmpty) Text('下一次调整：$_lastAdjustment'),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('回到首页／修改最小行动'),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.restructureHub),
                  child: const Text('查看／修改方向'),
                ),
                TextButton(
                  onPressed: () => showMinActionEditor(context),
                  child: const Text('修改最小启动行动'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text(
            copy.historyTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),
          if (feedbackAsync.hasError)
            TextButton(
              onPressed: () => ref.invalidate(recentActionFeedbacksProvider),
              child: const Text('反馈记录读取失败，点此重试'),
            )
          else if (feedbackAsync.isLoading)
            const Text('正在读取反馈记录…')
          else if (records.isEmpty)
            Text(
              copy.historyEmpty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E93),
                height: 1.6,
              ),
            )
          else
            for (final record in records) ...[
              _FeedbackRecordCard(record: record, copy: copy),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _FeedbackFormCard extends StatelessWidget {
  const _FeedbackFormCard({
    required this.copy,
    required this.attemptedController,
    required this.happenedController,
    required this.insightController,
    required this.adjustmentController,
    required this.isSaving,
    required this.canSave,
    required this.justSaved,
    required this.errorMessage,
    required this.onChanged,
    required this.onSave,
  });

  final ActionFeedbackCopy copy;
  final TextEditingController attemptedController;
  final TextEditingController happenedController;
  final TextEditingController insightController;
  final TextEditingController adjustmentController;
  final bool isSaving;
  final bool canSave;
  final bool justSaved;
  final String? errorMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
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
          _FeedbackField(
            label: copy.attemptedLabel,
            hint: copy.attemptedHint,
            controller: attemptedController,
            onChanged: onChanged,
            enabled: !isSaving,
          ),
          const SizedBox(height: 16),
          _FeedbackField(
            label: copy.happenedLabel,
            hint: copy.happenedHint,
            controller: happenedController,
            onChanged: onChanged,
            enabled: !isSaving,
          ),
          const SizedBox(height: 16),
          _FeedbackField(
            label: copy.insightLabel,
            hint: copy.insightHint,
            controller: insightController,
            onChanged: onChanged,
            enabled: !isSaving,
          ),
          const SizedBox(height: 16),
          _FeedbackField(
            label: copy.adjustmentLabel,
            hint: copy.adjustmentHint,
            controller: adjustmentController,
            onChanged: onChanged,
            enabled: !isSaving,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (isSaving || !canSave) ? null : onSave,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(copy.saveLabel),
                  if (isSaving) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (justSaved) ...[
            const SizedBox(height: 12),
            _FeedbackNote(
              title: copy.savedTitle,
              body: copy.savedBody,
              color: const Color(0xFF819B8E),
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: const TextStyle(color: Color(0xFF8E8E93)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackField extends StatelessWidget {
  const _FeedbackField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: const Color(0xFF8E8E93)),
        ),
        const SizedBox(height: 8),
        TextField(
          enabled: enabled,
          controller: controller,
          minLines: 2,
          maxLines: 4,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF2D2D2D),
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0x668E8E93),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackNote extends StatelessWidget {
  const _FeedbackNote({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5B5B5B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackRecordCard extends StatelessWidget {
  const _FeedbackRecordCard({required this.record, required this.copy});

  final ActionFeedback record;
  final ActionFeedbackCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEAE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatFeedbackTime(record.createdAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8E8E93)),
          ),
          ExpansionTile(
            title: const Text('记录时参考的方向'),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(record.directionSnapshot ?? '这条记录未保存方向上下文。'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FeedbackRecordRow(
            label: copy.attemptedLabel,
            value: record.attempted,
          ),
          const SizedBox(height: 8),
          _FeedbackRecordRow(label: copy.happenedLabel, value: record.happened),
          const SizedBox(height: 8),
          _FeedbackRecordRow(label: copy.insightLabel, value: record.insight),
          const SizedBox(height: 8),
          _FeedbackRecordRow(
            label: copy.adjustmentLabel,
            value: record.adjustment,
          ),
        ],
      ),
    );
  }
}

class _FeedbackRecordRow extends StatelessWidget {
  const _FeedbackRecordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final trimmed = value.trim();
    final copy = CopyStrategy.actionFeedback();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF819B8E),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          trimmed.isEmpty ? copy.emptyValue : trimmed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5B5B5B),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

String _formatFeedbackTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
