import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/app_debug_snapshot.dart';
import '../models/checkin_status.dart';
import '../models/daily_checkin.dart';
import '../models/deviation_pattern.dart';
import '../models/insight_trend_summary.dart';
import '../models/inertia_sample.dart';
import '../models/restructure_draft.dart';
import '../models/user_profile.dart';
import '../models/vacuum_focus_state.dart';
import '../models/vacuum_mode_settings.dart';
import '../models/weekly_review_summary.dart';

class UserProfileRepository {
  UserProfileRepository(this._database);

  final AppDatabase _database;

  Future<void> ensureSingleProfile() async {
    final db = await _database.database;
    final result = await db.query('user_profile', limit: 1);

    if (result.isNotEmpty) {
      return;
    }

    await db.insert('user_profile', {
      'id': 1,
      'identity_text': '',
      'today_min_action': '',
      'status': UserProfileStatus.uninit.value,
    });
  }

  Future<UserProfile> getCurrentProfile() async {
    final db = await _database.database;
    final rows = await db.query(
      'user_profile',
      orderBy: 'id ASC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return UserProfile.empty();
    }

    return UserProfile.fromMap(rows.first);
  }

  Future<RestructureDraft> getRestructureDraft() async {
    final db = await _database.database;
    final rows = await db.query(
      'restructure_draft',
      where: 'id = ?',
      whereArgs: const [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return RestructureDraft.empty();
    }

    return RestructureDraft.fromMap(rows.first);
  }

  Future<VacuumModeSettings> getVacuumModeSettings() async {
    final db = await _database.database;
    final rows = await db.query(
      'vacuum_mode_settings',
      where: 'id = ?',
      whereArgs: const [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      final defaults = VacuumModeSettings.defaults();
      await saveVacuumModeSettings(defaults);
      return defaults;
    }

    return VacuumModeSettings.fromMap(rows.first);
  }

  Future<void> saveVacuumModeSettings(VacuumModeSettings settings) async {
    final db = await _database.database;
    await db.insert(
      'vacuum_mode_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<VacuumFocusState> getVacuumFocusState() async {
    final db = await _database.database;
    final rows = await db.query(
      'vacuum_focus_state',
      where: 'id = ?',
      whereArgs: const [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return VacuumFocusState.inactive();
    }

    return VacuumFocusState.fromMap(rows.first);
  }

  Future<void> startVacuumFocus(VacuumModeSettings settings) async {
    final db = await _database.database;
    final currentState = await getVacuumFocusState();
    final now = DateTime.now();

    await db.insert(
      'vacuum_focus_state',
      VacuumFocusState(
        isActive: true,
        startedAt: now,
        plannedEndAt: now.add(
          Duration(minutes: settings.focusWindowMinutes),
        ),
        lastEndedAt: currentState.lastEndedAt,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> stopVacuumFocus() async {
    final db = await _database.database;
    final currentState = await getVacuumFocusState();
    final now = DateTime.now();

    await db.transaction((txn) async {
      if (currentState.isActive) {
        final rows = await txn.query(
          'user_profile',
          where: 'id = ?',
          whereArgs: const [1],
          limit: 1,
        );
        final minAction = rows.isEmpty
            ? ''
            : rows.first['today_min_action'] as String? ?? '';
        final actualMinutes = currentState.startedAt == null
            ? null
            : now.difference(currentState.startedAt!).inMinutes.clamp(1, 999);
        final focusSummary = actualMinutes == null
            ? '完成了一段真空专注。'
            : '完成了一段 $actualMinutes 分钟真空专注。';
        final returnSummary = minAction.trim().isEmpty
            ? '现在回到今天这一个动作。'
            : '现在回到：${minAction.trim()}';

        await txn.insert('inertia_sample', {
          'source_type': 'vacuum_focus',
          'status_tag': '专注完成',
          'content': '$focusSummary$returnSummary',
        });
      }

      await txn.insert(
        'vacuum_focus_state',
        VacuumFocusState.inactive(
          lastEndedAt: currentState.isActive ? now : currentState.lastEndedAt,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> saveRestructureDraft(RestructureDraft draft) async {
    final db = await _database.database;

    await db.insert(
      'restructure_draft',
      draft.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> submitInitialRestructure(RestructureDraft draft) async {
    if (!draft.isReadyToSubmit) {
      throw StateError('首次重构内容还不完整，暂时无法提交。');
    }

    final db = await _database.database;
    final year = DateTime.now().year;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await _ensureSingleProfileInTransaction(txn);

      await txn.update(
        'user_profile',
        {
          'identity_text': draft.identityDraft.trim(),
          'today_min_action': draft.minActionDraft.trim(),
          'status': UserProfileStatus.finished.value,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: const [1],
      );

      await txn.update(
        'restructure_record',
        {'is_latest': 0},
        where: 'is_latest = ?',
        whereArgs: const [1],
      );

      final restructureRecordId = await txn.insert('restructure_record', {
        'anti_vision': draft.antiVision.trim(),
        'fear_content': draft.fearContent.trim(),
        'belief_draft': draft.beliefDraft.trim(),
        'identity_draft': draft.identityDraft.trim(),
        'min_action_draft': draft.minActionDraft.trim(),
        'is_latest': 1,
        'create_year': year,
      });

      final beliefId = await txn.insert('limiting_belief', {
        'content': draft.beliefDraft.trim(),
        'trigger_scene': draft.fearContent.trim(),
        'status': 'active',
        'updated_at': now,
      });

      await txn.insert(
        'inertia_sample',
        {
          'source_type': 'manual',
          'status_tag': '首次重构',
          'content': '新的身份已落地：${draft.identityDraft.trim()}',
          'belief_ref_id': beliefId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'restructure_draft',
        where: 'id = ?',
        whereArgs: const [1],
      );

      await txn.update(
        'restructure_record',
        {'is_latest': 1},
        where: 'id = ?',
        whereArgs: [restructureRecordId],
      );
    });
  }

  Future<void> saveDailyCheckin(CheckinStatus status) async {
    final db = await _database.database;
    final today = DateTime.now().toIso8601String().split('T').first;

    await db.transaction((txn) async {
      final existing = await txn.query(
        'daily_checkin',
        where: 'check_date = ?',
        whereArgs: [today],
        limit: 1,
      );

      if (existing.isEmpty) {
        await txn.insert('daily_checkin', {
          'check_date': today,
          'match_status': status.value,
          'system_comment': status.systemComment,
        });
      } else {
        await txn.update(
          'daily_checkin',
          {
            'match_status': status.value,
            'system_comment': status.systemComment,
          },
          where: 'check_date = ?',
          whereArgs: [today],
        );
      }

      await txn.delete(
        'inertia_sample',
        where: "source_type = ? AND date(created_at) = date('now', 'localtime')",
        whereArgs: const ['daily_checkin'],
      );

      if (status.shouldCreateSample) {
        await txn.insert('inertia_sample', {
          'source_type': 'daily_checkin',
          'status_tag': status.sampleStatusTag,
          'content': status.systemComment,
        });
      }
    });
  }

  Future<void> saveSosSample(String label) async {
    final db = await _database.database;

    await db.insert('inertia_sample', {
      'source_type': 'sos',
      'status_tag': 'SOS急救',
      'content': label.trim(),
    });
  }

  Future<DailyCheckin?> getTodayCheckin() async {
    final db = await _database.database;
    final today = DateTime.now().toIso8601String().split('T').first;
    final rows = await db.query(
      'daily_checkin',
      where: 'check_date = ?',
      whereArgs: [today],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return DailyCheckin.fromMap(rows.first);
  }

  Future<int> getRecentSampleCount({int days = 7}) async {
    final db = await _database.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM inertia_sample
      WHERE datetime(created_at) >= datetime('now', '-$days day')
    ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<InertiaSample?> getLatestSample() async {
    final db = await _database.database;
    final rows = await db.query(
      'inertia_sample',
      orderBy: 'datetime(created_at) DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return InertiaSample.fromMap(rows.first);
  }

  Future<List<InertiaSample>> getRecentSamples({
    int days = 7,
    int limit = 20,
    String? sourceType,
  }) async {
    final db = await _database.database;
    final buffer = StringBuffer('''
      SELECT id, source_type, status_tag, content, created_at
      FROM inertia_sample
      WHERE datetime(created_at) >= datetime('now', '-$days day')
    ''');
    final whereArgs = <Object?>[];

    if (sourceType != null && sourceType.isNotEmpty) {
      buffer.write(' AND source_type = ?');
      whereArgs.add(sourceType);
    }

    buffer.write(' ORDER BY datetime(created_at) DESC LIMIT $limit');

    final rows = await db.rawQuery(buffer.toString(), whereArgs);

    return rows.map(InertiaSample.fromMap).toList();
  }

  Future<AppDebugSnapshot> getDebugSnapshot() async {
    final db = await _database.database;
    final databasePath = await _database.databasePath;
    final totalSampleCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) AS total FROM inertia_sample'),
        ) ??
        0;
    final dailyCheckinCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) AS total FROM daily_checkin'),
        ) ??
        0;
    final latestCheckinResult = await db.rawQuery('''
      SELECT check_date
      FROM daily_checkin
      ORDER BY check_date DESC
      LIMIT 1
    ''');
    final draft = await getRestructureDraft();

    return AppDebugSnapshot(
      databasePath: databasePath,
      totalSampleCount: totalSampleCount,
      recentSampleCount: await getRecentSampleCount(),
      dailyCheckinCount: dailyCheckinCount,
      hasDraft: draft.hasAnyInput,
      latestCheckinDate: latestCheckinResult.isEmpty
          ? null
          : latestCheckinResult.first['check_date'] as String?,
    );
  }

  Future<WeeklyReviewSummary> getWeeklyReviewSummary() async {
    final db = await _database.database;
    final checkinResult = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN match_status = 'match' THEN 1 ELSE 0 END) AS match_count,
        SUM(CASE WHEN match_status = 'partial' THEN 1 ELSE 0 END) AS partial_count,
        SUM(CASE WHEN match_status = 'full_deviation' THEN 1 ELSE 0 END) AS full_count
      FROM daily_checkin
      WHERE check_date >= date('now', '-6 day')
    ''');
    final sampleResult = await db.rawQuery('''
      SELECT
        COUNT(*) AS sample_count,
        SUM(CASE WHEN source_type = 'sos' THEN 1 ELSE 0 END) AS sos_count,
        SUM(CASE WHEN source_type = 'vacuum_focus' THEN 1 ELSE 0 END) AS vacuum_focus_count
      FROM inertia_sample
      WHERE datetime(created_at) >= datetime('now', '-7 day')
    ''');

    final checkinRow = checkinResult.first;
    final sampleRow = sampleResult.first;

    return WeeklyReviewSummary(
      matchCount: (checkinRow['match_count'] as int?) ?? 0,
      partialCount: (checkinRow['partial_count'] as int?) ?? 0,
      fullDeviationCount: (checkinRow['full_count'] as int?) ?? 0,
      sosCount: (sampleRow['sos_count'] as int?) ?? 0,
      vacuumFocusCount: (sampleRow['vacuum_focus_count'] as int?) ?? 0,
      sampleCount: (sampleRow['sample_count'] as int?) ?? 0,
    );
  }

  Future<List<DeviationPattern>> getTopDeviationPatterns({int limit = 3}) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT
        source_type,
        status_tag,
        content,
        COUNT(*) AS hit_count
      FROM inertia_sample
      WHERE datetime(created_at) >= datetime('now', '-7 day')
        AND source_type IN ('daily_checkin', 'sos')
      GROUP BY source_type, status_tag, content
      ORDER BY hit_count DESC, datetime(MAX(created_at)) DESC
      LIMIT $limit
    ''');

    return rows.map((row) {
      final sourceType = row['source_type'] as String? ?? '';
      final statusTag = row['status_tag'] as String? ?? '';
      final content = row['content'] as String? ?? '';
      final hitCount = row['hit_count'] as int? ?? 0;
      final label = sourceType == 'sos'
          ? (content.isEmpty ? 'SOS 波动' : content)
          : (statusTag.isEmpty ? '每日偏离' : statusTag);
      final summary = sourceType == 'sos'
          ? '这一类情绪波动最近共出现 $hitCount 次'
          : '这种日常偏离最近共出现 $hitCount 次';

      return DeviationPattern(
        label: label,
        count: hitCount,
        sourceType: sourceType,
        summary: summary,
      );
    }).toList();
  }

  Future<InsightTrendSummary> getInsightTrendSummary() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN source_type = 'daily_checkin' THEN 1 ELSE 0 END) AS daily_count,
        SUM(CASE WHEN source_type = 'sos' THEN 1 ELSE 0 END) AS sos_count,
        SUM(CASE WHEN source_type = 'manual' THEN 1 ELSE 0 END) AS manual_count,
        SUM(CASE WHEN source_type = 'vacuum_focus' THEN 1 ELSE 0 END) AS vacuum_focus_count
      FROM inertia_sample
      WHERE datetime(created_at) >= datetime('now', '-7 day')
    ''');
    final row = rows.first;

    return InsightTrendSummary(
      dailyDeviationCount: (row['daily_count'] as int?) ?? 0,
      sosCount: (row['sos_count'] as int?) ?? 0,
      restructureCount: (row['manual_count'] as int?) ?? 0,
      vacuumFocusCount: (row['vacuum_focus_count'] as int?) ?? 0,
    );
  }

  Future<void> resetToOnboarding() async {
    final db = await _database.database;

    await db.transaction((txn) async {
      await _ensureSingleProfileInTransaction(txn);

      await txn.update(
        'user_profile',
        {
          'identity_text': '',
          'today_min_action': '',
          'status': UserProfileStatus.uninit.value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: const [1],
      );

      await txn.update('restructure_record', {'is_latest': 0});
      await txn.delete('restructure_draft', where: 'id = ?', whereArgs: const [1]);
      await txn.delete(
        'vacuum_focus_state',
        where: 'id = ?',
        whereArgs: const [1],
      );
    });
  }

  Future<void> _ensureSingleProfileInTransaction(Transaction txn) async {
    final rows = await txn.query('user_profile', limit: 1);
    if (rows.isNotEmpty) {
      return;
    }

    await txn.insert('user_profile', {
      'id': 1,
      'identity_text': '',
      'today_min_action': '',
      'status': UserProfileStatus.uninit.value,
    });
  }
}
