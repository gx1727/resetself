import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/system/system_resident.dart';

final systemResidentStatusProvider =
    FutureProvider.autoDispose<SystemResidentStatus>((ref) {
      return SystemResident.status();
    });

/// 设置页里的「后台常驻与提醒」面板：展示系统授权状态并提供授权入口。
class ResidentSettingsCard extends ConsumerStatefulWidget {
  const ResidentSettingsCard({super.key});

  @override
  ConsumerState<ResidentSettingsCard> createState() =>
      _ResidentSettingsCardState();
}

class _ResidentSettingsCardState extends ConsumerState<ResidentSettingsCard>
    with WidgetsBindingObserver {
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
    // 从系统设置/授权弹窗返回后重新读取真实状态。
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(systemResidentStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(systemResidentStatusProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '后台常驻与提醒',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '开启后会尝试维持后台服务并安排提醒。实际送达受通知权限、电池限制和系统策略影响。'
              '若系统限制了后台运行，需要按下面几项逐一放行。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E93),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            statusAsync.when(
              data: (status) => Column(
                children: [
                  _StatusRow(
                    icon: Icons.notifications_active_outlined,
                    label: '通知权限',
                    value: status.notificationsEnabled ? '已开启' : '未开启',
                    ok: status.notificationsEnabled,
                    actionLabel: '去允许',
                    onAction: () async {
                      await SystemResident.requestNotificationPermission();
                      ref.invalidate(systemResidentStatusProvider);
                    },
                  ),
                  _StatusRow(
                    icon: Icons.alarm_rounded,
                    label: '精确提醒',
                    value: status.exactAlarmAllowed ? '已允许' : '未允许（时间可能被延后）',
                    ok: status.exactAlarmAllowed,
                    actionLabel: '去允许',
                    onAction: () async {
                      await SystemResident.requestExactAlarmPermission();
                      ref.invalidate(systemResidentStatusProvider);
                    },
                  ),
                  _StatusRow(
                    icon: Icons.battery_saver_outlined,
                    label: '电池优化',
                    value: status.ignoringBatteryOptimizations ? '已豁免' : '仍受限制',
                    ok: status.ignoringBatteryOptimizations,
                    actionLabel: '去设置',
                    onAction: () async {
                      await SystemResident.requestIgnoreBatteryOptimizations();
                      ref.invalidate(systemResidentStatusProvider);
                    },
                  ),
                  _StatusRow(
                    icon: Icons.shield_moon_outlined,
                    label: '常驻服务',
                    value: status.residentRunning ? '运行中' : '未运行',
                    ok: status.residentRunning,
                    actionLabel: '立即开启',
                    onAction: () async {
                      await SystemResident.start();
                      ref.invalidate(systemResidentStatusProvider);
                    },
                  ),
                  _StatusRow(
                    icon: Icons.schedule_outlined,
                    label: '已排提醒',
                    value: '${status.scheduledReminderCount} 条',
                    ok: status.scheduledReminderCount > 0,
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '正在读取系统状态...',
                  style: TextStyle(color: Color(0xFF8E8E93)),
                ),
              ),
              error: (error, stackTrace) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '暂时读不到系统状态，可以在手机设置里手动放行后台运行。',
                  style: TextStyle(color: Color(0xFF8E8E93)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ok,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ok;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: ok ? const Color(0xFF819B8E) : const Color(0xFF8E8E93),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                onAction!();
              },
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
