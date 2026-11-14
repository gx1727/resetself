import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';
import '../../../core/widgets/draft_navigation_guard.dart';
import '../../../core/widgets/draft_save_controller.dart';
import '../../home/application/home_providers.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/restructure_draft.dart';
import 'exploration_review_sheet.dart';

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
      phase: '晚间 · 理解当前模式',
      title: '反愿景（Anti-Vision）',
      description: '回顾晨间写下的反愿景探索，把它提炼成一句：\n你不愿继续走向的生活是什么？',
      placeholder: '写成一句你现在能确认的反愿景...',
    ),
    _WizardStep(
      id: 'fear',
      phase: '晚间 · 理解当前模式',
      title: '深层恐惧与自我保护',
      description: '回看这些观察，如果某些行为是在保护自己，\n它们在保护什么？带来了什么，也付出了什么？',
      placeholder: '怕失败、怕被评价、怕承担责任，还是怕失去某种身份...',
    ),
    _WizardStep(
      id: 'belief',
      phase: '晚间 · 理解当前模式',
      title: '内在敌人（内部模式）',
      description: '经过这些观察，哪个反复出现的内部模式或信念，\n最像是在让你停留原地？',
      placeholder: '它可能是否定自己，也可能是讨好、回避不确定、维护体面...',
    ),
    _WizardStep(
      id: 'identity',
      phase: '晚间 · 选择想建设的生活',
      title: '新身份叙事',
      description: '为了让这种生活逐渐变得自然，\n你想以怎样的方式生活和行动？',
      placeholder: '我是那种会______的人',
    ),
    _WizardStep(
      id: 'vision',
      phase: '晚间 · 选择想建设的生活',
      title: '愿景 MVP',
      description: '用一句话概括你正在建设、走向什么，\n同时知道它还会继续演化。',
      placeholder: '例如：我在建立一个由自己节奏掌控的生活...',
    ),
    _WizardStep(
      id: 'yearGoal',
      phase: '晚间 · 安排行动与边界',
      title: '一年镜头',
      description: '一年后，希望有什么具体事实成立，\n让你看见自己正在接近想要的生活？',
      placeholder: '例如：完成并发布了第一件作品',
    ),
    _WizardStep(
      id: 'monthProject',
      phase: '晚间 · 安排行动与边界',
      title: '一月项目',
      description: '为了推进这个一年目标，这个月需要学习什么、\n练习什么，或做出什么成果？',
      placeholder: '例如：写出第一版内容框架，并完成 3 次练习',
    ),
    _WizardStep(
      id: 'levers',
      phase: '晚间 · 安排行动与边界',
      title: '每日杠杆',
      description: '为了推进这个月项目，明天优先做哪 2–3 个行动？\n可为每项安排时间块。每行写一项。',
      placeholder: '例如：\n09:00 打开文档写 300 字\n20:00 练习 30 分钟',
    ),
    _WizardStep(
      id: 'action',
      phase: '晚间 · 安排行动与边界',
      title: '最小启动行动',
      description: '从上面某一项里，缩小到此刻就能开始的\n那一个最小一步是什么？',
      placeholder: '例如：打开文档，写下一个标题',
    ),
    _WizardStep(
      id: 'valueConstraints',
      phase: '晚间 · 安排行动与边界',
      title: '价值约束',
      description: '为了实现这个愿景，你不愿牺牲什么？\n这些边界会影响你怎样安排投入与取舍。',
      placeholder: '例如：不以长期睡眠不足换取产出，保留重要关系中的相处时间',
    ),
    _WizardStep(
      id: 'constraints',
      phase: '晚间 · 安排行动与边界',
      title: '环境避坑规则',
      description: '哪些环境、场景、信息会触发旧习惯？\n你给自己设下的规避规则是什么？',
      placeholder: '例如：写作时把手机放到另一个房间',
    ),
  ];

  final Map<String, String> _formData = {};
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _hasPreviousDirection = false;
  final _exitKey = GlobalKey<DraftNavigationGuardState>();
  late final DraftSaveController<RestructureDraft> _saver;
  bool _loadFailed = false;
  bool _advancing = false;
  int _currentStepIndex = 0;
  bool _isLoadingDraft = true;
  String? _draftErrorMessage;

  _WizardStep get _currentStep => _steps[_currentStepIndex];
  bool get _isLastStep => _currentStepIndex == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    final repository = ref.read(userProfileRepositoryProvider);
    _saver = DraftSaveController(
      write: repository.saveRestructureDraft,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    unawaited(_loadDraft());
  }

  @override
  void dispose() {
    _saver.dispose();
    _textController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    try {
      final repository = ref.read(userProfileRepositoryProvider);
      var draft = await repository.getRestructureDraft();
      _hasPreviousDirection = ref
          .read(appControllerProvider)
          .hasCompletedInitialRestructure;

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
      final step = _steps.indexWhere((step) => step.id == draft.currentStepId);
      _currentStepIndex = step < 0 ? 0 : step;
      _reasonController.text = draft.changeReason;
      _syncControllerText();
    } catch (error) {
      _loadFailed = true;
      _draftErrorMessage = '草稿读取失败。请重试取回，避免覆盖已有内容。';
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
      currentStepId: _currentStep.id,
      changeReason: _reasonController.text,
    );
  }

  Future<bool> _saveDraftNow() => _saver.flush();

  void _scheduleDraftSave() {
    _saver.update(_buildDraft());
  }

  Future<void> _handleNext() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    final saved = await _saveDraftNow();
    if (!mounted) return;
    if (!saved) {
      setState(() => _advancing = false);
      return;
    }

    if (_isLastStep) {
      await ref
          .read(appControllerProvider)
          .submitInitialRestructure(_buildDraft());
      if (mounted &&
          ref.read(appControllerProvider).hasCompletedInitialRestructure) {
        if (ref.read(appControllerProvider).errorMessage == null) {
          invalidateHomeSurface(ref);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('本次方向已保存。接下来，在生活中尝试，再根据反馈调整。')),
          );
          context.go(AppRoutes.home);
        }
      }
      if (mounted) setState(() => _advancing = false);
      return;
    }

    setState(() {
      _advancing = false;
      _currentStepIndex += 1;
      _syncControllerText();
    });
    _scheduleDraftSave();
  }

  void _handleBack() {
    if (_currentStepIndex == 0) {
      unawaited(_exitKey.currentState?.leave());
      return;
    }

    setState(() {
      _currentStepIndex -= 1;
      _syncControllerText();
    });
    _scheduleDraftSave();
  }

  Future<void> _showReviewSheet() async {
    if (await _saveDraftNow() && mounted) {
      await showExplorationReview(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final currentText = (_formData[_currentStep.id] ?? '').trim();

    return DraftNavigationGuard(
      key: _exitKey,
      save: _saveDraftNow,
      ready: !_isLoadingDraft && !_loadFailed,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F5),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _advancing ? null : _handleBack,
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
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
                          onPressed: controller.isSaving || _advancing
                              ? null
                              : () => _exitKey.currentState?.leave(),
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
                        : SingleChildScrollView(
                            child: Column(
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: const Color(0xFF2D2D2D),
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                if (_currentStep.id == 'anti')
                                  OutlinedButton(
                                    onPressed: _showReviewSheet,
                                    child: const Text('先回看晨间原稿与日间观察'),
                                  ),
                                if (_currentStep.id == 'belief')
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      '先作为待核对的解释：哪些观察支持它？安排下一步时，也核对时间、精力、技能和环境。',
                                    ),
                                  ),
                                if (_currentStep.id == 'identity')
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text('身份表达可以随经验调整，不必现在就完全做到。'),
                                  ),
                                if (_contextForStep().isNotEmpty)
                                  ExpansionTile(
                                    title: const Text('回看相关方向'),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(_contextForStep()),
                                      ),
                                    ],
                                  ),
                                TextField(
                                  enabled: !_loadFailed && !_advancing,
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
                                    _scheduleDraftSave();
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (_isLastStep &&
                                    (_hasPreviousDirection ||
                                        widget.prefillFromLastAnswers))
                                  ExpansionTile(
                                    title: const Text('这次为什么调整（可选）'),
                                    children: [
                                      TextField(
                                        controller: _reasonController,
                                        enabled: !_loadFailed && !_advancing,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          hintText: '哪次经历或反馈让你改变了方向？',
                                        ),
                                        onChanged: (_) => _scheduleDraftSave(),
                                      ),
                                    ],
                                  ),
                                Text(
                                  _saver.isSaving
                                      ? '正在保存草稿…'
                                      : _saver.isDirty
                                      ? '有待保存的改动'
                                      : '当前内容已保存',
                                ),
                              ],
                            ),
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
                        child: FilledButton(
                          key: const ValueKey('wizard-action-button'),
                          onPressed:
                              currentText.isEmpty ||
                                  controller.isSaving ||
                                  _isLoadingDraft ||
                                  _loadFailed ||
                                  _advancing
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
                        ),
                      ),
                      if (_draftErrorMessage != null ||
                          _saver.error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _draftErrorMessage ?? '草稿未保存成功，内容仍在页面里，请重试。',
                          style: const TextStyle(color: Color(0xFF8E8E93)),
                        ),
                      ],
                      if (_loadFailed || _saver.error != null)
                        TextButton(
                          onPressed: () async {
                            if (_loadFailed) {
                              setState(() {
                                _isLoadingDraft = true;
                                _loadFailed = false;
                                _draftErrorMessage = null;
                              });
                              await _loadDraft();
                            } else {
                              await _saveDraftNow();
                            }
                          },
                          child: const Text('重试'),
                        ),
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
      ),
    );
  }

  String _contextForStep() => switch (_currentStep.id) {
    'yearGoal' => '愿景：${_formData['vision'] ?? ''}',
    'monthProject' => '一年目标：${_formData['yearGoal'] ?? ''}',
    'levers' => '月项目：${_formData['monthProject'] ?? ''}',
    'action' => '每日杠杆：${_formData['levers'] ?? ''}',
    'valueConstraints' => '愿景：${_formData['vision'] ?? ''}',
    _ => '',
  };
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
