import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';

/// 用户在弹层里选择的重启方式。
enum RestructureRestartChoice {
  /// 彻底清空所有已有数据后重建。
  clearAll,

  /// 只修改上一次写下的回答，不清空数据。
  editLastAnswers,
}

/// 在"重新进入 24h 重构"前弹出的选择层。
///
/// 返回用户的选择；点击右上角"×"或下滑关闭时返回 null。
Future<RestructureRestartChoice?> showRestructureRestartSheet(
  BuildContext context,
) {
  return showModalBottomSheet<RestructureRestartChoice>(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    isScrollControlled: true,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => const _RestructureRestartSheet(),
  );
}

/// 统一的"重新进入 24h 重构"入口：先让用户选择清空重建或修改上一次回答。
Future<void> openRestructureRestartFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final choice = await showRestructureRestartSheet(context);
  if (choice == null || !context.mounted) {
    return;
  }

  if (choice == RestructureRestartChoice.editLastAnswers) {
    context.push(AppRoutes.restructureSetupEdit);
    return;
  }

  final confirmed = await _confirmClearAll(context);
  if (confirmed != true || !context.mounted) {
    return;
  }

  await ref.read(appControllerProvider).clearAllAndRestart();
  if (!context.mounted) {
    return;
  }

  context.go(AppRoutes.onboarding);
}

Future<bool?> _confirmClearAll(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        '确定彻底清空重建？',
        style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w700),
      ),
      content: const Text(
        '这会清空所有已有数据，包括身份、重构回答、晨间原稿、每日校验与 SOS 记录等，清空后无法恢复。',
        style: TextStyle(color: Color(0xFF5B5B5B), height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('再想想'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC2A878),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('确认清空'),
        ),
      ],
    ),
  );
}

class _RestructureRestartSheet extends StatelessWidget {
  const _RestructureRestartSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '重新进入 24h 重构',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFFE5E5EA),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '选择一种方式继续。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8E8E93),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RestartOptionCard(
              icon: Icons.autorenew_rounded,
              accentColor: const Color(0xFFC2A878),
              title: '彻底清空重建',
              description: '会清空所有已有数据：身份、重构回答、晨间原稿、每日校验、SOS 记录等，且无法恢复。',
              onTap: () =>
                  Navigator.of(context).pop(RestructureRestartChoice.clearAll),
            ),
            const SizedBox(height: 12),
            _RestartOptionCard(
              icon: Icons.edit_outlined,
              accentColor: const Color(0xFF819B8E),
              title: '修改上一次的回答',
              description: '保留现有数据，只更新你这一次写下的回答。',
              onTap: () => Navigator.of(
                context,
              ).pop(RestructureRestartChoice.editLastAnswers),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestartOptionCard extends StatelessWidget {
  const _RestartOptionCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFE5E5EA),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFA1A1A6),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
