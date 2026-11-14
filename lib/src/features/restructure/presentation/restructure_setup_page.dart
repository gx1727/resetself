import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/inertia_sample.dart';
import '../../../data/models/morning_question.dart';
import '../../../data/models/restructure_draft.dart';

class RestructureSetupPage extends ConsumerStatefulWidget {
  const RestructureSetupPage({super.key, this.prefillFromLastAnswers = false});

  /// 进入向导时，如果本地没有草稿，则用上一次提交的重构回答预填
  /// （用于"只修改上一次的回答"）。
  final bool prefillFromLastAnswers;

  @override
  ConsumerState<RestructureSetupPage> createState() =>
      _RestructureSetupPageState();
}

class _RestructureSetupPageState extends ConsumerState<RestructureSetupPage> {
  static const _steps = [
    _WizardStep(
      id: 'anti',
      phase: '晚间 · 综合（简化问卷）',
      title: '反愿景（Anti-Vision）',
      description: '回顾晨间写下的反愿景探索，把它提炼成一句：\n你不愿继续走向的生活是什么？',
      placeholder: '写成一句你现在能确认的反愿景...',
    ),
    _WizardStep(
      id: 'fear',
      phase: '晚间 · 综合（简化问卷）',
      title: '深层恐惧与自我保护',
      description: '如果现在的行为是一种自我保护，\n你到底在保护什么？代价是什么？',
      placeholder: '怕失败、怕被评价、怕承担责任，还是怕失去某种身份...',
    ),
    _WizardStep(
      id: 'belief',
      phase: '夜晚 · 综合洞见',
      title: '内在敌人（内部模式）',
      description: '真正让你卡住的，是哪个一直在幕后运作的\n内部模式或信念？',
      placeholder: '它可能是否定自己，也可能是讨好、回避不确定、维护体面...',
    ),
    _WizardStep(
      id: 'identity',
      phase: '夜晚 · 综合洞见',
      title: '新身份叙事',
      description: '为了让新生活自然而非勉强，\n你必须相信自己是什么样的人？',
      placeholder: '我是那种会______的人',
    ),
    _WizardStep(
      id: 'vision',
      phase: '夜晚 · 综合洞见',
      title: '愿景 MVP',
      description: '用一句话概括你正在建设、走向什么，\n同时知道它还会继续演化。',
      placeholder: '例如：我在建立一个由自己节奏掌控的生活...',
    ),
    _WizardStep(
      id: 'yearGoal',
      phase: '夜晚 · 六组件',
      title: '一年镜头',
      description: '一年后，必须有什么具体事实成立，\n才能证明你已经打破旧模式？',
      placeholder: '例如：完成并发布了第一件作品',
    ),
    _WizardStep(
      id: 'monthProject',
      phase: '夜晚 · 六组件',
      title: '一月项目',
      description: '一个月后，需要学习什么、获得什么技能、\n构建什么成果，才能让一年镜头仍然可能？',
      placeholder: '例如：写出第一版内容框架，并完成 3 次练习',
    ),
    _WizardStep(
      id: 'levers',
      phase: '夜晚 · 六组件',
      title: '每日杠杆',
      description: '明天，那个正在成为的人会优先推进哪 2–3 个行动？\n可为每一项安排一个时间块。每行写一项。',
      placeholder: '例如：\n09:00 打开文档写 300 字\n20:00 练习 30 分钟',
    ),
    _WizardStep(
      id: 'action',
      phase: '夜晚 · 六组件',
      title: '最小启动行动',
      description: '从上面某一项里，缩小到此刻就能开始的\n那一个最小一步是什么？',
      placeholder: '例如：打开文档，写下一个标题',
    ),
    _WizardStep(
      id: 'valueConstraints',
      phase: '夜晚 · 六组件',
      title: '价值约束',
      description: '为了实现这个愿景，你不愿牺牲什么？\n这些边界会影响你怎样安排投入与取舍。',
      placeholder: '例如：不以长期睡眠不足换取产出，保留重要关系中的相处时间',
    ),
    _WizardStep(
      id: 'constraints',
      phase: '夜晚 · 六组件',
      title: '环境避坑规则',
      description: '哪些环境、场景、信息会触发旧习惯？\n你给自己设下的规避规则是什么？',
      placeholder: '例如：写作时把手机放到另一个房间',
    ),
  ];

  final Map<String, String> _formData = {};
  final TextEditingController _textController = TextEditingController();
  Timer? _autoSaveTimer;
  Timer? _gentleDelayTimer;
  int _currentStepIndex = 0;
  bool _isLoadingDraft = true;
  bool _isGentleDelayActive = false;
  String? _draftErrorMessage;

  _WizardStep get _currentStep => _steps[_currentStepIndex];
  bool get _isLastStep => _currentStepIndex == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDraft());
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _gentleDelayTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    try {
      final repository = ref.read(userProfileRepositoryProvider);
      var draft = await repository.getRestructureDraft();

      // "只修改上一次的回答"：本地没有草稿时，用上一次提交的回答回填，
      // 让用户看到并直接修改原有内容，而不是从空白重新填写。
      if (!draft.hasAnyInput && widget.prefillFromLastAnswers) {
        final latest = await repository.getLatestRestructureRecord();
        if (latest != null) {
          draft = RestructureDraft(
            antiVision: latest.antiVision,
            fearContent: latest.fearContent,
            beliefDraft: latest.beliefDraft,
            identityDraft: latest.identityDraft,
            minActionDraft: latest.minActionDraft,
            dailyLevers: latest.dailyLevers,
            visionText: latest.visionText,
            yearGoal: latest.yearGoal,
            monthProject: latest.monthProject,
            constraints: latest.constraints,
            valueConstraints: latest.valueConstraints,
          );
        }
      }

      if (!mounted) {
        return;
      }

      _formData
        ..clear()
        ..addAll({
          'anti': draft.antiVision,
          'fear': draft.fearContent,
          'belief': draft.beliefDraft,
          'identity': draft.identityDraft,
          'vision': draft.visionText,
          'levers': draft.dailyLevers,
          'action': draft.minActionDraft,
          'yearGoal': draft.yearGoal,
          'monthProject': draft.monthProject,
          'constraints': draft.constraints,
          'valueConstraints': draft.valueConstraints,
        });

      _syncControllerText();
      _updateGentleDelayForCurrentText(
        (_formData[_currentStep.id] ?? '').trim(),
        fromTyping: false,
      );
    } catch (error) {
      _draftErrorMessage = '草稿暂时没有取回成功，你仍然可以继续填写。';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDraft = false;
        });
      }
    }
  }

  void _syncControllerText() {
    final value = _formData[_currentStep.id] ?? '';
    _textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  RestructureDraft _buildDraft() {
    return RestructureDraft(
      antiVision: _formData['anti'] ?? '',
      fearContent: _formData['fear'] ?? '',
      beliefDraft: _formData['belief'] ?? '',
      identityDraft: _formData['identity'] ?? '',
      minActionDraft: _formData['action'] ?? '',
      dailyLevers: _formData['levers'] ?? '',
      visionText: _formData['vision'] ?? '',
      yearGoal: _formData['yearGoal'] ?? '',
      monthProject: _formData['monthProject'] ?? '',
      constraints: _formData['constraints'] ?? '',
      valueConstraints: _formData['valueConstraints'] ?? '',
    );
  }

  Future<void> _saveDraftNow() async {
    try {
      await ref
          .read(userProfileRepositoryProvider)
          .saveRestructureDraft(_buildDraft());
      if (!mounted) {
        return;
      }

      setState(() {
        _draftErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _draftErrorMessage = '草稿保存时走神了，但你刚才写下的内容还在页面里。';
      });
    }
  }

  void _scheduleDraftSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_saveDraftNow());
    });
  }

  void _updateGentleDelayForCurrentText(
    String text, {
    required bool fromTyping,
  }) {
    final trimmed = text.trim();
    final needsGentleDelay =
        fromTyping && trimmed.isNotEmpty && trimmed.length < 10;

    _gentleDelayTimer?.cancel();

    if (!needsGentleDelay) {
      if (_isGentleDelayActive) {
        setState(() {
          _isGentleDelayActive = false;
        });
      }
      return;
    }

    setState(() {
      _isGentleDelayActive = true;
    });

    _gentleDelayTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGentleDelayActive = false;
      });
    });
  }

  Future<void> _handleNext() async {
    await _saveDraftNow();

    if (_isLastStep) {
      await ref
          .read(appControllerProvider)
          .submitInitialRestructure(_buildDraft());
      if (mounted &&
          ref.read(appControllerProvider).hasCompletedInitialRestructure) {
        context.go(AppRoutes.home);
      }
      return;
    }

    setState(() {
      _currentStepIndex += 1;
      _syncControllerText();
    });
    _updateGentleDelayForCurrentText(
      (_formData[_currentStep.id] ?? '').trim(),
      fromTyping: false,
    );
  }

  void _handleBack() {
    if (_currentStepIndex == 0) {
      context.pop();
      return;
    }

    setState(() {
      _currentStepIndex -= 1;
      _syncControllerText();
    });
    _updateGentleDelayForCurrentText(
      (_formData[_currentStep.id] ?? '').trim(),
      fromTyping: false,
    );
  }

  /// 晚间综合前的回顾层：把晨间原稿和今天白天留下的观察放在一起看。
  ///
  /// 这样"晚间依据当天观察综合"才有材料，而不是只凭当下的印象作答。
  Future<void> _showReviewSheet() async {
    var answers = <String, String>{};
    var reflections = <InertiaSample>[];

    try {
      final repository = ref.read(userProfileRepositoryProvider);
      answers = await repository.getMorningAnswers();
      reflections = await repository.getTodayInterruptReflections();
    } catch (error) {
      // 回顾失败不阻塞晚间综合，页面照常可用。
    }

    if (!mounted) {
      return;
    }

    final answeredQuestions = MorningQuestion.all
        .where((question) => (answers[question.key] ?? '').trim().isNotEmpty)
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF7F7F5),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Text(
                  '晚间综合前的回顾',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '先看一遍晨间写下的原稿和今天白天的观察，再开始综合。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8E8E93),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '晨间原稿',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF819B8E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (answeredQuestions.isEmpty)
                  Text(
                    '还没有晨间回答。你可以先去完成晨间挖掘，再回来综合。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8E8E93),
                      height: 1.5,
                    ),
                  )
                else
                  for (final question in answeredQuestions) ...[
                    _ReviewEntry(
                      label: '${question.order}. ${question.question}',
                      value: answers[question.key] ?? '',
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push(AppRoutes.restructureMorning);
                    },
                    child: const Text('去补充 / 修改晨间原稿'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '今天的日间观察',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF819B8E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (reflections.isEmpty)
                  Text(
                    '今天还没有留下日间观察。白天用日间打断看一眼自己的真实行为，这里就会有材料。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8E8E93),
                      height: 1.5,
                    ),
                  )
                else
                  for (final reflection in reflections) ...[
                    _ReviewEntry(
                      label: reflection.statusTag,
                      value: reflection.content,
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push(AppRoutes.daytimeInterrupt);
                    },
                    child: const Text('去记录一次日间观察'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final currentText = (_formData[_currentStep.id] ?? '').trim();
    final needsShortPrompt = currentText.isNotEmpty && currentText.length < 10;
    final showActionButton =
        !_isGentleDelayActive ||
        currentText.isEmpty ||
        currentText.length >= 10;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      size: 28,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _currentStep.phase,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFF8E8E93),
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_steps.length, (index) {
                            final bool isCurrent = index == _currentStepIndex;
                            final bool isDone = index < _currentStepIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isCurrent ? 16 : 8,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: isCurrent || isDone
                                    ? const Color(0xFF819B8E)
                                    : const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _isLoadingDraft ? null : _showReviewSheet,
                        child: const Text('回顾'),
                      ),
                      TextButton(
                        onPressed: controller.isSaving
                            ? null
                            : () => context.pop(),
                        child: const Text('稍后继续'),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _isLoadingDraft
                      ? Center(
                          child: Text(
                            '正在取回你上次停下的思绪...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF8E8E93)),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep.title,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: const Color(0xFF819B8E),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentStep.description,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: const Color(0xFF2D2D2D),
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _textController,
                              autofocus: true,
                              maxLines: 6,
                              minLines: 4,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF2D2D2D),
                                    height: 1.6,
                                  ),
                              decoration: InputDecoration(
                                hintText: _currentStep.placeholder,
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: const Color(0x668E8E93),
                                      height: 1.6,
                                    ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _formData[_currentStep.id] = value;
                                });
                                _updateGentleDelayForCurrentText(
                                  value,
                                  fromTyping: true,
                                );
                                _scheduleDraftSave();
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 24,
                              child: needsShortPrompt
                                  ? Row(
                                      children: [
                                        const Icon(
                                          Icons.eco_outlined,
                                          size: 14,
                                          color: Color(0xFF819B8E),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isGentleDelayActive
                                              ? '先停 1.5 秒，按钮马上出现。多写一点会更帮助你看清自己。'
                                              : '多写一点真实的细节，会更容易看见你真正的拉扯。',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF8E8E93),
                                              ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ],
                        ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: showActionButton
                          ? FilledButton(
                              key: const ValueKey('wizard-action-button'),
                              onPressed:
                                  currentText.isEmpty ||
                                      controller.isSaving ||
                                      _isLoadingDraft
                                  ? null
                                  : _handleNext,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLastStep
                                        ? (controller.isSaving
                                              ? '正在保存本次反思...'
                                              : '保存本次反思，返回主页')
                                        : '保存并进入下一步',
                                  ),
                                  const SizedBox(width: 8),
                                  if (controller.isSaving)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                ],
                              ),
                            )
                          : SizedBox(
                              key: const ValueKey('wizard-action-placeholder'),
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEFEA),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Center(
                                  child: Text(
                                    '按钮正在慢慢出现...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF8E8E93),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (_draftErrorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _draftErrorMessage!,
                        style: const TextStyle(color: Color(0xFF8E8E93)),
                      ),
                    ],
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        controller.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WizardStep {
  const _WizardStep({
    required this.id,
    required this.phase,
    required this.title,
    required this.description,
    required this.placeholder,
  });

  final String id;
  final String phase;
  final String title;
  final String description;
  final String placeholder;
}

/// 回顾层里的一条只读记录（晨间原稿或日间观察）。
class _ReviewEntry extends StatelessWidget {
  const _ReviewEntry({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF8E8E93),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2D2D2D),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
