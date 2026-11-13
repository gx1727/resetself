import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/state/app_controller.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../data/database/database_providers.dart';
import '../../home/application/home_providers.dart';
import '../../restructure/presentation/restructure_restart_sheet.dart';

class SosPage extends ConsumerStatefulWidget {
  const SosPage({super.key});

  @override
  ConsumerState<SosPage> createState() => _SosPageState();
}

class _SosPageState extends ConsumerState<SosPage> {
  bool _isSaving = false;
  bool _saved = false;
  String? _errorMessage;
  String? _selectedLabel;

  Future<void> _handleSave(String label) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(userProfileRepositoryProvider).saveSosSample(label);
      invalidateHomeSurface(ref);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedLabel = label;
        _saved = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = NeutralCopyEngine.sosError();
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
    final profile = ref.watch(appControllerProvider).profile;
    final minimalAction = profile.todayMinAction.isEmpty
        ? '回到首页后，只做 1 个最小动作'
        : profile.todayMinAction;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _saved
                        ? _SosDoneView(
                            selectedLabel: _selectedLabel ?? '这次拉扯',
                            minimalAction: minimalAction,
                            onBackHome: () => context.go(AppRoutes.home),
                            onOpenAction: () => context.go(AppRoutes.home),
                          )
                        : Column(
                            key: const ValueKey('sos-form'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monitor_heart_outlined,
                                size: 48,
                                color: Color(0xFF819B8E),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                NeutralCopyEngine.sosIntroTitle(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: const Color(0xFFE5E5EA),
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                NeutralCopyEngine.sosIntroBody(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF8E8E93),
                                      height: 1.7,
                                    ),
                              ),
                              const SizedBox(height: 32),
                              _SosActionButton(
                                label: '我感到焦虑，想逃避',
                                onTap:
                                    _isSaving ? null : () => _handleSave('我感到焦虑，想逃避'),
                              ),
                              const SizedBox(height: 12),
                              _SosActionButton(
                                label: '对庞大的目标感到畏惧',
                                onTap: _isSaving
                                    ? null
                                    : () => _handleSave('对庞大的目标感到畏惧'),
                              ),
                              const SizedBox(height: 12),
                              _SosActionButton(
                                label: '我开始怀疑自己根本做不到',
                                onTap: _isSaving
                                    ? null
                                    : () => _handleSave('我开始怀疑自己根本做不到'),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                              if (_isSaving) ...[
                                const SizedBox(height: 16),
                                Text(
                                  NeutralCopyEngine.sosSaving(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: const Color(0xFF8E8E93)),
                                ),
                              ],
                              const SizedBox(height: 32),
                              TextButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => openRestructureRestartFlow(context, ref),
                                child: const Text('认为方向错了？重新进入 24h 重构'),
                              ),
                            ],
                          ),
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

class _SosDoneView extends StatelessWidget {
  const _SosDoneView({
    required this.selectedLabel,
    required this.minimalAction,
    required this.onBackHome,
    required this.onOpenAction,
  });

  final String selectedLabel;
  final String minimalAction;
  final VoidCallback onBackHome;
  final VoidCallback onOpenAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('sos-done'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2E),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.self_improvement_rounded,
            size: 34,
            color: Color(0xFF819B8E),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          NeutralCopyEngine.sosDoneTitle(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFFE5E5EA),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          NeutralCopyEngine.sosDoneBody(selectedLabel),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E93),
                height: 1.7,
              ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '现在只做 3 件小事',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFE5E5EA),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              _CalmStep(text: '先把呼吸放慢，给自己 3 次缓慢吸气和呼气'),
              const SizedBox(height: 8),
              _CalmStep(text: '承认这只是旧惯性，不把它解释成“我不行”'),
              const SizedBox(height: 8),
              _CalmStep(text: '回到首页，只做今天那个最小动作就够了'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3A3A3C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '现在只回到这一个动作',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF819B8E),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                minimalAction,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFE5E5EA),
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onOpenAction,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('回到首页，看最小行动'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onBackHome,
          child: const Text('先回首页，稍后再继续'),
        ),
      ],
    );
  }
}

class _CalmStep extends StatelessWidget {
  const _CalmStep({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Icons.circle,
            size: 8,
            color: Color(0xFF819B8E),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFAFAFB4),
                  height: 1.6,
                ),
          ),
        ),
      ],
    );
  }
}

class _SosActionButton extends StatelessWidget {
  const _SosActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        alignment: Alignment.centerLeft,
        backgroundColor: const Color(0xFF2C2C2E),
        foregroundColor: const Color(0xFFE5E5EA),
        side: const BorderSide(color: Color(0xFF3A3A3C)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFF8E8E93),
          ),
        ],
      ),
    );
  }
}
