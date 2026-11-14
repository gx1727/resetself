import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/inertia_sample.dart';
import '../../home/application/home_providers.dart';
import '../../vacuum/application/vacuum_mode_providers.dart';
import '../../restructure/presentation/exploration_review_sheet.dart';

/// 原文六个示例时点及三条追加追问；标签是可选的产品整理方式。
class DaytimeInterruptPage extends ConsumerStatefulWidget {
  const DaytimeInterruptPage({super.key, this.initialPromptId});

  /// 由通知点击带入的问题 id；命中时会直接选中对应问题。
  final String? initialPromptId;

  @override
  ConsumerState<DaytimeInterruptPage> createState() =>
      _DaytimeInterruptPageState();
}

class _DaytimeInterruptPageState extends ConsumerState<DaytimeInterruptPage> {
  final TextEditingController _controller = TextEditingController();
  int? _selectedIndex;
  String? _selectedTag;
  bool _isSaving = false;
  String? _errorMessage;
  String? _savedPromptId;
  String _reflectionText = '';
  final Map<int, String> _drafts = {};
  final Map<int, String?> _tags = {};

  void _selectPrompt(int index, int currentIndex) {
    if (_isSaving) return;
    _drafts[currentIndex] = _controller.text;
    _tags[currentIndex] = _selectedTag;
    _controller.text = _drafts[index] ?? '';
    setState(() {
      _selectedIndex = index;
      _selectedTag = _tags[index];
      _reflectionText = _controller.text;
      _errorMessage = null;
    });
  }

  @override
  void initState() {
    super.initState();
    final promptId = widget.initialPromptId;
    if (promptId != null && promptId.isNotEmpty) {
      final copy = CopyStrategy.daytimeInterrupt();
      final allPrompts = [...copy.prompts, ...copy.followUpPrompts];
      final index = allPrompts.indexWhere((prompt) => prompt.id == promptId);
      if (index >= 0) {
        _selectedIndex = index;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave(InterruptPrompt prompt) async {
    if (_isSaving) {
      return;
    }

    final copy = CopyStrategy.daytimeInterrupt();
    final content = _controller.text.trim();
    final tag = _selectedTag;

    if (content.isEmpty) {
      setState(() {
        _errorMessage = copy.emptyContentHint;
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
          .saveDaytimeInterruptReflection(
            content: content,
            statusTag: tag ?? '未归类',
            promptId: prompt.id,
            promptSnapshot: prompt.question,
          );
      invalidateHomeSurface(ref);
      if (!mounted) {
        return;
      }

      _controller.clear();
      setState(() {
        _drafts.remove(_selectedIndex);
        _tags.remove(_selectedIndex);
        _savedPromptId = prompt.id;
        _selectedTag = null;
        _reflectionText = '';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '这次自省没有记下来，你可以再点一次。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = CopyStrategy.daytimeInterrupt();
    final settingsAsync = ref.watch(vacuumModeSettingsProvider);
    final reflectionsAsync = ref.watch(todayInterruptReflectionsProvider);
    final reflections = reflectionsAsync.valueOrNull ?? const <InertiaSample>[];
    final interruptEnabled =
        settingsAsync.valueOrNull?.interruptEnabled ?? true;

    final allPrompts = [...copy.prompts, ...copy.followUpPrompts];
    final configuredTimes =
        settingsAsync.valueOrNull?.interruptTimeList ?? const <String>[];
    final promptTimes = [
      for (var i = 0; i < copy.prompts.length; i++)
        i < configuredTimes.length ? configuredTimes[i] : copy.prompts[i].time,
    ];
    final selectedIndex = _selectedIndex ?? _defaultPromptIndex(promptTimes);
    final selectedPrompt = allPrompts[selectedIndex];
    final followUpStartIndex = copy.prompts.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.home),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      size: 28,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF8E8E93),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.subtitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF2D2D2D),
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0EC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.eco_outlined,
                              size: 16,
                              color: Color(0xFF819B8E),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CopyStrategy.daytimeInterruptRecorded(
                                reflections.length,
                              ),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFF819B8E),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!interruptEnabled) _InterruptDisabledCard(copy: copy),
                      ...[
                        const Text('原文示例时点，可按日程调整；也可以随时手动记录。'),
                        ExpansionTile(
                          title: const Text('选择／切换观察问题'),
                          children: [
                            Text(
                              copy.promptEyebrow,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFF8E8E93),
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            for (var i = 0; i < copy.prompts.length; i++) ...[
                              _InterruptPromptTile(
                                prompt: copy.prompts[i],
                                time: promptTimes[i],
                                isSelected: i == selectedIndex,
                                isSaved: _savedPromptId == copy.prompts[i].id,
                                onTap: () => _selectPrompt(i, selectedIndex),
                              ),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              copy.followUpEyebrow,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFF8E8E93),
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            for (
                              var i = 0;
                              i < copy.followUpPrompts.length;
                              i++
                            ) ...[
                              _InterruptPromptTile(
                                prompt: copy.followUpPrompts[i],
                                isSelected:
                                    followUpStartIndex + i == selectedIndex,
                                isSaved:
                                    _savedPromptId ==
                                    copy.followUpPrompts[i].id,
                                onTap: () => _selectPrompt(
                                  followUpStartIndex + i,
                                  selectedIndex,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ),
                        Text(
                          selectedPrompt.question,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: () => showExplorationReview(
                            context,
                            includeObservations: false,
                          ),
                          child: const Text('回看晨间原稿'),
                        ),
                        _InterruptReflectionForm(
                          copy: copy,
                          controller: _controller,
                          selectedTag: _selectedTag,
                          isSaving: _isSaving,
                          canSave: _reflectionText.trim().isNotEmpty,
                          errorMessage: _errorMessage,
                          onChangedText: (value) {
                            setState(() {
                              _reflectionText = value;
                            });
                          },
                          onSelectTag: (tag) {
                            if (_isSaving) return;
                            setState(() {
                              _selectedTag = _selectedTag == tag ? null : tag;
                            });
                          },
                          onSave: () => _handleSave(selectedPrompt),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        copy.historyTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF2D2D2D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (reflectionsAsync.hasError)
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(todayInterruptReflectionsProvider),
                          child: const Text('观察记录读取失败，点此重试'),
                        )
                      else if (reflectionsAsync.isLoading)
                        const Text('正在读取观察记录…')
                      else if (reflections.isEmpty)
                        Text(
                          copy.historyEmpty,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF8E8E93)),
                        )
                      else
                        for (final sample in reflections) ...[
                          _InterruptHistoryTile(sample: sample),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterruptPromptTile extends StatelessWidget {
  const _InterruptPromptTile({
    required this.prompt,
    required this.isSelected,
    required this.isSaved,
    required this.onTap,
    this.time,
  });

  final InterruptPrompt prompt;
  final String? time;
  final bool isSelected;
  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4FAF6) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC7DED2)
                : const Color(0xFFF0F0F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0EC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                time ?? prompt.time,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF819B8E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                prompt.question,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2D2D2D),
                  height: 1.5,
                ),
              ),
            ),
            if (isSaved) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: Color(0xFF819B8E),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InterruptReflectionForm extends StatelessWidget {
  const _InterruptReflectionForm({
    required this.copy,
    required this.controller,
    required this.selectedTag,
    required this.isSaving,
    required this.canSave,
    required this.errorMessage,
    required this.onChangedText,
    required this.onSelectTag,
    required this.onSave,
  });

  final DaytimeInterruptCopy copy;
  final TextEditingController controller;
  final String? selectedTag;
  final bool isSaving;
  final bool canSave;
  final String? errorMessage;
  final ValueChanged<String> onChangedText;
  final ValueChanged<String> onSelectTag;
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
          Text(
            copy.reflectionLabel,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 10),
          TextField(
            enabled: !isSaving,
            controller: controller,
            minLines: 3,
            maxLines: 5,
            onChanged: onChangedText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF2D2D2D),
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: copy.reflectionHint,
              hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0x668E8E93),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${copy.tagLabel}（可选，可暂时不归类）',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              _InterruptTagChip(
                label: copy.growthTag,
                selected: selectedTag == copy.growthTag,
                onTap: () => onSelectTag(copy.growthTag),
              ),
              _InterruptTagChip(
                label: copy.escapeTag,
                selected: selectedTag == copy.escapeTag,
                onTap: () => onSelectTag(copy.escapeTag),
              ),
              _InterruptTagChip(
                label: copy.otherTag,
                selected: selectedTag == copy.otherTag,
                onTap: () => onSelectTag(copy.otherTag),
              ),
            ],
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
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
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

class _InterruptTagChip extends StatelessWidget {
  const _InterruptTagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF819B8E) : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : const Color(0xFF5B5B5B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InterruptHistoryTile extends StatelessWidget {
  const _InterruptHistoryTile({required this.sample});

  final InertiaSample sample;

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
          Row(
            children: [
              Text(
                sample.statusTag,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF819B8E),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _formatInterruptTime(sample.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8E8E93)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sample.promptSnapshot ?? '未记录问题',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Text(
            sample.content,
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

class _InterruptDisabledCard extends StatelessWidget {
  const _InterruptDisabledCard({required this.copy});

  final DaytimeInterruptCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAEAE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.disabledTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF2D2D2D),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '日间通知已关闭。你仍可以手动查看问题、回看原稿并记录观察。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8E8E93),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.vacuumMode),
            child: const Text('去认知真空准备区'),
          ),
        ],
      ),
    );
  }
}

int _defaultPromptIndex(List<String> times) {
  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;
  for (var i = 0; i < times.length; i++) {
    if (_minutesOfDay(times[i]) >= nowMinutes) {
      return i;
    }
  }
  return times.length - 1;
}

int _minutesOfDay(String time) {
  final parts = time.split(':');
  if (parts.length != 2) {
    return 0;
  }
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return hour * 60 + minute;
}

String _formatInterruptTime(DateTime value) {
  return formatObservationTime(value);
}
