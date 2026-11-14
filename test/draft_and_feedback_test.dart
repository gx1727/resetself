import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resetself/src/app/state/app_controller.dart';
import 'package:resetself/src/app/navigation/app_router.dart';
import 'package:resetself/src/app/navigation/app_routes.dart';
import 'package:resetself/src/data/models/user_profile.dart';
import 'package:resetself/src/core/widgets/draft_save_controller.dart';
import 'package:resetself/src/data/database/app_database.dart';
import 'package:resetself/src/data/database/database_providers.dart';
import 'package:resetself/src/data/models/restructure_draft.dart';
import 'package:resetself/src/data/models/restructure_archive_record.dart';
import 'package:resetself/src/data/models/inertia_sample.dart';
import 'package:resetself/src/data/models/vacuum_mode_settings.dart';
import 'package:resetself/src/features/interrupt/presentation/daytime_interrupt_page.dart';
import 'package:resetself/src/features/restructure/presentation/exploration_review_sheet.dart';
import 'package:resetself/src/features/vacuum/application/vacuum_mode_providers.dart';
import 'package:resetself/src/features/feedback/application/action_feedback_providers.dart';
import 'package:resetself/src/features/feedback/presentation/action_feedback_page.dart';
import 'package:resetself/src/features/home/application/home_providers.dart';
import 'package:resetself/src/features/restructure/presentation/restructure_morning_page.dart';
import 'package:resetself/src/features/restructure/presentation/restructure_setup_page.dart';
import 'package:resetself/src/data/repositories/user_profile_repository.dart';

class _Repository extends UserProfileRepository {
  _Repository() : super(AppDatabase());
  bool fail = false;
  Map<String, String> morning = {};
  Set<String> reviewKeys = {};
  RestructureDraft draft = RestructureDraft.empty();
  final List<String> feedback = [];
  final List<String?> contexts = [];
  final List<(String, String, String?)> observations = [];
  DateTime? rangeStart;
  DateTime? rangeEnd;

  @override
  Future<DateTime?> getMorningExplorationStartedAt() async =>
      DateTime.now().subtract(const Duration(days: 1));

  @override
  Future<List<InertiaSample>> getInterruptReflections({
    required DateTime start,
    required DateTime end,
  }) async {
    if (fail) throw StateError('unavailable');
    rangeStart = start;
    rangeEnd = end;
    return [
      InertiaSample(
        id: 1,
        sourceType: 'daytime_interrupt',
        statusTag: '待核对',
        content: 'yesterday observation',
        createdAt: start,
        promptSnapshot: 'a previous question',
      ),
    ];
  }

  @override
  Future<void> saveDaytimeInterruptReflection({
    required String content,
    required String statusTag,
    String? promptId,
    String? promptSnapshot,
  }) async {
    observations.add((content, statusTag, promptSnapshot));
  }

  @override
  Future<Map<String, String>> getMorningAnswers() async => Map.of(morning);

  @override
  Future<Set<String>> getMorningReviewKeys() async => Set.of(reviewKeys);

  @override
  Future<void> saveMorningAnswers(
    Map<String, String> answers, {
    Set<String>? reviewKeys,
  }) async {
    if (fail) throw StateError('disk unavailable');
    morning = Map.of(answers);
    if (reviewKeys != null) this.reviewKeys = Set.of(reviewKeys);
  }

  @override
  Future<RestructureDraft> getRestructureDraft() async => draft;

  @override
  Future<void> saveRestructureDraft(RestructureDraft value) async {
    if (fail) throw StateError('disk unavailable');
    draft = value;
  }

  @override
  Future<void> saveActionFeedback({
    required String attempted,
    required String happened,
    required String insight,
    required String adjustment,
    String? directionSnapshot,
  }) async {
    if (fail) throw StateError('disk unavailable');
    feedback.add(attempted);
    contexts.add(directionSnapshot);
  }
}

void main() {
  testWidgets(
    'evening resumes saved step and saves next and previous positions',
    (tester) async {
      final repository = _Repository()
        ..draft = RestructureDraft.empty().copyWith(
          currentStepId: 'vision',
          visionText: 'a direction',
          changeReason: 'experience',
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
            appControllerProvider.overrideWith((ref) => AppController.test()),
          ],
          child: const MaterialApp(home: RestructureSetupPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('愿景 MVP'), findsOneWidget);
      await tester.tap(find.text('保存并进入下一步'));
      await tester.pumpAndSettle();
      expect(repository.draft.currentStepId, 'yearGoal');
      expect(repository.draft.changeReason, 'experience');
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      expect(repository.draft.currentStepId, 'vision');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'a direction',
      );
    },
  );

  testWidgets(
    'morning marks unanswered questions and restores marks on reload',
    (tester) async {
      final repository = _Repository();
      Widget app() => ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: RestructureMorningPage()),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final chip = find.byType(FilterChip).first;
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(repository.reviewKeys.length, 1);
      expect(
        repository.morning.values.every((answer) => answer.isEmpty),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilterChip>(find.byType(FilterChip).first).selected,
        isTrue,
      );
    },
  );
  testWidgets(
    'controller updates preserve routed draft even with a save error',
    (tester) async {
      final controller = AppController.test(
        profile: UserProfile.empty(),
        errorMessage: 'save failed',
      );
      final container = ProviderContainer(
        overrides: [
          appControllerProvider.overrideWith((ref) => controller),
          userProfileRepositoryProvider.overrideWithValue(_Repository()),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.restructureSetup);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'keep this draft open',
      );
      await controller.init();
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider), same(router));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'keep this draft open',
      );
    },
  );
  test(
    'flush serializes writes and saves edits made during an older write',
    () async {
      final first = Completer<void>();
      final writes = <String>[];
      final saver = DraftSaveController<String>(
        delay: const Duration(days: 1),
        write: (value) async {
          writes.add(value);
          if (value == 'old') await first.future;
        },
        onChanged: () {},
      );
      addTearDown(saver.dispose);
      saver.update('old');
      final flushing = saver.flush();
      await Future<void>.delayed(Duration.zero);
      saver.update('new');
      final concurrentFlush = saver.flush();
      first.complete();
      expect(await flushing, isTrue);
      expect(await concurrentFlush, isTrue);
      expect(writes, ['old', 'new']);
      expect(saver.isDirty, isFalse);
      expect(saver.isSaving, isFalse);
    },
  );

  test('failed snapshot stays dirty until retry succeeds', () async {
    var fail = true;
    var saved = '';
    final saver = DraftSaveController<String>(
      delay: const Duration(days: 1),
      write: (value) async {
        if (fail) throw StateError('disk unavailable');
        saved = value;
      },
      onChanged: () {},
    );
    addTearDown(saver.dispose);
    saver.update('latest');
    expect(await saver.flush(), isFalse);
    expect(saver.error, isNotNull);
    expect(saver.isDirty, isTrue);
    fail = false;
    expect(await saver.flush(), isTrue);
    expect(saved, 'latest');
    expect(saver.error, isNull);
  });

  testWidgets(
    'feedback enables on first input, keeps failed input and saves again',
    (tester) async {
      final repository = _Repository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
            recentActionFeedbacksProvider.overrideWith((ref) async => []),
            latestRestructureRecordProvider.overrideWith((ref) async => null),
            appControllerProvider.overrideWith((ref) => AppController.test()),
          ],
          child: const MaterialApp(home: ActionFeedbackPage()),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      final button = find.widgetWithText(FilledButton, '保存记录');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.enterText(fields.at(0), 'write a draft');
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      await tester.enterText(fields.at(0), '');
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.enterText(fields.at(0), 'retry this');
      repository.fail = true;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repository.feedback, isEmpty);
      expect(
        tester.widget<TextField>(fields.at(0)).controller!.text,
        'retry this',
      );
      repository.fail = false;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repository.feedback, ['retry this']);
      await tester.ensureVisible(fields.at(0));
      await tester.enterText(fields.at(0), 'next attempt');
      await tester.pump();
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repository.feedback, ['retry this', 'next attempt']);
    },
  );

  for (final morning in [true, false]) {
    for (final systemBack in [true, false]) {
      testWidgets(
        '${morning ? 'morning' : 'evening'} flushes last input on quick ${systemBack ? 'system back' : 'header exit'}',
        (tester) async {
          final repository = _Repository();
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, _) => Scaffold(
                  body: TextButton(
                    onPressed: () => context.push('/draft'),
                    child: const Text('open draft'),
                  ),
                ),
              ),
              GoRoute(
                path: '/draft',
                builder: (_, _) => morning
                    ? const RestructureMorningPage()
                    : const RestructureSetupPage(),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                userProfileRepositoryProvider.overrideWithValue(repository),
                appControllerProvider.overrideWith(
                  (ref) => AppController.test(),
                ),
              ],
              child: MaterialApp.router(routerConfig: router),
            ),
          );
          await tester.tap(find.text('open draft'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextField).first,
            'last rapid edit',
          );
          // No wait for the 500ms debounce.
          if (systemBack) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(find.byIcon(Icons.chevron_left_rounded));
          }
          await tester.pumpAndSettle();
          expect(find.text('open draft'), findsOneWidget);
          expect(
            morning
                ? repository.morning.values.first
                : repository.draft.antiVision,
            'last rapid edit',
          );
        },
      );
    }
    testWidgets(
      '${morning ? 'morning' : 'evening'} failed exit stays and retries',
      (tester) async {
        final repository = _Repository()..fail = true;
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.push('/draft'),
                  child: const Text('open'),
                ),
              ),
            ),
            GoRoute(
              path: '/draft',
              builder: (_, _) => morning
                  ? const RestructureMorningPage()
                  : const RestructureSetupPage(),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProfileRepositoryProvider.overrideWithValue(repository),
              appControllerProvider.overrideWith((ref) => AppController.test()),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).first,
          'must survive failure',
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('还有内容没有保存'), findsOneWidget);
        expect(find.text('晨间探索原稿已保存'), findsNothing);
        await tester.tap(find.text('继续填写'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          'must survive failure',
        );
        repository.fail = false;
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('open'), findsOneWidget);
        expect(
          morning
              ? repository.morning.values.first
              : repository.draft.antiVision,
          'must survive failure',
        );
      },
    );
  }

  testWidgets(
    'notification off still saves unclassified observation and question',
    (tester) async {
      final repository = _Repository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
            vacuumModeSettingsProvider.overrideWith(
              (ref) async => VacuumModeSettings.defaults().copyWith(
                interruptEnabled: false,
              ),
            ),
            todayInterruptReflectionsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: DaytimeInterruptPage(initialPromptId: 'interrupt_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'I rested; not sure about the motive');
      await tester.pump();
      final save = find.byType(FilledButton);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        repository.observations.single.$1,
        'I rested; not sure about the motive',
      );
      expect(repository.observations.single.$2, '未归类');
      expect(repository.observations.single.$3, isNotEmpty);
    },
  );

  testWidgets(
    'review loads yesterday by default and exposes load failure retry',
    (tester) async {
      final repository = _Repository()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExplorationReviewSheet(
                includeObservations: true,
                onEditMorning: () {},
                onAddObservation: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('材料读取失败，点此重试'), findsOneWidget);
      expect(find.textContaining('这段时间尚无日间记录'), findsNothing);
      repository.fail = false;
      await tester.tap(find.text('材料读取失败，点此重试'));
      await tester.pumpAndSettle();
      expect(
        repository.rangeStart!.day,
        DateTime.now().subtract(const Duration(days: 1)).day,
      );
      expect(repository.rangeEnd!.day, DateTime.now().day);
      expect(find.text('yesterday observation'), findsOneWidget);
      expect(find.textContaining('a previous question'), findsOneWidget);
    },
  );

  testWidgets(
    'feedback holds direction at first edit when current direction changes',
    (tester) async {
      final repository = _Repository();
      RestructureArchiveRecord direction(String project) =>
          RestructureArchiveRecord(
            id: 1,
            antiVision: '',
            fearContent: '',
            beliefDraft: '',
            identityDraft: '',
            minActionDraft: '',
            isLatest: true,
            createYear: 2026,
            createdAt: DateTime.now(),
            monthProject: project,
          );
      var current = direction('original essay project');
      final container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repository),
          recentActionFeedbacksProvider.overrideWith((ref) async => []),
          latestRestructureRecordProvider.overrideWith((ref) async => current),
          appControllerProvider.overrideWith((ref) => AppController.test()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ActionFeedbackPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'write the opening');
      await tester.pump();
      current = direction('new unrelated project');
      container.invalidate(latestRestructureRecordProvider);
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, '保存记录');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.contexts.single, contains('original essay project'));
      expect(
        repository.contexts.single,
        isNot(contains('new unrelated project')),
      );
    },
  );
}
