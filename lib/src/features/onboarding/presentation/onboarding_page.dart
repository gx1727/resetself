import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../core/copy/neutral_copy_engine.dart';
import '../../../core/widgets/method_note.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = CopyStrategy.onboarding();
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.air_rounded, size: 48, color: Color(0xFF819B8E)),
              const SizedBox(height: 32),
              Text(
                '欢迎来到\n认知真空区。',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFFE5E5EA),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                copy.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF8E8E93),
                  height: 1.7,
                ),
              ),
              const Spacer(flex: 3),
              TextButton(
                onPressed: () => showMethodNote(context),
                child: const Text('晨间探索 → 日间观察 → 晚间综合 · 方法说明'),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3A3A3C)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF819B8E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFFA1A1A6),
                                height: 1.6,
                              ),
                          children: const [
                            TextSpan(
                              text: '接下来这段时间属于你自己\n',
                              style: TextStyle(
                                color: Color(0xFFE5E5EA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '如果方便，可以先减少手机干扰。应用只会记录你的降噪偏好，不会替你屏蔽其他应用或系统通知。',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  alignment: Alignment.centerLeft,
                  foregroundColor: const Color(0xFFE5E5EA),
                  side: const BorderSide(color: Color(0xFF3A3A3C)),
                  backgroundColor: const Color(0xFF2C2C2E),
                ),
                onPressed: () => context.push(AppRoutes.vacuumMode),
                child: Row(
                  children: [
                    const Icon(Icons.waves_outlined, color: Color(0xFF819B8E)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(copy.vacuumPrepCta)),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE5E5EA),
                  foregroundColor: const Color(0xFF1C1C1E),
                ),
                onPressed: () => context.push(AppRoutes.restructureMorning),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(copy.restructureCta),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
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
