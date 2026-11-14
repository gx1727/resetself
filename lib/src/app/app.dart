import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation/app_router.dart';
import 'navigation/app_routes.dart';
import 'state/app_controller.dart';
import 'system/system_resident.dart';
import 'theme/app_theme.dart';

class ResetSelfRoot extends ConsumerStatefulWidget {
  const ResetSelfRoot({super.key});

  @override
  ConsumerState<ResetSelfRoot> createState() => _ResetSelfRootState();
}

class _ResetSelfRootState extends ConsumerState<ResetSelfRoot> {
  StreamSubscription<String>? _promptSubscription;

  /// 初始化未完成时先暂存的通知点击目标，等应用就绪后再跳转。
  String? _pendingPromptId;

  @override
  void initState() {
    super.initState();
    SystemResident.bindDaytimePromptRequests();
    _promptSubscription = SystemResident.daytimePromptRequests.listen(
      _onPromptRequested,
    );
  }

  @override
  void dispose() {
    _promptSubscription?.cancel();
    super.dispose();
  }

  void _onPromptRequested(String promptId) {
    _pendingPromptId = promptId;
    _flushPendingPrompt();
  }

  void _flushPendingPrompt() {
    final promptId = _pendingPromptId;
    if (promptId == null) {
      return;
    }

    final controller = ref.read(appControllerProvider);
    // 初始化完成前不跳转，否则会被引导页重定向吞掉。
    if (controller.isInitializing || controller.hasInitializationError) {
      return;
    }

    _pendingPromptId = null;
    final location = Uri(
      path: AppRoutes.daytimeInterrupt,
      queryParameters: {'prompt': promptId},
    ).toString();
    ref.read(appRouterProvider).go(location);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appControllerProvider, (previous, next) {
      if (!next.isInitializing) {
        _flushPendingPrompt();
      }
    });

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ResetSelf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
