import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/restructure_draft.dart';

class RestructureSetupPage extends ConsumerStatefulWidget {
  const RestructureSetupPage({super.key});

  @override
  ConsumerState<RestructureSetupPage> createState() => _RestructureSetupPageState();
}

class _RestructureSetupPageState extends ConsumerState<RestructureSetupPage> {
  static const _steps = [
    _WizardStep(
      id: 'anti',
      phase: '上午 90min',
      title: '反愿景',
      description: '如果保持现状 5 年不改变，\n最让你感到恐惧的画面是什么？',
      placeholder: '写下最真实的恶果，不要美化...',
    ),
    _WizardStep(
      id: 'fear',
      phase: '上午 90min',
      title: '底层恐惧',
      description: '剥离外界期待后，\n你内心深处到底在逃避什么？',
      placeholder: '怕失败、怕他人的评价、还是怕承担责任...',
    ),
    _WizardStep(
      id: 'belief',
      phase: '夜晚 120min',
      title: '限制性信念',
      description: '提炼出阻碍你的，\n最深层的一个自我否定信念。',
      placeholder: '例如：我总觉得自己不配得到好结果...',
    ),
    _WizardStep(
      id: 'identity',
      phase: '夜晚 120min',
      title: '新身份叙事',
      description: '写下你的新身份。\n不要结果指标，只要状态叙述。',
      placeholder: '我是一个______的人',
    ),
    _WizardStep(
      id: 'action',
      phase: '夜晚 120min',
      title: '极简行动',
      description: '为了印证这个新身份，\n明天你可以立刻做的零门槛动作是？',
      placeholder: '例如：早起喝一杯温水',
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
      final draft = await ref.read(userProfileRepositoryProvider).getRestructureDraft();
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
          'action': draft.minActionDraft,
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
    );
  }

  Future<void> _saveDraftNow() async {
    try {
      await ref.read(userProfileRepositoryProvider).saveRestructureDraft(_buildDraft());
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
    final needsGentleDelay = fromTyping && trimmed.isNotEmpty && trimmed.length < 10;

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
      await ref.read(appControllerProvider).submitInitialRestructure(_buildDraft());
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
      context.go(AppRoutes.onboarding);
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

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final currentText = (_formData[_currentStep.id] ?? '').trim();
    final needsShortPrompt = currentText.isNotEmpty && currentText.length < 10;
    final showActionButton =
        !_isGentleDelayActive || currentText.isEmpty || currentText.length >= 10;

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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                  TextButton(
                    onPressed: controller.isSaving
                        ? null
                        : () => context.go(AppRoutes.onboarding),
                    child: const Text('稍后继续'),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep.title,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF819B8E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentStep.description,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              onPressed: currentText.isEmpty ||
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
                                            ? '正在完成重构...'
                                            : '完成重构，返回主页')
                                        : '保存并进入下一步',
                                  ),
                                  const SizedBox(width: 8),
                                  if (controller.isSaving)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
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
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
