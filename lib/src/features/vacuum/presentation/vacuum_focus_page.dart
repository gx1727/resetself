import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/vacuum_focus_state.dart';
import '../../../data/models/vacuum_mode_settings.dart';
import '../../home/application/home_providers.dart';
import '../application/vacuum_mode_providers.dart';

class VacuumFocusPage extends ConsumerWidget {
  const VacuumFocusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(vacuumModeSettingsProvider);
    final focusStateAsync = ref.watch(vacuumFocusStateProvider);
    final hasCompletedInitialRestructure = ref
        .watch(appControllerProvider)
        .hasCompletedInitialRestructure;

    return Scaffold(
      backgroundColor: const Color(0xFF121315),
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(
            child: Text(
              '正在展开这一段安静区...',
              style: TextStyle(color: Color(0xFF8E8E93)),
            ),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.air_rounded,
                    color: Color(0xFF819B8E),
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '真空专注页暂时没有完全展开。',
                    style: TextStyle(
                      color: Color(0xFFE5E5EA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '但你仍然可以回到准备区，继续保持当前节奏。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8E8E93), height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.vacuumMode),
                    child: const Text('返回真空准备区'),
                  ),
                ],
              ),
            ),
          ),
          data: (settings) => focusStateAsync.when(
            loading: () => const Center(
              child: Text(
                '正在读取当前专注状态...',
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
            ),
            error: (error, stackTrace) => const Center(
              child: Text(
                '专注状态暂时没有完全展开。',
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
            ),
            data: (focusState) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF8E8E93),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    focusState.isActive ? '专注进行中' : '准备开始专注',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFE5E5EA),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    focusState.isActive
                        ? '你已经进入这一段安静区。接下来只保留当前动作。'
                        : '从这里开始进入一段真正安静的时间。按下开始后，首页和这里都会同步显示当前专注状态。',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFAFAFB4),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FocusHeroCard(settings: settings, focusState: focusState),
                  const SizedBox(height: 16),
                  _FocusActionCard(settings: settings, focusState: focusState),
                  const SizedBox(height: 16),
                  _FocusChecklistCard(
                    settings: settings,
                    focusState: focusState,
                  ),
                  const SizedBox(height: 16),
                  _FocusNoteCard(
                    hasCompletedInitialRestructure:
                        hasCompletedInitialRestructure,
                    focusState: focusState,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      final repository = ref.read(
                        userProfileRepositoryProvider,
                      );
                      if (focusState.isActive) {
                        await repository.stopVacuumFocus();
                      } else {
                        await repository.startVacuumFocus(settings);
                      }
                      invalidateHomeSurface(ref);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(focusState.isActive ? '结束这段专注' : '开始这段专注'),
                        const SizedBox(width: 8),
                        Icon(
                          focusState.isActive
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!focusState.isActive) ...[
                    OutlinedButton(
                      onPressed: () =>
                          context.push(AppRoutes.restructureMorning),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('继续进入 24h 重构'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton(
                    onPressed: () {
                      if (hasCompletedInitialRestructure) {
                        context.go(AppRoutes.home);
                      } else {
                        context.pop();
                      }
                    },
                    child: Text(
                      hasCompletedInitialRestructure ? '先回首页' : '回到真空准备区',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusHeroCard extends StatelessWidget {
  const _FocusHeroCard({required this.settings, required this.focusState});

  final VacuumModeSettings settings;
  final VacuumFocusState focusState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2D3135)),
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
              '当前真空节奏',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF819B8E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            focusState.isActive
                ? _focusHeroTitle(settings, focusState)
                : '${settings.focusWindowMinutes} 分钟安静区',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFFE5E5EA),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            focusState.isActive
                ? _focusHeroSubtitle(settings, focusState)
                : '提醒时间 ${settings.reminderTime} · ${settings.focusRhythmLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFAFAFB4),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusActionCard extends StatelessWidget {
  const _FocusActionCard({required this.settings, required this.focusState});

  final VacuumModeSettings settings;
  final VacuumFocusState focusState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2D3135)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前执行方式',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFE5E5EA),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _FocusPill(
            label: focusState.isActive
                ? '当前状态已开始'
                : (settings.noiseCutEnabled ? '降噪已开启' : '手动降噪中'),
            summary: focusState.isActive
                ? '首页和专注页现在会同步显示这一段专注是否正在进行。'
                : (settings.noiseCutEnabled
                      ? '优先把消息、短视频和无关标签页留在外面'
                      : '至少先关掉最容易把你拉走的一个入口'),
          ),
          const SizedBox(height: 10),
          _FocusPill(
            label: settings.gentleReminderEnabled ? '温和提醒开启' : '提醒已关闭',
            summary: settings.gentleReminderEnabled
                ? '在 ${settings.reminderTime} 留下一次低频提醒'
                : '这一段时间先不打断自己，只让行动往前走',
          ),
        ],
      ),
    );
  }
}

class _FocusChecklistCard extends StatelessWidget {
  const _FocusChecklistCard({required this.settings, required this.focusState});

  final VacuumModeSettings settings;
  final VacuumFocusState focusState;

  @override
  Widget build(BuildContext context) {
    final items = [
      focusState.isActive
          ? '这一段专注已经开始，接下来只处理当前动作，不切到别的入口'
          : '接下来 ${settings.focusWindowMinutes} 分钟内，不处理社交消息和碎片输入',
      settings.noiseCutEnabled
          ? '保持降噪状态，只留下当前任务需要的 1 个窗口或 1 个工具'
          : '先把最容易分心的应用关掉，再继续当前动作',
      settings.gentleReminderEnabled
          ? '把 ${settings.reminderTime} 当作一次轻提醒，不把它当成压迫'
          : '这段时间没有系统提醒，只盯住你下一步最小动作',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2D3135)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '进入前只确认 3 件事',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFE5E5EA),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF819B8E),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFAFAFB4),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _FocusNoteCard extends StatelessWidget {
  const _FocusNoteCard({
    required this.hasCompletedInitialRestructure,
    required this.focusState,
  });

  final bool hasCompletedInitialRestructure;
  final VacuumFocusState focusState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF17191B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2D3135)),
      ),
      child: Text(
        focusState.isActive
            ? '这段专注结束后，首页会回到未开始状态，你可以再决定是否进入下一段。'
            : (hasCompletedInitialRestructure
                  ? '这一页已经和首页联动。开始后，你会在首页看到当前真空节奏正在进行。'
                  : '这一页会先把你带进安静区，开始后也会同步回到首页状态。'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF8E8E93),
          height: 1.7,
        ),
      ),
    );
  }
}

class _FocusPill extends StatelessWidget {
  const _FocusPill({required this.label, required this.summary});

  final String label;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151618),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D3135)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFFE5E5EA),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFAFAFB4),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

String _focusHeroTitle(
  VacuumModeSettings settings,
  VacuumFocusState focusState,
) {
  final remainingMinutes = focusState.remainingMinutes;
  if (remainingMinutes == null) {
    return '${settings.focusWindowMinutes} 分钟安静区';
  }

  if (remainingMinutes == 0) {
    return '这段专注已到结束时间';
  }

  return '预计还有 $remainingMinutes 分钟';
}

String _focusHeroSubtitle(
  VacuumModeSettings settings,
  VacuumFocusState focusState,
) {
  final startLabel = focusState.startedAt == null
      ? '刚刚开始'
      : '开始于 ${_formatTimeOnly(focusState.startedAt!)}';
  return '$startLabel · ${settings.focusRhythmLabel}';
}

String _formatTimeOnly(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
