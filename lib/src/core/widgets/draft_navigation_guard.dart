import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/navigation/app_routes.dart';

/// System back and explicit exit share the same save-before-leave path.
class DraftNavigationGuard extends StatefulWidget {
  const DraftNavigationGuard({
    required this.save,
    required this.child,
    super.key,
    this.ready = true,
  });

  final Future<bool> Function() save;
  final bool ready;
  final Widget child;

  @override
  State<DraftNavigationGuard> createState() => DraftNavigationGuardState();
}

class DraftNavigationGuardState extends State<DraftNavigationGuard>
    with WidgetsBindingObserver {
  bool _allowPop = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.ready &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused)) {
      unawaited(widget.save());
    }
  }

  Future<void> leave() async {
    if (_leaving) return;
    _leaving = true;
    var saved = !widget.ready || await widget.save();
    while (!saved) {
      if (!mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('还有内容没有保存'),
          content: const Text('内容仍在页面里。可以重试保存，或放弃未保存的改动后离开。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'stay'),
              child: const Text('继续填写'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('放弃改动并离开'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'retry'),
              child: const Text('重试保存'),
            ),
          ],
        ),
      );
      if (choice == 'discard') break;
      if (choice != 'retry') {
        _leaving = false;
        return;
      }
      saved = await widget.save();
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(leave());
    },
    child: widget.child,
  );
}
