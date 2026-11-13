import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/copy/neutral_copy_engine.dart';
import '../database/app_database.dart';
import '../models/app_debug_snapshot.dart';
import '../models/backup_export_result.dart';
import '../models/backup_restore_result.dart';
import '../models/checkin_status.dart';
import '../models/daily_checkin.dart';
import '../models/deviation_pattern.dart';
import '../models/identity_anchor.dart';
import '../models/insight_trend_summary.dart';
import '../models/inertia_sample.dart';
import '../models/restructure_archive_record.dart';
import '../models/restructure_draft.dart';
import '../models/user_profile.dart';
import '../models/vacuum_focus_state.dart';
import '../models/vacuum_mode_settings.dart';
import '../models/weekly_review_summary.dart';
import '../models/yearly_archive_record.dart';
import '../models/yearly_report_summary.dart';

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
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
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
          'created_at': now.toIso8601String(),
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
        'vision_text': draft.visionText.trim(),
        'year_goal': draft.yearGoal.trim(),
        'month_project': draft.monthProject.trim(),
        'constraints': draft.constraints.trim(),
        'is_latest': 1,
        'create_year': year,
        'created_at': now,
      });

      final beliefId = await txn.insert('limiting_belief', {
        'content': draft.beliefDraft.trim(),
        'trigger_scene': draft.fearContent.trim(),
        'status': 'active',
        'created_at': now,
        'updated_at': now,
      });

      await txn.insert(
        'inertia_sample',
        {
          'source_type': 'manual',
          'status_tag': '首次重构',
          'content': '新的身份已落地：${draft.identityDraft.trim()}',
          'belief_ref_id': beliefId,
          'created_at': now,
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

      await _syncYearlyArchivesInTransaction(txn);
    });

    // 事务外把"新身份"沉淀进身份库，并同步为当前聚焦身份。
    await saveIdentityAnchors(
      [draft.identityDraft],
      source: IdentityAnchor.sourceRestructure,
    );
    await syncIdentityTextFromCurrentAnchor();
  }

  Future<void> saveDailyCheckin(CheckinStatus status) async {
    final db = await _database.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final today = nowIso.split('T').first;

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
          'created_at': nowIso,
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
          'created_at': nowIso,
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
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 日间打断：记录一次 3 分钟自省。
  ///
  /// [statusTag] 用来区分"成长性行为"还是"逃避性行为"，
  /// 便于后续月度/年度复盘时看清旧惯性最常出现的时段。
  Future<void> saveDaytimeInterruptReflection({
    required String promptLabel,
    required String content,
    required String statusTag,
  }) async {
    final db = await _database.database;

    await db.insert('inertia_sample', {
      'source_type': 'daytime_interrupt',
      'status_tag': statusTag,
      'content': content.trim().isEmpty ? promptLabel.trim() : content.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 今天已经留下过的日间打断自省。
  Future<List<InertiaSample>> getTodayInterruptReflections() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT id, source_type, status_tag, content, created_at
      FROM inertia_sample
      WHERE source_type = 'daytime_interrupt'
        AND date(created_at) = date('now', 'localtime')
      ORDER BY datetime(created_at) DESC
    ''');

    return rows.map(InertiaSample.fromMap).toList();
  }

  /// 最近一次身份重构记录，用于首页展示反愿景赌注与游戏化 6 组件。
  Future<RestructureArchiveRecord?> getLatestRestructureRecord() async {
    final db = await _database.database;
    final rows = await db.query(
      'restructure_record',
      where: 'is_latest = ?',
      whereArgs: const [1],
      orderBy: 'datetime(created_at) DESC, id DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return RestructureArchiveRecord.fromMap(rows.first);
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
      WHERE datetime(created_at) >= datetime('now', 'localtime', '-$days day')
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
      WHERE datetime(created_at) >= datetime('now', 'localtime', '-$days day')
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

  Future<List<RestructureArchiveRecord>> getRestructureArchiveRecords() async {
    final db = await _database.database;
    final rows = await db.query(
      'restructure_record',
      orderBy: 'is_latest DESC, datetime(created_at) DESC, id DESC',
    );

    return rows.map(RestructureArchiveRecord.fromMap).toList();
  }

  Future<List<YearlyArchiveRecord>> getYearlyArchiveRecords() async {
    await _syncYearlyArchives();

    final db = await _database.database;
    final rows = await db.query(
      'yearly_archive',
      orderBy: 'archive_year DESC, id DESC',
    );

    return rows.map(YearlyArchiveRecord.fromMap).toList();
  }

  Future<List<YearlyReportSummary>> getYearlyReportSummaries() async {
    final archives = await getYearlyArchiveRecords();
    return archives.map(_buildYearlyReportSummary).toList();
  }

  Future<BackupExportResult> exportLocalBackup() async {
    await _syncYearlyArchives();

    final db = await _database.database;
    final databasePath = await _database.databasePath;
    final backupDirectory = await _ensureBackupDirectory();

    final exportedAt = DateTime.now();
    final backupFile = File(
      p.join(
        backupDirectory.path,
        'resetself_backup_${_buildBackupTimestampKey(exportedAt)}.json',
      ),
    );

    const tableNames = [
      'user_profile',
      'restructure_record',
      'limiting_belief',
      'daily_checkin',
      'inertia_sample',
      'restructure_draft',
      'vacuum_mode_settings',
      'vacuum_focus_state',
      'yearly_archive',
      'identity_anchor',
    ];

    final tables = <String, Object?>{};
    var recordCount = 0;
    for (final tableName in tableNames) {
      final rows = await db.query(tableName);
      tables[tableName] = rows;
      recordCount += rows.length;
    }

    final payload = <String, Object?>{
      'app': 'ResetSelf',
      'schema_version': AppDatabase.dbVersion,
      'exported_at': exportedAt.toIso8601String(),
      'database_path': databasePath,
      'table_count': tableNames.length,
      'record_count': recordCount,
      'tables': tables,
    };

    await backupFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );

    return BackupExportResult(
      filePath: backupFile.path,
      exportedAt: exportedAt,
      tableCount: tableNames.length,
      recordCount: recordCount,
    );
  }

  Future<BackupRestoreResult> restoreLatestBackup() async {
    final backupDirectory = await _ensureBackupDirectory();
    final files = backupDirectory
        .listSync()
        .whereType<File>()
        .where((file) => p.extension(file.path).toLowerCase() == '.json')
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    if (files.isEmpty) {
      throw StateError('还没有找到可恢复的本地备份文件。');
    }

    final backupFile = files.first;
    final content = await backupFile.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('备份文件格式不可识别，暂时无法恢复。');
    }

    final tableMap = decoded['tables'];
    if (tableMap is! Map<String, dynamic>) {
      throw StateError('备份文件里没有可恢复的数据表。');
    }

    final db = await _database.database;
    final recordCount = decoded['record_count'] as int? ?? 0;
    final tableCount = decoded['table_count'] as int? ?? tableMap.length;

    await db.transaction((txn) async {
      await _clearTablesForRestore(txn);
      await _restoreTablesInTransaction(txn, tableMap);
    });

    return BackupRestoreResult(
      filePath: backupFile.path,
      restoredAt: DateTime.now(),
      tableCount: tableCount,
      recordCount: recordCount,
    );
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
      WHERE check_date >= date('now', 'localtime', '-6 day')
    ''');
    final sampleResult = await db.rawQuery('''
      SELECT
        COUNT(*) AS sample_count,
        SUM(CASE WHEN source_type = 'sos' THEN 1 ELSE 0 END) AS sos_count,
        SUM(CASE WHEN source_type = 'vacuum_focus' THEN 1 ELSE 0 END) AS vacuum_focus_count
      FROM inertia_sample
      WHERE datetime(created_at) >= datetime('now', 'localtime', '-7 day')
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
      WHERE datetime(created_at) >= datetime('now', 'localtime', '-7 day')
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
      WHERE datetime(created_at) >= datetime('now', 'localtime', '-7 day')
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
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _syncYearlyArchives() async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _syncYearlyArchivesInTransaction(txn);
    });
  }

  Future<void> _syncYearlyArchivesInTransaction(Transaction txn) async {
    final rows = await txn.query(
      'restructure_record',
      orderBy: 'create_year DESC, datetime(created_at) DESC, id DESC',
    );

    final latestByYear = <int, Map<String, Object?>>{};
    for (final row in rows) {
      final year = row['create_year'] as int?;
      if (year == null || latestByYear.containsKey(year)) {
        continue;
      }
      latestByYear[year] = row;
    }

    for (final entry in latestByYear.entries) {
      final year = entry.key;
      final row = entry.value;
      final sampleCountResult = await txn.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM inertia_sample
        WHERE strftime('%Y', created_at) = ?
        ''',
        [year.toString()],
      );
      final sampleCount = Sqflite.firstIntValue(sampleCountResult) ?? 0;

      final checkinResult = await txn.rawQuery(
        '''
        SELECT
          SUM(CASE WHEN match_status = 'match' THEN 1 ELSE 0 END) AS match_count,
          SUM(CASE WHEN match_status = 'partial' THEN 1 ELSE 0 END) AS partial_count,
          SUM(CASE WHEN match_status = 'full_deviation' THEN 1 ELSE 0 END) AS full_count
        FROM daily_checkin
        WHERE strftime('%Y', check_date) = ?
        ''',
        [year.toString()],
      );
      final checkinRow = checkinResult.first;
      final matchCount = (checkinRow['match_count'] as int?) ?? 0;
      final partialCount = (checkinRow['partial_count'] as int?) ?? 0;
      final fullCount = (checkinRow['full_count'] as int?) ?? 0;

      await txn.insert(
        'yearly_archive',
        {
          'archive_year': year,
          'identity_snapshot': row['identity_draft'] as String? ?? '',
          'belief_snapshot': row['belief_draft'] as String? ?? '',
          'sample_count': sampleCount,
          'checkin_stability': _buildYearlyCheckinStability(
            matchCount: matchCount,
            partialCount: partialCount,
            fullDeviationCount: fullCount,
          ),
          'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  String _buildYearlyCheckinStability({
    required int matchCount,
    required int partialCount,
    required int fullDeviationCount,
  }) {
    final total = matchCount + partialCount + fullDeviationCount;
    if (total == 0) {
      return '这一年还没有留下每日校验记录。';
    }

    if (matchCount >= partialCount + fullDeviationCount) {
      return '这一年以稳定回流为主，累计 $matchCount 次完全匹配。';
    }

    if (fullDeviationCount > matchCount) {
      return '这一年出现过较多明显偏离，但这些记录已经被沉淀成样本。';
    }

    return '这一年更多处在拉扯与回稳之间，累计 $partialCount 次部分偏离。';
  }

  YearlyReportSummary _buildYearlyReportSummary(YearlyArchiveRecord archive) {
    final identity = archive.identitySnapshot.trim();
    final belief = archive.beliefSnapshot.trim();
    final identityLine = identity.isEmpty ? '这一年还没有沉淀出明确身份快照。' : '这一年的身份锚点是：$identity';
    final beliefLine = belief.isEmpty ? '限制性信念还没有被单独归档。' : '当年主要松动的旧信念是：$belief';
    final stability = archive.checkinStability;
    final sampleCount = archive.sampleCount;

    return YearlyReportSummary(
      archiveYear: archive.archiveYear,
      title: '${archive.archiveYear} 年的变化摘要',
      body:
          '$identityLine $stability 这一年共沉淀了 $sampleCount 条惯性样本与回流记录。$beliefLine',
      highlight: _buildYearlyHighlight(archive),
    );
  }

  String _buildYearlyHighlight(YearlyArchiveRecord archive) {
    return NeutralCopyEngine.yearlyHighlight(
      sampleCount: archive.sampleCount,
      checkinStability: archive.checkinStability,
    );
  }

  Future<Directory> _ensureBackupDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final backupDirectory = Directory(
      p.join(documentsDirectory.path, 'backups'),
    );
    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }
    return backupDirectory;
  }

  Future<void> _clearTablesForRestore(Transaction txn) async {
    const deleteOrder = [
      'inertia_sample',
      'daily_checkin',
      'yearly_archive',
      'limiting_belief',
      'restructure_record',
      'restructure_draft',
      'vacuum_focus_state',
      'vacuum_mode_settings',
      'identity_anchor',
      'user_profile',
    ];

    for (final tableName in deleteOrder) {
      await txn.delete(tableName);
    }
  }

  Future<void> _restoreTablesInTransaction(
    Transaction txn,
    Map<String, dynamic> tableMap,
  ) async {
    const insertOrder = [
      'identity_anchor',
      'user_profile',
      'restructure_record',
      'limiting_belief',
      'daily_checkin',
      'inertia_sample',
      'restructure_draft',
      'vacuum_mode_settings',
      'vacuum_focus_state',
      'yearly_archive',
    ];

    for (final tableName in insertOrder) {
      final rows = tableMap[tableName];
      if (rows is! List) {
        continue;
      }

      for (final row in rows) {
        if (row is! Map) {
          continue;
        }

        final mappedRow = <String, Object?>{};
        for (final entry in row.entries) {
          mappedRow[entry.key.toString()] = entry.value;
        }
        await txn.insert(
          tableName,
          mappedRow,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  String _buildBackupTimestampKey(DateTime time) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$year$month${day}_$hour$minute$second';
  }

  // ========== 身份库 identity_anchor ==========

  /// 列出所有"激活态"身份卡（最多 5 条，按 sort_order 升序）。
  Future<List<IdentityAnchor>> getActiveIdentityAnchors() async {
    final db = await _database.database;
    final rows = await db.query(
      'identity_anchor',
      where: 'is_active = ?',
      whereArgs: const [1],
      orderBy: 'sort_order ASC, id ASC',
      limit: IdentityAnchor.maxActiveAnchors,
    );
    return rows.map(IdentityAnchor.fromMap).toList();
  }

  /// 查出当前聚焦的那一条，没有就回退到第一条激活身份。
  Future<IdentityAnchor?> getCurrentIdentityAnchor() async {
    final db = await _database.database;
    final profileRows = await db.query(
      'user_profile',
      orderBy: 'id ASC',
      limit: 1,
    );
    final currentId = profileRows.isEmpty
        ? null
        : profileRows.first['current_anchor_id'] as int?;

    if (currentId != null) {
      final hits = await db.query(
        'identity_anchor',
        where: 'id = ? AND is_active = 1',
        whereArgs: [currentId],
        limit: 1,
      );
      if (hits.isNotEmpty) {
        return IdentityAnchor.fromMap(hits.first);
      }
    }

    final fallback = await getActiveIdentityAnchors();
    return fallback.isEmpty ? null : fallback.first;
  }

  /// 把一组身份语句保存为激活身份库。会按 5 条上限和去重收敛。
  /// 返回最终入库的激活身份列表，方便调用方做后续切换。
  Future<List<IdentityAnchor>> saveIdentityAnchors(
    List<String> texts, {
    String source = IdentityAnchor.sourceManual,
  }) async {
    final db = await _database.database;
    final now = DateTime.now();

    final deduped = <String>[];
    for (final text in texts) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) continue;
      if (deduped.contains(trimmed)) continue;
      deduped.add(trimmed);
      if (deduped.length >= IdentityAnchor.maxActiveAnchors) break;
    }

    return await db.transaction((txn) async {
      final existing = await txn.query(
        'identity_anchor',
        where: 'is_active = 1',
        orderBy: 'sort_order ASC, id ASC',
        limit: IdentityAnchor.maxActiveAnchors,
      );

      final existingTexts = existing
          .map((row) => (row['anchor_text'] as String?) ?? '')
          .toList();

      // 不在新列表里的旧条目归档（is_active=0），保留追溯。
      final removedIds = <int>[];
      for (final row in existing) {
        final id = row['id'] as int;
        final text = (row['anchor_text'] as String?) ?? '';
        if (!deduped.contains(text)) {
          removedIds.add(id);
        }
      }

      for (final id in removedIds) {
        await txn.update(
          'identity_anchor',
          {
            'is_active': 0,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // 按顺序写入新条目；已存在的保留 id，仅在 text 不一致时更新。
      final saved = <IdentityAnchor>[];
      for (var i = 0; i < deduped.length; i++) {
        final text = deduped[i];
        final existingIndex = existingTexts.indexOf(text);
        if (existingIndex >= 0) {
          final id = existing[existingIndex]['id'] as int;
          await txn.update(
            'identity_anchor',
            {
              'sort_order': i,
              'is_active': 1,
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          saved.add(
            IdentityAnchor(
              id: id,
              anchorText: text,
              source: (existing[existingIndex]['source'] as String?) ??
                  source,
              isActive: true,
              sortOrder: i,
              createdAt: existingIndex >= 0 && existing.isNotEmpty
                  ? DateTime.tryParse(
                          (existing[existingIndex]['created_at'] as String?) ??
                              '') ??
                      now
                  : now,
              updatedAt: now,
            ),
          );
        } else {
          final insertId = await txn.insert('identity_anchor', {
            'anchor_text': text,
            'source': source,
            'is_active': 1,
            'sort_order': i,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          saved.add(
            IdentityAnchor(
              id: insertId,
              anchorText: text,
              source: source,
              isActive: true,
              sortOrder: i,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }

      // 默认聚焦：保持当前指针有效；无效则回退到第一条。
      final profile = await txn.query(
        'user_profile',
        orderBy: 'id ASC',
        limit: 1,
      );
      int? focusId =
          profile.isEmpty ? null : profile.first['current_anchor_id'] as int?;
      if (focusId == null || saved.every((a) => a.id != focusId)) {
        focusId = saved.isNotEmpty ? saved.first.id : null;
        await txn.update(
          'user_profile',
          {
            'current_anchor_id': focusId,
            'updated_at': now.toIso8601String(),
          },
        );
      }

      return saved;
    });
  }

  /// 切换"今日聚焦身份"指针。
  Future<void> setCurrentIdentityAnchor(int anchorId) async {
    final db = await _database.database;
    await db.update(
      'user_profile',
      {
        'current_anchor_id': anchorId,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 把当前聚焦的 anchor 文本同步回 user_profile.identity_text，保留向后兼容。
  Future<void> syncIdentityTextFromCurrentAnchor() async {
    final db = await _database.database;
    final anchor = await getCurrentIdentityAnchor();
    if (anchor == null) return;
    final now = DateTime.now();
    await db.update(
      'user_profile',
      {
        'identity_text': anchor.anchorText,
        'updated_at': now.toIso8601String(),
      },
    );
  }
}
