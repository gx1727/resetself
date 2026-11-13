import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/app_debug_snapshot.dart';
import '../../../data/models/backup_export_result.dart';
import '../../../data/models/backup_restore_result.dart';
import '../../../data/models/vacuum_focus_state.dart';
import '../../home/application/home_providers.dart';
import '../../vacuum/application/vacuum_mode_providers.dart';
import 'resident_settings_card.dart';

final debugSnapshotProvider = FutureProvider.autoDispose<AppDebugSnapshot>((ref) {
  return ref.watch(userProfileRepositoryProvider).getDebugSnapshot();
});

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isExportingBackup = false;
  bool _isRestoringBackup = false;
  BackupExportResult? _lastBackupResult;
  BackupRestoreResult? _lastRestoreResult;

  Future<void> _handleExportBackup() async {
    if (_isExportingBackup) {
      return;
    }

    setState(() {
      _isExportingBackup = true;
    });

    try {
      final result = await ref.read(userProfileRepositoryProvider).exportLocalBackup();
      if (!mounted) {
        return;
      }

      setState(() {
        _lastBackupResult = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(NeutralCopyEngine.settingsBackupExported(result.filePath)),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(NeutralCopyEngine.settingsBackupExportFailed()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingBackup = false;
        });
      }
    }
  }

  Future<void> _handleRestoreBackup() async {
    if (_isRestoringBackup) {
      return;
    }

    setState(() {
      _isRestoringBackup = true;
    });

    try {
      final result = await ref.read(userProfileRepositoryProvider).restoreLatestBackup();
      await ref.read(appControllerProvider).reloadProfile();
      ref.invalidate(debugSnapshotProvider);
      invalidateHomeSurface(ref);
      ref.invalidate(vacuumModeSettingsProvider);
      if (!mounted) {
        return;
      }

      setState(() {
        _lastRestoreResult = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(NeutralCopyEngine.settingsBackupRestored(result.filePath)),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message
                : NeutralCopyEngine.settingsBackupRestoreFailed(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringBackup = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsCopy = CopyStrategy.settings();
    final controller = ref.watch(appControllerProvider);
    final debugSnapshotAsync = ref.watch(debugSnapshotProvider);
    final vacuumSettingsAsync = ref.watch(vacuumModeSettingsProvider);
    final focusStateAsync = ref.watch(vacuumFocusStateProvider);
    final copy = NeutralCopyEngine.settingsPage();

    return AppPageScaffold(
      title: copy.title,
      subtitle: copy.subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              title: Text(CopyStrategy.settings().flowSectionTitle),
              subtitle: Text(controller.profile.status.value),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.air_rounded, color: Color(0xFF819B8E)),
                  title: Text(copy.focusPanelTitle),
                  subtitle: Text(copy.focusPanelBody),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.vacuumMode),
                ),
                const Divider(height: 1),
                vacuumSettingsAsync.when(
                  data: (settings) => ListTile(
                    leading:
                        const Icon(Icons.tune_rounded, color: Color(0xFF8E8E93)),
                    title: Text(settingsCopy.vacuumSectionTitle),
                    subtitle: Text(
                      '${settings.focusWindowMinutes} 分钟 / ${settings.reminderTime} / ${settings.focusRhythmLabel}',
                    ),
                  ),
                  loading: () => ListTile(
                    leading: const Icon(Icons.tune_rounded, color: Color(0xFF8E8E93)),
                    title: Text(settingsCopy.vacuumSectionTitle),
                    subtitle: Text(NeutralCopyEngine.settingsFocusSettingsLoading()),
                  ),
                  error: (error, stackTrace) => ListTile(
                    leading: const Icon(Icons.tune_rounded, color: Color(0xFF8E8E93)),
                    title: const Text('当前真空模式节奏'),
                    subtitle: Text(NeutralCopyEngine.settingsFocusSettingsError()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.do_not_disturb_alt_rounded,
                    color: Color(0xFF819B8E),
                  ),
                  title: Text(copy.focusOpenTitle),
                  subtitle: Text(copy.focusOpenBody),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.vacuumFocus),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: focusStateAsync.when(
              data: (focusState) => Column(
                children: [
                  ListTile(
                    leading: Icon(
                      focusState.isActive
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      color: focusState.isActive
                          ? const Color(0xFF819B8E)
                          : const Color(0xFF8E8E93),
                    ),
                    title: Text(
                      focusState.isActive ? '当前正在真空专注' : '当前未在真空专注',
                    ),
                    subtitle: Text(_focusStateSummary(focusState)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () async {
                              final settings = vacuumSettingsAsync.valueOrNull;
                              if (settings == null) {
                                context.go(AppRoutes.vacuumFocus);
                                return;
                              }

                              final repository =
                                  ref.read(userProfileRepositoryProvider);
                              if (focusState.isActive) {
                                await repository.stopVacuumFocus();
                              } else {
                                await repository.startVacuumFocus(settings);
                              }
                              invalidateHomeSurface(ref);
                            },
                            child: Text(
                              focusState.isActive ? '结束这段专注' : '从设置页开始专注',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go(AppRoutes.vacuumFocus),
                            child: Text(NeutralCopyEngine.settingsOpenFocusPageLabel()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => ListTile(
                leading: const Icon(Icons.timelapse_rounded, color: Color(0xFF8E8E93)),
                title: Text(settingsCopy.focusSectionTitle),
                subtitle: Text(NeutralCopyEngine.settingsFocusStatusLoading()),
              ),
              error: (error, stackTrace) => ListTile(
                leading: const Icon(Icons.timelapse_rounded, color: Color(0xFF8E8E93)),
                title: Text(settingsCopy.focusSectionTitle),
                subtitle: Text(NeutralCopyEngine.settingsFocusStatusError()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const ResidentSettingsCard(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: debugSnapshotAsync.when(
                  data: (snapshot) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.debugPanelTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DebugRow(
                        label: settingsCopy.debugDbPath,
                        value: snapshot.databasePath,
                      ),
                      _DebugRow(
                        label: settingsCopy.debugRecentSamples,
                        value: '${snapshot.recentSampleCount}${settingsCopy.debugCountSuffix}',
                      ),
                      _DebugRow(
                        label: settingsCopy.debugTotalSamples,
                        value: '${snapshot.totalSampleCount}${settingsCopy.debugCountSuffix}',
                      ),
                      _DebugRow(
                        label: settingsCopy.debugCheckinCount,
                        value: '${snapshot.dailyCheckinCount}${settingsCopy.debugCountSuffix}',
                      ),
                      _DebugRow(
                        label: settingsCopy.debugDraftStatus,
                        value: snapshot.hasDraft ? '存在未完成草稿' : '没有草稿',
                      ),
                      _DebugRow(
                        label: settingsCopy.debugRecentCheckinDate,
                        value: snapshot.latestCheckinDate ?? '暂无',
                      ),
                    ],
                  ),
                  loading: () => Text(
                    NeutralCopyEngine.settingsDebugLoading(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  error: (error, stackTrace) => Text(
                    NeutralCopyEngine.settingsDebugError(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.backupTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.backupBody,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8E8E93),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: _isExportingBackup ? null : _handleExportBackup,
                    child: Text(
                      _isExportingBackup
                          ? NeutralCopyEngine.settingsBackupExporting()
                          : NeutralCopyEngine.settingsBackupExportLabel(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isRestoringBackup ? null : _handleRestoreBackup,
                    child: Text(
                      _isRestoringBackup
                          ? NeutralCopyEngine.settingsBackupRestoring()
                          : NeutralCopyEngine.settingsBackupRestoreLabel(),
                    ),
                  ),
                  if (_lastBackupResult != null) ...[
                    const SizedBox(height: 14),
                    _DebugRow(
                      label: settingsCopy.debugLatestExport,
                      value: _lastBackupResult!.filePath,
                    ),
                    _DebugRow(
                      label: settingsCopy.debugExportContents,
                      value:
                          '${_lastBackupResult!.tableCount} 张表，${_lastBackupResult!.recordCount} 条记录',
                    ),
                    _DebugRow(
                      label: settingsCopy.debugExportTime,
                      value: CopyStrategy.settingsDebugTimestamp(_lastBackupResult!.exportedAt),
                    ),
                  ],
                  if (_lastRestoreResult != null) ...[
                    const SizedBox(height: 4),
                    _DebugRow(
                      label: settingsCopy.debugLatestRestore,
                      value: _lastRestoreResult!.filePath,
                    ),
                    _DebugRow(
                      label: settingsCopy.debugRestoreContents,
                      value:
                          '${_lastRestoreResult!.tableCount} 张表，${_lastRestoreResult!.recordCount} 条记录',
                    ),
                    _DebugRow(
                      label: settingsCopy.debugRestoreTime,
                      value: CopyStrategy.settingsDebugTimestamp(_lastRestoreResult!.restoredAt),
                    ),
                  ],
                ],
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
            child: Text(
              controller.isSaving ? copy.resettingLabel : copy.resetLabel,
            ),
          ),
        ],
      ),
    );
  }
}

String _focusStateSummary(VacuumFocusState focusState) {
  return NeutralCopyEngine.settingsFocusSummary(
    isActive: focusState.isActive,
    remainingMinutes: focusState.remainingMinutes,
    plannedMinutes: focusState.plannedMinutes,
    hasStartedAt: focusState.startedAt != null,
    lastEndedAt: focusState.lastEndedAt,
  );
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
