import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:resetself/src/app/app.dart';
import 'package:resetself/src/app/state/app_controller.dart';
import 'package:resetself/src/data/models/user_profile.dart';

void main() {
  testWidgets('未完成首次重构时跳转到引导页', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith(
            (ref) => AppController.test(profile: UserProfile.empty()),
          ),
        ],
        child: const ResetSelfRoot(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('欢迎来到\n认知真空区。'), findsOneWidget);
    expect(find.text('开启 24h 重构向导'), findsOneWidget);
  });

  testWidgets('完成首次重构后进入首页身份中枢', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith(
            (ref) => AppController.test(profile: UserProfile.demoFinished()),
          ),
        ],
        child: const ResetSelfRoot(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('当前核心身份'), findsOneWidget);
    expect(find.text('进行今日校验'), findsOneWidget);
  });
}
