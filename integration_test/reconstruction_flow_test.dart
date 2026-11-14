import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:resetself/src/app/app.dart';
import 'package:resetself/src/app/navigation/app_router.dart';
import 'package:resetself/src/app/navigation/app_routes.dart';
import 'package:resetself/src/app/state/app_controller.dart';
import 'package:resetself/src/data/database/app_database.dart';
import 'package:resetself/src/data/database/database_providers.dart';
import 'package:resetself/src/features/vacuum/application/vacuum_mode_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android three phases, cross-day review, failed submit retry and feedback',
    (tester) async {
      // Keep programmatic text entry deterministic while retaining Android
      // rendering, navigation and native SQLite. Native IME behavior is outside
      // this test's scope.
      tester.testTextInput.register();
      // Use a separate SQLite file; existing app records are never reset.
      final temporary = await getTemporaryDirectory();
      final file = File(
        p.join(
          temporary.path,
          'flow_${DateTime.now().microsecondsSinceEpoch}.db',
        ),
      );
      final database = AppDatabase(pathOverride: file.path);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      final repository = container.read(userProfileRepositoryProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ResetSelfRoot(),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> write(Finder finder, String text) async {
        await tester.ensureVisible(finder);
        await tester.enterText(finder, text);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      Future<void> waitFor(bool Function() ready, String label) async {
        for (var attempt = 0; attempt < 100; attempt++) {
          if (ready()) {
            await tester.pumpAndSettle();
            return;
          }
          await tester.pump(const Duration(milliseconds: 100));
        }
        throw TestFailure('Timed out waiting for $label');
      }

      try {
        expect(find.text('欢迎来到\n认知真空区。'), findsOneWidget);
        await tap(find.text('开启 24h 重构向导'));
        await write(
          find.byType(TextField).first,
          'I research tools instead of writing; perhaps I fear evaluation.',
        );
        await tap(find.byType(FilterChip).first);
        await tap(find.text('完成晨间挖掘'));
        expect(find.text('晨间探索原稿已保存'), findsOneWidget);
        await tap(find.text('进入日间打断（白天观察）'));
        final settings = await repository.getVacuumModeSettings();
        await repository.saveVacuumModeSettings(
          settings.copyWith(interruptEnabled: false),
        );
        container.invalidate(vacuumModeSettingsProvider);
        await tester.pumpAndSettle();
        await write(
          find.byType(TextField),
          'After resting I wrote for ten minutes. Energy also mattered.',
        );
        await tap(find.byType(FilledButton));
        expect(
          (await repository.getTodayInterruptReflections()).single.statusTag,
          '未归类',
        );
        expect(
          (await repository.getTodayInterruptReflections())
              .single
              .promptSnapshot,
          isNotEmpty,
        );

        final db = await database.database;
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await db.update('exploration_state', {
          'started_at': yesterday.toIso8601String(),
        });
        await db.update(
          'inertia_sample',
          {'created_at': yesterday.toIso8601String()},
          where: 'source_type = ?',
          whereArgs: ['daytime_interrupt'],
        );
        container.read(appRouterProvider).go(AppRoutes.restructureHub);
        await tester.pumpAndSettle();
        await tap(find.text('继续晚间综合'));
        await tap(find.text('先回看晨间原稿与日间观察'));
        expect(find.textContaining('观察范围：'), findsOneWidget);
        expect(
          find.text(
            'After resting I wrote for ten minutes. Energy also mattered.',
          ),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        const answers = [
          'Keep choosing tools and never share writing.',
          'Maybe protecting myself from evaluation, but fatigue also matters.',
          'Avoiding public drafts is a hypothesis to test.',
          'I practice and share writing.',
          'Create stories and meet readers.',
          'Publish a collection.',
          'Complete and share the first essay.',
          '09:00 outline\n20:00 write a scene',
          'Open a document and write a title.',
          'Protect sleep and time with family.',
          'Place the phone away while writing.',
        ];
        const stepTitles = [
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
        for (var index = 0; index < answers.length; index++) {
          await waitFor(
            () =>
                find.text(stepTitles[index]).evaluate().isNotEmpty &&
                tester.widget<TextField>(find.byType(TextField)).enabled !=
                    false,
            'editable evening step $index; visible text: ${tester.widgetList<Text>(find.byType(Text)).map((widget) => widget.data).join(" | ")}',
          );
          if (index == 4) {
            await tap(find.text('稍后继续'));
            await tap(find.text('继续晚间综合'));
            await waitFor(
              () => find.text('愿景 MVP').evaluate().isNotEmpty,
              'restored evening step',
            );
            expect(
              (await repository.getRestructureDraft()).currentStepId,
              'vision',
            );
          }
          await write(find.byType(TextField), answers[index]);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            answers[index],
          );
          if (index < answers.length - 1) {
            await waitFor(
              () =>
                  tester
                      .widget<FilledButton>(find.byType(FilledButton))
                      .onPressed !=
                  null,
              'enabled next button at $index',
            );
            await tap(find.byType(FilledButton));
            await waitFor(
              () => find.text(stepTitles[index + 1]).evaluate().isNotEmpty,
              'next evening step after $index',
            );
          }
        }
        expect(find.text('环境避坑规则'), findsOneWidget);
        await waitFor(
          () =>
              tester
                  .widget<FilledButton>(find.byType(FilledButton))
                  .onPressed !=
              null,
          'enabled final submit button',
        );
        // Real native SQLite failure must leave the routed editor and draft intact.
        await db.execute(
          "CREATE TRIGGER fail_flow BEFORE INSERT ON identity_anchor BEGIN SELECT RAISE(ABORT, 'flow failure'); END",
        );
        await tap(find.byType(FilledButton));
        await waitFor(
          () => container.read(appControllerProvider).errorMessage != null,
          'failed submit result',
        );
        expect(find.text('环境避坑规则'), findsOneWidget);
        expect(find.text('欢迎来到\n认知真空区。'), findsNothing);
        expect(
          (await repository.getRestructureDraft()).constraints,
          answers.last,
        );
        expect(await repository.getRestructureArchiveRecords(), isEmpty);
        await db.execute('DROP TRIGGER fail_flow');
        await tap(find.byType(FilledButton));
        await waitFor(
          () => find.text('当前核心身份').evaluate().isNotEmpty,
          'successful submission home',
        );
        expect(find.text('当前核心身份'), findsOneWidget);
        expect(
          (await repository.getLatestRestructureRecord())!.monthProject,
          answers[6],
        );
        expect((await repository.getRestructureDraft()).hasAnyInput, isFalse);

        await tap(find.text('修改最小启动行动'));
        await write(find.byType(TextField).first, 'Write the first sentence.');
        await write(find.byType(TextField).last, 'Make starting easier.');
        await tap(find.text('确认保存'));
        expect(find.text('Write the first sentence.'), findsOneWidget);
        container.read(appRouterProvider).push(AppRoutes.actionFeedback);
        await tester.pumpAndSettle();
        await write(
          find.byType(TextField).first,
          'Wrote an opening; expected a whole draft.',
        );
        await write(
          find.byType(TextField).at(1),
          'Started easily but postponed sharing.',
        );
        await write(
          find.byType(TextField).at(2),
          'A trusted reader may help test the evaluation hypothesis.',
        );
        await write(
          find.byType(TextField).at(3),
          'Share a draft with one friend.',
        );
        await tap(find.text('保存记录'));
        final feedback = (await repository.getRecentActionFeedbacks()).single;
        expect(feedback.adjustment, 'Share a draft with one friend.');
        expect(feedback.directionSnapshot, contains(answers[6]));
        expect(
          feedback.directionSnapshot,
          contains('Write the first sentence.'),
        );
        await tap(find.text('修改最小启动行动'));
        await write(
          find.byType(TextField).at(4),
          'Send the draft to one trusted reader.',
        );
        await write(find.byType(TextField).last, 'Try feedback from a reader.');
        await tap(find.text('确认保存'));
        expect(
          (await repository.getCurrentProfile()).todayMinAction,
          'Send the draft to one trusted reader.',
        );
        expect(
          (await repository.getRecentActionFeedbacks())
              .single
              .directionSnapshot,
          contains('Write the first sentence.'),
        );
        expect(
          (await repository.getActionChanges()).last['reason'],
          'Make starting easier.',
        );

        container.read(appRouterProvider).go(AppRoutes.restructureHub);
        await tester.pumpAndSettle();
        await tap(find.text('重新做一次身份重构'));
        await tap(find.text('归档原稿，开始新探索'));
        await tap(find.text('归档并开始'));
        await waitFor(
          () => find.text('完成晨间挖掘').evaluate().isNotEmpty,
          'new morning exploration',
        );
        await waitFor(
          () => find.byType(TextField).evaluate().isNotEmpty,
          'loaded new morning form',
        );
        expect(
          (await repository.getMorningArchives()).single.reviewKeys.length,
          1,
        );
        expect(await repository.getMorningAnswers(), isEmpty);
        await write(
          find.byType(TextField).first,
          'Second exploration, after sharing.',
        );
        await tap(find.text('稍后继续'));
        await tap(find.text('晨间原稿归档'));
        await waitFor(
          () => find.text('查看原稿与观察').evaluate().isNotEmpty,
          'loaded morning archives',
        );
        await tap(find.text('查看原稿与观察'));
        await waitFor(
          () => find
              .textContaining('perhaps I fear evaluation.')
              .evaluate()
              .isNotEmpty,
          'loaded archive review',
        );
        expect(
          find.textContaining('perhaps I fear evaluation.'),
          findsOneWidget,
        );
        expect(find.textContaining('待回看 ·'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tap(find.text('恢复为当前稿'));
        await tap(find.text('归档当前并恢复'));
        await waitFor(
          () => find.text('恢复为当前稿').evaluate().isEmpty,
          'restored morning archive',
        );
        expect((await repository.getMorningArchives()).length, 2);
        expect(
          (await repository.getMorningAnswers()).values.single,
          contains('perhaps I fear evaluation.'),
        );
        expect(
          (await repository.getRecentActionFeedbacks()).single.adjustment,
          'Share a draft with one friend.',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
        expect(
          (await repository.getRecentActionFeedbacks()).single.adjustment,
          'Share a draft with one friend.',
        );
        expect(await repository.getMorningAnswers(), isNotEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await database.close();
        if (file.existsSync()) await file.delete();
        tester.testTextInput.unregister();
      }
    },
  );
}
