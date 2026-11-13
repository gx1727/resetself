import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/inertia_sample.dart';
import '../../home/application/home_providers.dart';
import '../../vacuum/application/vacuum_mode_providers.dart';

/// 日间打断：把理论里"白天每小时一次 3 分钟自省"落成应用内页面。
///
/// 因为没有系统通知底座，这里以固定六个时点 + 手动进入的方式实现：
/// 每个时点对应一句来自原版理论的追问，用户写下觉察并归类为
/// 「成长性行为 / 逃避性行为」，最终沉淀为 `daytime_interrupt` 惯性样本。
class DaytimeInterruptPage extends ConsumerStatefulWidget {
  const DaytimeInterruptPage({super.key});

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
  String? _savedPromptTime;

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
    final tag = _selectedTag ?? copy.growthTag;
    final content = _controller.text.trim();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(userProfileRepositoryProvider)
          .saveDaytimeInterruptReflection(
            promptLabel: '${prompt.time} · ${prompt.question}',
            content: content,
            statusTag: tag,
          );
      invalidateHomeSurface(ref);
      if (!mounted) {
        return;
      }

      _controller.clear();
      setState(() {
        _savedPromptTime = prompt.time;
        _selectedTag = null;
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

    final selectedIndex = _selectedIndex ?? _defaultPromptIndex(copy.prompts);
    final selectedPrompt = copy.prompts[selectedIndex];

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
                    onPressed: () => context.pop(),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFF819B8E),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!interruptEnabled)
                        _InterruptDisabledCard(copy: copy)
                      else ...[
                        Text(
                          copy.promptEyebrow,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF8E8E93),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < copy.prompts.length; i++) ...[
                          _InterruptPromptTile(
                            prompt: copy.prompts[i],
                            isSelected: i == selectedIndex,
                            isSaved: _savedPromptTime == copy.prompts[i].time,
                            onTap: () {
                              _controller.clear();
                              setState(() {
                                _selectedIndex = i;
                                _selectedTag = null;
                                _savedPromptTime = null;
                                _errorMessage = null;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                        _InterruptReflectionForm(
                          copy: copy,
                          controller: _controller,
                          selectedTag: _selectedTag,
                          isSaving: _isSaving,
                          errorMessage: _errorMessage,
                          onSelectTag: (tag) {
                            setState(() {
                              _selectedTag = tag;
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
                      if (reflections.isEmpty)
                        Text(
                          copy.historyEmpty,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8E8E93),
                          ),
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
  });

  final InterruptPrompt prompt;
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
                prompt.time,
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
    required this.errorMessage,
    required this.onSelectTag,
    required this.onSave,
  });

  final DaytimeInterruptCopy copy;
  final TextEditingController controller;
  final String? selectedTag;
  final bool isSaving;
  final String? errorMessage;
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
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
            copy.tagLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF8E8E93),
            ),
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
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSaving ? null : onSave,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8E8E93),
                ),
              ),
            ],
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
            copy.disabledBody,
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

int _defaultPromptIndex(List<InterruptPrompt> prompts) {
  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;
  for (var i = 0; i < prompts.length; i++) {
    if (_minutesOfDay(prompts[i].time) >= nowMinutes) {
      return i;
    }
  }
  return prompts.length - 1;
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
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
