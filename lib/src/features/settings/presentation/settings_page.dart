import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/app_debug_snapshot.dart';
import '../../vacuum/application/vacuum_mode_providers.dart';

final debugSnapshotProvider = FutureProvider.autoDispose<AppDebugSnapshot>((ref) {
  return ref.watch(userProfileRepositoryProvider).getDebugSnapshot();
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final debugSnapshotAsync = ref.watch(debugSnapshotProvider);
    final vacuumSettingsAsync = ref.watch(vacuumModeSettingsProvider);

    return AppPageScaffold(
      title: '设置与调试',
      subtitle: '先保留 P0 需要的开发入口，方便调试流程锁、本地数据库和首轮重构状态。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              title: const Text('当前流程状态'),
              subtitle: Text(controller.profile.status.value),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.air_rounded, color: Color(0xFF819B8E)),
                  title: const Text('认知真空准备区'),
                  subtitle: const Text('查看降噪准备、专注时段和提醒节奏'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.vacuumMode),
                ),
                const Divider(height: 1),
                vacuumSettingsAsync.when(
                  data: (settings) => ListTile(
                    leading:
                        const Icon(Icons.tune_rounded, color: Color(0xFF8E8E93)),
                    title: const Text('当前真空模式节奏'),
                    subtitle: Text(
                      '${settings.focusWindowMinutes} 分钟 / ${settings.reminderTime} / ${settings.focusRhythmLabel}',
                    ),
                  ),
                  loading: () => const ListTile(
                    leading: Icon(Icons.tune_rounded, color: Color(0xFF8E8E93)),
                    title: Text('当前真空模式节奏'),
                    subtitle: Text('正在读取本地设置...'),
                  ),
                  error: (error, stackTrace) => const ListTile(
                    leading: Icon(Icons.tune_rounded, color: Color(0xFF8E8E93)),
                    title: Text('当前真空模式节奏'),
                    subtitle: Text('本地设置暂时未展开'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.do_not_disturb_alt_rounded,
                    color: Color(0xFF819B8E),
                  ),
                  title: const Text('打开专注进行中页'),
                  subtitle: const Text('按当前真空模式节奏进入一段安静区'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.vacuumFocus),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: debugSnapshotAsync.when(
                data: (snapshot) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本地数据库调试面板',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DebugRow(label: '数据库路径', value: snapshot.databasePath),
                    _DebugRow(label: '最近 7 天样本', value: '${snapshot.recentSampleCount} 条'),
                    _DebugRow(label: '样本总数', value: '${snapshot.totalSampleCount} 条'),
                    _DebugRow(label: '每日校验总数', value: '${snapshot.dailyCheckinCount} 条'),
                    _DebugRow(
                      label: '草稿状态',
                      value: snapshot.hasDraft ? '存在未完成草稿' : '没有草稿',
                    ),
                    _DebugRow(
                      label: '最近校验日期',
                      value: snapshot.latestCheckinDate ?? '暂无',
                    ),
                  ],
                ),
                loading: () => Text(
                  '正在整理本地调试信息...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                error: (error, stackTrace) => Text(
                  '调试信息暂时没有展开，但本地数据仍然保留在设备里。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: controller.isSaving
                ? null
                : () async {
                    await controller.resetExperience();
                    ref.invalidate(debugSnapshotProvider);
                  },
            child: Text(controller.isSaving ? '重置中...' : '重置为首次引导'),
          ),
        ],
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
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
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2D2D2D),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
