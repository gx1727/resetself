import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../data/database/database_providers.dart';
import '../../../data/models/checkin_status.dart';

class DailyCheckinPage extends ConsumerStatefulWidget {
  const DailyCheckinPage({super.key});

  @override
  ConsumerState<DailyCheckinPage> createState() => _DailyCheckinPageState();
}

class _DailyCheckinPageState extends ConsumerState<DailyCheckinPage> {
  CheckinStatus? _submittedStatus;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleSelect(CheckinStatus status) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(userProfileRepositoryProvider).saveDailyCheckin(status);
      if (!mounted) {
        return;
      }

      setState(() {
        _submittedStatus = status;
      });

      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '这次校验没有记下来，你可以再点一次。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
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
                    child: _submittedStatus != null
                        ? _CheckinDoneView(status: _submittedStatus!)
                        : _CheckinSelectView(
                            onSelect: _handleSelect,
                            isSubmitting: _isSubmitting,
                            errorMessage: _errorMessage,
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

class _CheckinSelectView extends StatelessWidget {
  const _CheckinSelectView({
    required this.onSelect,
    required this.isSubmitting,
    this.errorMessage,
  });

  final ValueChanged<CheckinStatus> onSelect;
  final bool isSubmitting;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('select'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.eco_outlined,
          color: Color(0xFF819B8E),
          size: 32,
        ),
        const SizedBox(height: 24),
        Text(
          '今天的行为，\n匹配你的新身份吗？',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '无需自责，系统只做状态校准',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 32),
        for (final (index, status) in CheckinStatus.values.indexed) ...[
          if (index > 0) const SizedBox(height: 12),
          _OptionButton(
            label: status.optionLabel,
            dotColor: switch (status) {
              CheckinStatus.match => const Color(0xFF819B8E),
              CheckinStatus.partial => const Color(0xFFC2A878),
              CheckinStatus.fullDeviation => const Color(0xFFE5E5EA),
            },
            foregroundColor: status == CheckinStatus.fullDeviation
                ? const Color(0xFF8E8E93)
                : const Color(0xFF2D2D2D),
            onTap: isSubmitting ? null : () => onSelect(status),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8E8E93),
            ),
          ),
        ],
        if (isSubmitting) ...[
          const SizedBox(height: 16),
          Text(
            '系统正在温柔地记下今天的状态...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8E8E93),
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckinDoneView extends StatelessWidget {
  const _CheckinDoneView({required this.status});

  final CheckinStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('done'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F0EC),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 32,
            color: Color(0xFF819B8E),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          status.completionTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          status.completionBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF8E8E93),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.dotColor,
    required this.onTap,
    this.foregroundColor = const Color(0xFF2D2D2D),
  });

  final String label;
  final Color dotColor;
  final VoidCallback? onTap;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        alignment: Alignment.centerLeft,
        side: const BorderSide(color: Color(0xFFE5E5EA)),
        backgroundColor: Colors.white,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
