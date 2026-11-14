import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:resetself/src/app/app.dart';
import 'package:resetself/src/app/navigation/app_router.dart';
import 'package:resetself/src/app/navigation/app_routes.dart';
import 'package:resetself/src/data/database/database_providers.dart';
import 'package:resetself/src/features/vacuum/application/vacuum_mode_providers.dart';

/// 设备端截图输出目录（应用私有临时目录，宿主机通过 run-as 拉取）。
final shotDir = '${Directory.systemTemp.path}/manual_shots';

late GlobalKey rootKey;
late WidgetTester T;
late GoRouter router;

int _shotCount = 0;

Future<void> settle() async {
  try {
    await T.pumpAndSettle(
      const Duration(milliseconds: 80),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 4),
    );
  } catch (_) {
    await T.pump(const Duration(milliseconds: 400));
  }
}

Future<void> pumps([int n = 8, int ms = 120]) async {
  for (var i = 0; i < n; i++) {
    await T.pump(Duration(milliseconds: ms));
  }
}

/// 把可能匹配多个元素的 finder 收敛成首个元素，避免 "Too many elements"。
Finder one(Finder finder) {
  final matches = finder.evaluate();
  if (matches.length > 1) return finder.first;
  return finder;
}

Future<void> shot(String name) async {
  try {
    await pumps(5, 100);
    final boundary =
        rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: T.view.devicePixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory(shotDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    _shotCount += 1;
    debugPrint('SHOT_SAVED $name');
  } catch (error) {
    debugPrint('SHOT_FAILED $name :: $error');
  }
}

Future<void> tap(Finder finder) async {
  final target = one(finder);
  await T.ensureVisible(target);
  await T.tap(target);
  await settle();
}

Future<void> write(Finder finder, String text) async {
  final target = one(finder);
  await T.ensureVisible(target);
  await T.enterText(target, text);
  FocusManager.instance.primaryFocus?.unfocus();
  await settle();
}

/// 屏幕逻辑尺寸，用于按比例发起原生拖拽。
Size get _screen {
  final size = T.view.physicalSize / T.view.devicePixelRatio;
  return size;
}

/// 从屏幕中下部发起上滑。直接按坐标拖拽，避免误取到页面上方的横向滚动列表。
Future<void> dragUp([double dy = 520]) async {
  final size = _screen;
  final distance = dy.clamp(0.0, size.height * 0.85);
  await T.dragFrom(
    Offset(size.width * 0.5, size.height * 0.72),
    Offset(0, -distance),
  );
  await settle();
}

/// 从屏幕中上部发起下滑。
Future<void> dragDown([double dy = 520]) async {
  final size = _screen;
  final distance = dy.clamp(0.0, size.height * 0.85);
  await T.dragFrom(
    Offset(size.width * 0.5, size.height * 0.32),
    Offset(0, distance),
  );
  await settle();
}

Future<void> scrollTo(Finder finder) async {
  try {
    await T.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await settle();
  } catch (error) {
    debugPrint('SCROLL_FAILED :: $error');
  }
}

bool hasText(String value) => find.text(value).evaluate().isNotEmpty;

bool filledEnabled() {
  final finder = find.byType(FilledButton);
  if (finder.evaluate().isEmpty) return false;
  return T.widget<FilledButton>(finder.first).onPressed != null;
}

bool textEnabled() {
  final finder = find.byType(TextField);
  if (finder.evaluate().isEmpty) return false;
  return T.widget<TextField>(finder.first).enabled != false;
}

Future<void> waitUntil(
  bool Function() ready, {
  int attempts = 60,
  String label = 'condition',
}) async {
  for (var i = 0; i < attempts; i++) {
    if (ready()) return;
    await T.pump(const Duration(milliseconds: 100));
  }
  debugPrint('WAIT_TIMEOUT $label');
}

Future<void> back() async {
  await T.binding.handlePopRoute();
  await settle();
}

Future<void> go(String route) async {
  router.go(route);
  await settle();
  await pumps(8);
}

/// 每个小节独立容错，单点失败不会中断整套截图流程。
Future<void> section(String name, Future<void> Function() body) async {
  debugPrint('SECTION_START $name');
  try {
    await body();
    debugPrint('SECTION_OK $name');
  } catch (error, stack) {
    debugPrint('SECTION_FAILED $name :: $error');
    debugPrint('$stack');
    // 尽量把应用拉回首页，避免后续小节连带失败。
    try {
      router.go(AppRoutes.home);
      await settle();
    } catch (_) {}
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ResetSelf full flow with screenshots', (tester) async {
    T = tester;
    tester.testTextInput.register();
    rootKey = GlobalKey();

    final container = ProviderContainer();
    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: UncontrolledProviderScope(
          container: container,
          child: const ResetSelfRoot(),
        ),
      ),
    );

    router = container.read(appRouterProvider);

    // ---------- 1. 首次进入 + 方法说明 ----------
    await section('01_onboarding', () async {
      await pumps(30, 100);
      await shot('s01_onboarding');
      await tap(find.text('晨间探索 → 日间观察 → 晚间综合 · 方法说明'));
      await shot('s02_method_note');
      await back();
    });

    // ---------- 2. 认知真空准备区 ----------
    await section('02_vacuum_prep', () async {
      await tap(find.text('先看认知真空准备区'));
      await pumps(10);
      await shot('s03_vacuum_top');
      await dragUp(420);
      await shot('s04_vacuum_mid');
      await dragUp(420);
      await shot('s05_vacuum_bottom');
      await dragDown(1200);
    });

    // ---------- 3. 真空专注 ----------
    await section('03_vacuum_focus', () async {
      await tap(find.widgetWithText(OutlinedButton, '先进入一段真空专注'));
      await pumps(8);
      await shot('s06_vacuum_focus_idle');
      await tap(find.text('开始这段专注'));
      await pumps(6);
      await shot('s07_vacuum_focus_active');
      await tap(find.text('结束这段专注'));
      await pumps(6);
      await back();
    });

    // ---------- 4. 晨间探索 ----------
    await section('04_morning', () async {
      await scrollTo(find.text('我准备好了，进入 24h 重构'));
      await tap(find.text('我准备好了，进入 24h 重构'));
      await pumps(14);
      await shot('s08_morning_top');
      await write(
        find.byType(TextField),
        '一种反复出现的迟钝不满：我把工具研究得很熟，却很少真正开始写。',
      );
      await tap(find.byType(FilterChip));
      await shot('s09_morning_answered');
      // “完成晨间挖掘”在固定底栏里，始终可见；这里改为向下滚动列表看后半段问题。
      await dragUp(800);
      await dragUp(800);
      await shot('s10_morning_bottom');
      await tap(find.text('完成晨间挖掘'));
      await pumps(8);
      await shot('s11_morning_saved_sheet');
      await tap(find.text('进入日间打断（白天观察）'));
      await pumps(10);
    });

    // ---------- 5. 日间观察 ----------
    await section('05_interrupt', () async {
      final settings = await container
          .read(userProfileRepositoryProvider)
          .getVacuumModeSettings();
      await container
          .read(userProfileRepositoryProvider)
          .saveVacuumModeSettings(settings.copyWith(interruptEnabled: false));
      container.invalidate(vacuumModeSettingsProvider);
      await settle();

      await pumps(10);
      await shot('s12_interrupt_top');
      await tap(find.text('选择／切换观察问题'));
      await pumps(8);
      await shot('s13_interrupt_questions');
      await tap(find.text('选择／切换观察问题'));
      await write(
        find.byType(TextField),
        '午休后我先打开了文档写下三行，然后再去看别的。精力状态也影响结果。',
      );
      await tap(find.text('成长性行为'));
      await pumps(4);
      await shot('s14_interrupt_input');
      await tap(find.byType(FilledButton));
      await pumps(12);
      await shot('s15_interrupt_history');
    });

    // ---------- 6. 晚间综合（11 步向导） ----------
    await section('06_setup_wizard', () async {
      await go(AppRoutes.restructureHub);
      await tap(find.text('继续晚间综合'));
      await pumps(12);
      await shot('s16_setup_step1');
      await tap(find.text('先回看晨间原稿与日间观察'));
      await pumps(8);
      await shot('s17_review_sheet');
      await back();

      const answers = [
        '继续把工具当成避难所，从不真正发布作品。',
        '也许是在保护自己不被他人的评价影响，但疲劳同样真实存在。',
        '「不公开发表」是一个可以被检验的假设。',
        '我练习并分享我的写作。',
        '写出自己的故事，并被读者看见。',
        '完成并发布第一篇文章。',
        '完成第一版内容框架，并练习三次。',
        '09:00 打开文档写 300 字\n20:00 练习一段场景',
        '打开文档，写下第一个标题。',
        '不以长期睡眠不足换取产出，保留与家人相处的时间。',
        '写作时把手机放到另一个房间。',
      ];
      const keys = [
        '反愿景（Anti-Vision）',
        '深层恐惧与自我保护',
        '内在敌人（内部模式）',
        '新身份叙事',
        '愿景 MVP',
        '一年镜头',
        '一月项目',
        '每日杠杆',
        '最小启动行动',
        '价值约束',
        '环境避坑规则',
      ];

      for (var i = 0; i < keys.length; i++) {
        await waitUntil(
          () => hasText(keys[i]) && textEnabled(),
          label: 'step-$i-${keys[i]}',
        );
        await write(find.byType(TextField), answers[i]);
        if (i == 2) await shot('s18_setup_step3');
        if (i == 7) await shot('s19_setup_step8');
        if (i == 10) await shot('s20_setup_step11');
        await waitUntil(filledEnabled, label: 'next-$i');
        await tap(find.byType(FilledButton));
        await pumps(4);
      }

      await pumps(30, 120);
      await shot('s21_home_top');
      await dragUp(500);
      await shot('s22_home_mid');
      await dragUp(500);
      await shot('s23_home_bottom');
      await dragDown(1600);
    });

    // ---------- 7. 每日校验 ----------
    await section('07_checkin', () async {
      await tap(find.text('进行今日校验'));
      await pumps(6);
      await shot('s24_checkin');
      await tap(find.text('部分偏离，动作没有完全走稳'));
      await pumps(4, 120);
      await shot('s25_checkin_done');
      await pumps(20, 120);
    });

    // ---------- 8. 行动反馈闭环 ----------
    await section('08_feedback', () async {
      await go(AppRoutes.actionFeedback);
      await pumps(8);
      await shot('s26_feedback_form');
      await write(
        find.byType(TextField).at(0),
        '按最小行动打开文档，写下第一个标题。',
      );
      await write(
        find.byType(TextField).at(1),
        '开始变得容易，但写完标题后又停下来去处理别的事。',
      );
      await write(
        find.byType(TextField).at(2),
        '「害怕被评价」这个解释还需要更多观察来支持。',
      );
      await write(find.byType(TextField).at(3), '把稿子发给一位信任的朋友。');
      await tap(find.text('保存记录'));
      await pumps(10);
      await shot('s27_feedback_saved');
    });

    // ---------- 9. SOS ----------
    await section('09_sos', () async {
      await go(AppRoutes.sos);
      await pumps(8);
      await shot('s28_sos');
      await tap(find.text('我感到焦虑，想逃避'));
      await pumps(10);
      await shot('s29_sos_done');
      await tap(find.text('先回首页，稍后再继续'));
      await settle();
    });

    // ---------- 10. 惯性样本库 ----------
    await section('10_insights', () async {
      await go(AppRoutes.insights);
      await pumps(10);
      await shot('s30_insights_all');
      await dragUp(600);
      await shot('s31_insights_cards');
      await dragUp(600);
      await shot('s32_insights_list');
    });

    // ---------- 11. 重构中枢 ----------
    await section('11_hub', () async {
      await go(AppRoutes.restructureHub);
      await pumps(10);
      await shot('s33_hub_top');
      await dragUp(560);
      await shot('s34_hub_mid');
      await dragUp(560);
      await shot('s35_hub_yearly');
      await dragDown(1600);

      await tap(find.text('重新做一次身份重构'));
      await pumps(8);
      await shot('s36_restart_sheet');
      await back();

      await tap(find.text('晨间原稿归档'));
      await pumps(8);
      await shot('s37_morning_history');
      await back();
    });

    // ---------- 12. 设置 ----------
    await section('12_settings', () async {
      await go(AppRoutes.settings);
      await pumps(10);
      await shot('s38_settings_top');
      await dragUp(380);
      await shot('s39_settings_resident');
      await dragUp(380);
      await shot('s40_settings_debug');
      await dragUp(380);
      await shot('s41_settings_backup');
    });

    // ---------- 13. 回到首页 ----------
    await section('13_home_final', () async {
      await go(AppRoutes.home);
      await pumps(10);
      await shot('s42_home_after_all');
    });

    debugPrint('TOTAL_SHOTS $_shotCount');
    // 给宿主机留出抓取时间
    await pumps(100, 100);
  });
}
