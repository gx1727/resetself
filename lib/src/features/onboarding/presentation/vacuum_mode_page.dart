import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/system/system_resident.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/vacuum_mode_settings.dart';
import '../../vacuum/application/vacuum_mode_providers.dart';

class VacuumModePage extends ConsumerStatefulWidget {
  const VacuumModePage({super.key});

  @override
  ConsumerState<VacuumModePage> createState() => _VacuumModePageState();
}

class _VacuumModePageState extends ConsumerState<VacuumModePage> {
  VacuumModeSettings? _draft;
  bool _isSaving = false;

  static const _focusWindowOptions = [60, 90, 120];
  static const _rhythmOptions = [
    '每晚一次温和提醒',
    '工作日提醒',
    '只在重构日提醒',
  ];

  Future<void> _saveSettings(VacuumModeSettings settings) async {
    setState(() {
      _draft = settings;
      _isSaving = true;
    });

    await ref.read(userProfileRepositoryProvider).saveVacuumModeSettings(settings);
    await SystemResident.syncReminders(settings);
    ref.invalidate(vacuumModeSettingsProvider);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }
@override
  Widget build(BuildContext context) {
    final copy = CopyStrategy.vacuumMode();

    final settingsAsync = ref.watch(vacuumModeSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: settingsAsync.when(
            loading: () => const Center(
              child: Text(
                '正在整理你的真空模式设置...',
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
            ),
            error: (error, stackTrace) => const Center(
              child: Text(
                '真空模式设置暂时没有展开，但后续仍可继续进入重构。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
            ),
            data: (loadedSettings) {
              final settings = _draft ?? loadedSettings;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.home),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF8E8E93),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '认知真空\n准备区',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFFE5E5EA),
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '这一页开始具备本地记忆能力。你选择的专注时段、降噪偏好和提醒节奏，都会被温柔记住。',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF8E8E93),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _VacuumFocusEntryCard(
                      settings: settings,
                      onOpenFocus: () => context.push(AppRoutes.vacuumFocus),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '建议专注时段',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFE5E5EA),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _focusWindowOptions.map((minutes) {
                        final isSelected = minutes == settings.focusWindowMinutes;
                        return ChoiceChip(
                          label: Text(CopyStrategy.vacuumDurationOption(minutes)),
                          selected: isSelected,
                          onSelected: _isSaving
                              ? null
                              : (_) => _saveSettings(
                                    settings.copyWith(
                                      focusWindowMinutes: minutes,
                                    ),
                                  ),
                          selectedColor: const Color(0xFFE8F0EC),
                          backgroundColor: const Color(0xFF2C2C2E),
                          side: const BorderSide(color: Color(0xFF3A3A3C)),
                          labelStyle:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? const Color(0xFF819B8E)
                                        : const Color(0xFFAFAFB4),
                                    fontWeight: FontWeight.w600,
                                  ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _VacuumToggleCard(
                      title: '降噪状态',
                      subtitle: '把社交信息和无关提醒先关在门外，给自己一段真正安静的时间。',
                      value: settings.noiseCutEnabled,
                      onChanged: _isSaving
                          ? null
                          : (value) => _saveSettings(
                                settings.copyWith(noiseCutEnabled: value),
                              ),
                    ),
                    const SizedBox(height: 12),
                    _VacuumToggleCard(
                      title: '温和提醒',
                      subtitle: '在专注时段中，只保留低频、无压迫感的提示方式。',
                      value: settings.gentleReminderEnabled,
                      onChanged: _isSaving
                          ? null
                          : (value) => _saveSettings(
                                settings.copyWith(
                                  gentleReminderEnabled: value,
                                ),
                              ),
                    ),
                    const SizedBox(height: 12),
                    _VacuumToggleCard(
                      title: '日间打断',
                      subtitle: '在 11:00 / 13:30 / 15:15 / 17:00 / 19:30 / 21:00 提醒你停下来，用 3 分钟看清此刻是在走向新身份，还是退回旧惯性。',
                      value: settings.interruptEnabled,
                      onChanged: _isSaving
                          ? null
                          : (value) => _saveSettings(
                                settings.copyWith(interruptEnabled: value),
                              ),
                    ),
                    const SizedBox(height: 12),
                    _VacuumChoiceCard(
                      title: '提醒时间',
                      value: settings.reminderTime,
                      options: const ['07:30', '12:30', '21:30'],
                      onSelected: _isSaving
                          ? null
                          : (value) => _saveSettings(
                                settings.copyWith(reminderTime: value),
                              ),
                    ),
                    const SizedBox(height: 12),
                    _VacuumChoiceCard(
                      title: '专注节奏',
                      value: settings.focusRhythmLabel,
                      options: _rhythmOptions,
                      onSelected: _isSaving
                          ? null
                          : (value) => _saveSettings(
                                settings.copyWith(focusRhythmLabel: value),
                              ),
                    ),
                    const SizedBox(height: 16),
                    const _VacuumChecklistCard(
                      title: '建议先完成的 3 件事',
                      items: [
                        '把社交软件、短视频和工作通知先静音 90 分钟',
                        '确认自己处在一个不会被打断的独处环境',
                        '准备纸笔或耳机，只留下真正需要的工具',
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _VacuumChecklistCard(
                      title: '后续会接进来的能力',
                      items: [
                        '系统级专注权限引导',
                        '重构时段建议与专注提醒',
                        '首页回流与专注状态同步',
                      ],
                    ),
                    if (_isSaving) ...[
                      const SizedBox(height: 12),
                      Text(
                        '正在记住这次真空模式偏好...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8E8E93),
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => context.push(AppRoutes.vacuumFocus),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(copy.enterFocus),
                          const SizedBox(width: 8),
                          const Icon(Icons.air_rounded, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push(AppRoutes.restructureSetup),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(copy.readyCta),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VacuumToggleCard extends StatelessWidget {
  const _VacuumToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3A3A3C)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFE5E5EA),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFAFAFB4),
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFF819B8E),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _VacuumChoiceCard extends StatelessWidget {
  const _VacuumChoiceCard({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3A3A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFE5E5EA),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = option == value;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: onSelected == null ? null : (_) => onSelected!(option),
                selectedColor: const Color(0xFFE8F0EC),
                backgroundColor: const Color(0xFF1F1F21),
                side: const BorderSide(color: Color(0xFF3A3A3C)),
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? const Color(0xFF819B8E)
                          : const Color(0xFFAFAFB4),
                      fontWeight: FontWeight.w600,
                    ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _VacuumChecklistCard extends StatelessWidget {
  const _VacuumChecklistCard({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3A3A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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

class _VacuumFocusEntryCard extends StatelessWidget {
  const _VacuumFocusEntryCard({
    required this.settings,
    required this.onOpenFocus,
  });

  final VacuumModeSettings settings;
  final VoidCallback onOpenFocus;

  @override
  Widget build(BuildContext context) {
    final copy = CopyStrategy.vacuumMode();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF232528),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3A3A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '如果现在就想开始一段安静区',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFE5E5EA),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '按你当前的节奏，系统会带你进入 ${settings.focusWindowMinutes} 分钟真空专注页，并保留 ${settings.reminderTime} 的提醒设定。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFAFAFB4),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onOpenFocus,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(copy.enterFocus),
                const SizedBox(width: 8),
                const Icon(Icons.waves_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
