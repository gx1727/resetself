import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state/app_controller.dart';
import '../../data/database/database_providers.dart';

Future<void> showMinActionEditor(BuildContext context, {String? suggestion}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _MinActionDialog(suggestion: suggestion),
    );

class _MinActionDialog extends ConsumerStatefulWidget {
  const _MinActionDialog({this.suggestion});
  final String? suggestion;
  @override
  ConsumerState<_MinActionDialog> createState() => _MinActionDialogState();
}

class _MinActionDialogState extends ConsumerState<_MinActionDialog> {
  late final TextEditingController _controller;
  final _reasonController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text:
          widget.suggestion ??
          ref.read(appControllerProvider).profile.todayMinAction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _controller.text.trim().isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(appControllerProvider);
      await ref
          .read(userProfileRepositoryProvider)
          .updateTodayMinAction(
            _controller.text,
            reason: _reasonController.text,
          );
      await controller.reloadProfile();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '行动没有保存，请重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('修改最小启动行动'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('从想推进的行动里选择现在能开始的一步。确认后更新首页行动。'),
            TextField(controller: _controller, enabled: !_saving, maxLines: 3),
            TextField(
              controller: _reasonController,
              enabled: !_saving,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '修改原因（可选）'),
            ),
            if (_error != null) Text(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '保存中…' : '确认保存'),
        ),
      ],
    ),
  );
}
