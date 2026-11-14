import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:resetself/src/data/database/app_database.dart';
import 'package:resetself/src/data/models/restructure_draft.dart';
import 'package:resetself/src/data/repositories/user_profile_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const completeDraft = RestructureDraft(
  antiVision: 'staying stuck',
  fearContent: 'possibly protecting myself',
  beliefDraft: 'a hypothesis',
  identityDraft: 'I practice writing',
  minActionDraft: 'write a title',
  dailyLevers: 'outline\nwrite a scene',
  visionText: 'share my writing',
  yearGoal: 'publish a collection',
  monthProject: 'finish an essay',
  constraints: 'put phone away',
  valueConstraints: 'protect sleep',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late AppDatabase database;
  late UserProfileRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('resetself_db_test_');
    database = AppDatabase(pathOverride: p.join(directory.path, 'test.db'));
    repository = UserProfileRepository(database);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
  });
  tearDown(() async {
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await directory.delete(recursive: true);
  });

  for (var version = 1; version <= 12; version++) {
    test(
      'real SQLite v$version upgrades preserving existing meanings',
      () async {
        // Reconstruct the actual versioned differences, then reopen using the
        // production onUpgrade callback. This exercises SQL, not model defaults.
        final db = await database.database;
        await repository.ensureSingleProfile();
        await repository.saveRestructureDraft(completeDraft);
        await db.insert('restructure_record', {
          'identity_draft': 'old identity',
          'constraints': 'old environment rule',
          'anti_vision': 'old anti vision',
          'is_latest': 1,
        });
        await db.insert('inertia_sample', {
          'source_type': 'daytime_interrupt',
          'content': 'old observation',
          'status_tag': '待核对',
          'created_at': '2026-11-13 10:00:00',
        });
        await db.execute('DROP TABLE morning_archive');
        await db.execute('DROP TABLE action_change');
        await db.execute(
          'ALTER TABLE exploration_state DROP COLUMN review_question_keys',
        );
        await db.execute(
          'ALTER TABLE restructure_draft DROP COLUMN current_step_id',
        );
        await db.execute(
          'ALTER TABLE restructure_draft DROP COLUMN change_reason',
        );
        await db.execute(
          'ALTER TABLE restructure_record DROP COLUMN change_reason',
        );
        if (version < 12) {
          await db.execute('DROP TABLE exploration_state');
          await db.execute('ALTER TABLE inertia_sample DROP COLUMN prompt_id');
          await db.execute(
            'ALTER TABLE inertia_sample DROP COLUMN prompt_snapshot',
          );
          await db.execute(
            'ALTER TABLE action_feedback DROP COLUMN direction_snapshot',
          );
        }
        if (version < 11) await db.execute('DROP TABLE action_feedback');
        if (version < 10) {
          await db.execute(
            'ALTER TABLE restructure_record DROP COLUMN daily_levers',
          );
          await db.execute(
            'ALTER TABLE restructure_draft DROP COLUMN daily_levers',
          );
        }
        if (version < 9) {
          await db.execute('DROP TABLE restructure_morning_answer');
        }
        if (version < 8) {
          await db.execute(
            'ALTER TABLE restructure_record DROP COLUMN value_constraints',
          );
          await db.execute(
            'ALTER TABLE restructure_draft DROP COLUMN value_constraints',
          );
        }
        if (version < 6) {
          for (final column in [
            'vision_text',
            'year_goal',
            'month_project',
            'constraints',
          ]) {
            await db.execute(
              'ALTER TABLE restructure_record DROP COLUMN $column',
            );
            await db.execute(
              'ALTER TABLE restructure_draft DROP COLUMN $column',
            );
          }
          await db.execute(
            'ALTER TABLE vacuum_mode_settings DROP COLUMN interrupt_enabled',
          );
          await db.execute(
            'ALTER TABLE vacuum_mode_settings DROP COLUMN interrupt_times',
          );
        }
        if (version < 5) {
          await db.execute(
            'ALTER TABLE user_profile DROP COLUMN current_anchor_id',
          );
          await db.execute('DROP TABLE identity_anchor');
        }
        if (version == 6) {
          await db.execute(
            'ALTER TABLE user_profile DROP COLUMN current_anchor_id',
          );
        }
        if (version < 4) await db.execute('DROP TABLE vacuum_focus_state');
        if (version < 3) await db.execute('DROP TABLE vacuum_mode_settings');
        if (version < 2) await db.execute('DROP TABLE restructure_draft');
        await db.setVersion(version);
        await database.close();
        final upgraded = await database.database;
        expect(await upgraded.getVersion(), AppDatabase.dbVersion);
        expect((await repository.getCurrentProfile()).identityText, '');
        final record = (await repository.getRestructureArchiveRecords()).single;
        expect(record.identityDraft, 'old identity');
        expect(record.antiVision, 'old anti vision');
        expect(record.constraints, version >= 6 ? 'old environment rule' : '');
        expect(record.valueConstraints, '');
        expect(record.changeReason, '');
        expect((await repository.getRestructureDraft()).currentStepId, 'anti');
        expect(await repository.getMorningReviewKeys(), isEmpty);
        final observations = await repository.getInterruptReflections(
          start: DateTime(2026, 11, 13),
          end: DateTime(2026, 11, 13),
        );
        expect(observations.single.content, 'old observation');
        expect(observations.single.promptSnapshot, isNull);
        await repository.saveActionFeedback(
          attempted: 'new attempt',
          happened: '',
          insight: '',
          adjustment: '',
          directionSnapshot: 'new context',
        );
        expect(
          (await repository.getRecentActionFeedbacks())
              .single
              .directionSnapshot,
          'new context',
        );
        await repository.saveMorningAnswers({'q1': 'new morning'});
        expect(await repository.getMorningExplorationStartedAt(), isNotNull);
      },
    );
  }

  test('local inclusive days handle ISO offsets and exact boundaries', () async {
    final db = await database.database;
    final start = DateTime(2026, 11, 13);
    final endExclusive = DateTime(2026, 11, 15);
    final entries = {
      'before': start
          .subtract(const Duration(microseconds: 1))
          .toIso8601String(),
      'start': start.toUtc().toIso8601String(),
      'previous day': DateTime(2026, 11, 13, 23, 59).toIso8601String(),
      'next day': DateTime(2026, 11, 14, 12).toIso8601String(),
      'end': endExclusive.toIso8601String(),
      'invalid': 'invalid timestamp',
    };
    // Same instant encoded using an explicit +02:00 offset.
    final instant = DateTime(2026, 11, 14, 5).toUtc();
    entries['offset'] =
        '${instant.add(const Duration(hours: 2)).toIso8601String().replaceAll('Z', '')}+02:00';
    for (final entry in entries.entries) {
      await db.insert('inertia_sample', {
        'source_type': 'daytime_interrupt',
        'content': entry.key,
        'created_at': entry.value,
      });
    }
    final records = await repository.getInterruptReflections(
      start: start,
      end: DateTime(2026, 11, 14),
    );
    expect(records.map((r) => r.content).toSet(), {
      'start',
      'previous day',
      'next day',
      'offset',
    });
    expect(records.first.content, 'next day');
  });

  test(
    'morning start remains stable across edits and reset clears it',
    () async {
      await repository.saveMorningAnswers({'q1': 'first', 'q2': 'second'});
      final started = await repository.getMorningExplorationStartedAt();
      await repository.saveMorningAnswers({'q1': 'latest', 'q2': ''});
      expect(await repository.getMorningExplorationStartedAt(), started);
      expect(await repository.getMorningAnswers(), {'q1': 'latest'});
      await repository.clearMorningAnswers();
      expect(await repository.getMorningAnswers(), isEmpty);
      expect(await repository.getMorningExplorationStartedAt(), isNull);
    },
  );

  test(
    'new backup roundtrip and old backup without context preserve text',
    () async {
      await repository.ensureSingleProfile();
      await repository.saveMorningAnswers({'q1': 'original thought'});
      await repository.saveRestructureDraft(completeDraft);
      await repository.saveDaytimeInterruptReflection(
        content: 'an observation',
        statusTag: '未归类',
        promptId: 'prompt1',
        promptSnapshot: 'what happened?',
      );
      await repository.saveActionFeedback(
        attempted: 'write',
        happened: 'a draft',
        insight: 'need practice',
        adjustment: 'share it',
        directionSnapshot: 'old project',
      );
      final started = await repository.getMorningExplorationStartedAt();
      final backup = await repository.exportLocalBackup();
      await repository.clearMorningAnswers();
      await repository.saveMorningAnswers({'q1': 'overwrite'});
      await repository.restoreLatestBackup();
      expect(await repository.getMorningAnswers(), {'q1': 'original thought'});
      expect(await repository.getMorningExplorationStartedAt(), started);
      expect(
        (await repository.getRestructureDraft()).dailyLevers,
        completeDraft.dailyLevers,
      );
      expect(
        (await repository.getRecentActionFeedbacks()).single.directionSnapshot,
        'old project',
      );
      expect(
        (await repository.getTodayInterruptReflections()).single.promptSnapshot,
        'what happened?',
      );

      final file = File(backup.filePath);
      final payload =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final tables = payload['tables'] as Map<String, dynamic>;
      tables.remove('exploration_state');
      tables.remove('morning_archive');
      tables.remove('action_change');
      for (final row in tables['restructure_draft'] as List) {
        (row as Map).remove('current_step_id');
        row.remove('change_reason');
      }
      for (final row in tables['restructure_record'] as List) {
        (row as Map).remove('change_reason');
      }
      for (final row in tables['inertia_sample'] as List) {
        (row as Map).remove('prompt_id');
        row.remove('prompt_snapshot');
      }
      for (final row in tables['action_feedback'] as List) {
        (row as Map).remove('direction_snapshot');
      }
      payload['schema_version'] = 11;
      await file.writeAsString(jsonEncode(payload));
      await repository.restoreLatestBackup();
      expect(await repository.getMorningAnswers(), {'q1': 'original thought'});
      expect(await repository.getMorningExplorationStartedAt(), isNull);
      expect(await repository.getMorningReviewKeys(), isEmpty);
      expect(await repository.getMorningArchives(), isEmpty);
      expect(await repository.getActionChanges(), isEmpty);
      expect((await repository.getRestructureDraft()).currentStepId, 'anti');
      expect(
        (await repository.getRecentActionFeedbacks()).single.directionSnapshot,
        isNull,
      );
      expect(
        (await repository.getTodayInterruptReflections()).single.promptSnapshot,
        isNull,
      );
    },
  );

  test('submission rolls back all tables if identity insertion fails', () async {
    await repository.ensureSingleProfile();
    await repository.saveRestructureDraft(completeDraft);
    final db = await database.database;
    await db.execute(
      "CREATE TRIGGER fail_anchor BEFORE INSERT ON identity_anchor BEGIN SELECT RAISE(ABORT, 'simulated disk failure'); END",
    );
    await expectLater(
      repository.submitInitialRestructure(completeDraft),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repository.getRestructureArchiveRecords(), isEmpty);
    expect(
      (await repository.getRestructureDraft()).identityDraft,
      completeDraft.identityDraft,
    );
    expect(
      (await repository.getCurrentProfile()).hasCompletedInitialRestructure,
      isFalse,
    );
    expect(await db.query('inertia_sample'), isEmpty);
    await db.execute('DROP TRIGGER fail_anchor');
    await repository.submitInitialRestructure(completeDraft);
    expect(
      (await repository.getCurrentProfile()).hasCompletedInitialRestructure,
      isTrue,
    );
    expect(
      (await repository.getCurrentIdentityAnchor())!.anchorText,
      completeDraft.identityDraft,
    );
    expect((await repository.getRestructureDraft()).hasAnyInput, isFalse);
    await repository.updateTodayMinAction('write the first sentence');
    expect(
      (await repository.getCurrentProfile()).todayMinAction,
      'write the first sentence',
    );
    expect(
      (await repository.getLatestRestructureRecord())!.minActionDraft,
      'write a title',
    );
  });

  test(
    'archive restores marks and text, preserves formal records and rolls back replacement',
    () async {
      await repository.submitInitialRestructure(completeDraft);
      await repository.saveMorningAnswers(
        {'q1': 'first batch'},
        reviewKeys: {'q2'},
      );
      await repository.saveRestructureDraft(
        completeDraft.copyWith(
          currentStepId: 'vision',
          changeReason: 'new evidence',
        ),
      );
      final started = await repository.getMorningExplorationStartedAt();
      final db = await database.database;
      await db.execute(
        "CREATE TRIGGER fail_archive BEFORE INSERT ON morning_archive BEGIN SELECT RAISE(ABORT, 'archive failure'); END",
      );
      await expectLater(
        repository.archiveCurrentMorningAndStartNew(),
        throwsA(isA<DatabaseException>()),
      );
      expect(await repository.getMorningAnswers(), {'q1': 'first batch'});
      expect((await repository.getRestructureDraft()).currentStepId, 'vision');
      await db.execute('DROP TRIGGER fail_archive');
      await repository.archiveCurrentMorningAndStartNew();
      final archive = (await repository.getMorningArchives()).single;
      expect(archive.answers, {'q1': 'first batch'});
      expect(archive.reviewKeys, {'q2'});
      expect(archive.startedAt, started);
      expect(await repository.getMorningAnswers(), isEmpty);
      expect((await repository.getRestructureDraft()).hasAnyInput, isFalse);
      await repository.saveMorningAnswers(
        {'q3': 'second batch'},
        reviewKeys: {'q3'},
      );
      await repository.saveRestructureDraft(
        completeDraft.copyWith(currentStepId: 'action'),
      );
      await db.execute(
        "CREATE TRIGGER fail_restore_morning BEFORE INSERT ON restructure_morning_answer BEGIN SELECT RAISE(ABORT, 'restore failure'); END",
      );
      await expectLater(
        repository.archiveCurrentMorningAndStartNew(
          restoreArchiveId: archive.id,
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(await repository.getMorningAnswers(), {'q3': 'second batch'});
      expect((await repository.getRestructureDraft()).currentStepId, 'action');
      expect((await repository.getMorningArchives()).length, 1);
      await db.execute('DROP TRIGGER fail_restore_morning');
      await repository.archiveCurrentMorningAndStartNew(
        restoreArchiveId: archive.id,
      );
      expect(await repository.getMorningAnswers(), {'q1': 'first batch'});
      expect(await repository.getMorningReviewKeys(), {'q2'});
      expect((await repository.getMorningArchives()).length, 2);
      expect(
        (await repository.getLatestRestructureRecord())!.monthProject,
        completeDraft.monthProject,
      );
      await repository.clearMorningAnswers();
      await repository.archiveCurrentMorningAndStartNew();
      expect((await repository.getMorningArchives()).length, 2);
      await repository.saveMorningAnswers({}, reviewKeys: {'q4'});
      await repository.archiveCurrentMorningAndStartNew();
      expect((await repository.getMorningArchives()).first.reviewKeys, {'q4'});
    },
  );

  test(
    'step, optional reasons and history survive backups; action update is atomic',
    () async {
      final draft = completeDraft.copyWith(
        currentStepId: 'constraints',
        changeReason: 'feedback changed my plan',
      );
      await repository.saveRestructureDraft(draft);
      await repository.submitInitialRestructure(draft);
      expect(
        (await repository.getLatestRestructureRecord())!.changeReason,
        draft.changeReason,
      );
      await repository.saveRestructureDraft(draft);
      await repository.saveMorningAnswers(
        {'q1': 'archived'},
        reviewKeys: {'q2'},
      );
      await repository.archiveCurrentMorningAndStartNew();
      await repository.saveRestructureDraft(draft);
      final db = await database.database;
      await db.execute(
        "CREATE TRIGGER fail_action BEFORE INSERT ON action_change BEGIN SELECT RAISE(ABORT, 'action failure'); END",
      );
      await expectLater(
        repository.updateTodayMinAction('new step', reason: 'less energy'),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        (await repository.getCurrentProfile()).todayMinAction,
        completeDraft.minActionDraft,
      );
      await db.execute('DROP TRIGGER fail_action');
      await repository.updateTodayMinAction('new step', reason: 'less energy');
      await repository.updateTodayMinAction('new step', reason: 'unchanged');
      expect((await repository.getActionChanges()).length, 1);
      await repository.exportLocalBackup();
      await repository.clearAllData();
      await repository.restoreLatestBackup();
      expect(
        (await repository.getRestructureDraft()).currentStepId,
        'constraints',
      );
      expect(
        (await repository.getRestructureDraft()).changeReason,
        draft.changeReason,
      );
      expect(
        (await repository.getActionChanges()).single['reason'],
        'less energy',
      );
      expect((await repository.getMorningArchives()).single.reviewKeys, {'q2'});
    },
  );
}
