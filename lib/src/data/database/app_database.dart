import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({this.pathOverride});

  final String? pathOverride;
  static const dbName = 'resetself_v1.db';
  static const dbVersion = 13;

  Database? _database;
  Future<Database>? _databaseFuture;
  String? _databasePath;

  Future<Database> get database {
    final existing = _database;
    if (existing != null) {
      return Future.value(existing);
    }

    // 缓存"打开中的 Future"，避免并发调用各自 openDatabase 同一个文件而报错。
    return _databaseFuture ??= _openDatabase().then((opened) {
      _database = opened;
      return opened;
    });
  }

  Future<String> get databasePath async {
    if (pathOverride != null) return pathOverride!;
    final existing = _databasePath;
    if (existing != null) {
      return existing;
    }

    final databasesPath = await getDatabasesPath();
    final resolvedPath = path.join(databasesPath, dbName);
    _databasePath = resolvedPath;
    return resolvedPath;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<void> close() async {
    final existing = _database;
    _database = null;
    _databaseFuture = null;

    if (existing == null) {
      return;
    }

    await existing.close();
  }

  Future<Database> _openDatabase() async {
    final databasePath = await this.databasePath;

    return openDatabase(
      databasePath,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrateSchema(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identity_text TEXT NOT NULL DEFAULT '',
        today_min_action TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'uninit',
        current_anchor_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_user_single ON user_profile(id);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS restructure_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anti_vision TEXT,
        fear_content TEXT,
        belief_draft TEXT,
        identity_draft TEXT,
        min_action_draft TEXT,
        daily_levers TEXT,
        vision_text TEXT,
        year_goal TEXT,
        month_project TEXT,
        constraints TEXT,
        value_constraints TEXT,
        is_latest INTEGER DEFAULT 0,
        create_year INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS limiting_belief (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        trigger_scene TEXT,
        status TEXT DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_checkin (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        check_date TEXT NOT NULL,
        match_status TEXT NOT NULL,
        system_comment TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(check_date)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inertia_sample (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_type TEXT NOT NULL,
        status_tag TEXT,
        content TEXT,
        belief_ref_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (belief_ref_id) REFERENCES limiting_belief(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS yearly_archive (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        archive_year INTEGER NOT NULL,
        identity_snapshot TEXT,
        belief_snapshot TEXT,
        sample_count INTEGER DEFAULT 0,
        checkin_stability TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(archive_year)
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inertia_time ON inertia_sample(created_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_checkin_date ON daily_checkin(check_date);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_belief_status ON limiting_belief(status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_archive_year ON yearly_archive(archive_year);',
    );

    await _createDraftTable(db);
    await _createVacuumSettingsTable(db);
    await _createVacuumFocusStateTable(db);
    await _createIdentityAnchorTable(db);
    await _createMorningAnswerTable(db);
    await _createActionFeedbackTable(db);
    await _addExplorationContext(db);
    await _addExplorationHistory(db);
  }

  Future<void> _migrateSchema(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _createDraftTable(db);
    }

    if (oldVersion < 3 && newVersion >= 3) {
      await _createVacuumSettingsTable(db);
    }

    if (oldVersion < 4 && newVersion >= 4) {
      await _createVacuumFocusStateTable(db);
    }

    if (oldVersion < 5 && newVersion >= 5) {
      await _addCurrentAnchorIdToUserProfile(db);
      await _createIdentityAnchorTable(db);
      await _seedIdentityAnchorsFromProfile(db);
    }

    if (oldVersion < 6 && newVersion >= 6) {
      await _addRestructureComponentColumns(db);
      await _addInterruptColumnsToVacuumSettings(db);
    }

    if (oldVersion < 7 && newVersion >= 7) {
      // v6 的全新安装走 onCreate，建表时漏了 current_anchor_id，这里统一补齐。
      await _addCurrentAnchorIdToUserProfile(db);
    }

    if (oldVersion < 8 && newVersion >= 8) {
      // v8：区分"价值约束"与既有的"环境避坑规则"。
      // 旧 constraints 的避坑语义保持不变，只新增 value_constraints 承载价值约束。
      await _addValueConstraintsColumns(db);
    }

    if (oldVersion < 9 && newVersion >= 9) {
      // v9：晨间 14 问的探索原稿独立存储，与晚间综合结论分开。
      await _createMorningAnswerTable(db);
    }

    if (oldVersion < 10 && newVersion >= 10) {
      // v10：区分原文的「每日杠杆」（2–3 项行动）与产品的「最小启动行动」。
      await _addDailyLeversColumns(db);
    }

    if (oldVersion < 11 && newVersion >= 11) {
      // v11：落地原文的行动反馈闭环记录：
      // 尝试了什么 → 发生了什么 → 得到什么认识 → 下一次调整什么。
      await _createActionFeedbackTable(db);
    }
    if (oldVersion < 12 && newVersion >= 12) {
      await _addExplorationContext(db);
    }
    if (oldVersion < 13 && newVersion >= 13) {
      await _addExplorationHistory(db);
    }
  }

  Future<void> _addExplorationHistory(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'exploration_state',
      column: 'review_question_keys',
      definition: "TEXT NOT NULL DEFAULT '[]'",
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_draft',
      column: 'current_step_id',
      definition: "TEXT NOT NULL DEFAULT 'anti'",
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_draft',
      column: 'change_reason',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_record',
      column: 'change_reason',
      definition: 'TEXT',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS morning_archive (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at TEXT,
        archived_at TEXT NOT NULL,
        answers_json TEXT NOT NULL,
        review_keys_json TEXT NOT NULL DEFAULT '[]'
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS action_change (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        previous_action TEXT NOT NULL,
        new_action TEXT NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL
      );
    ''');
  }

  /// Optional context only; old records retain their original meaning.
  Future<void> _addExplorationContext(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'inertia_sample',
      column: 'prompt_id',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'inertia_sample',
      column: 'prompt_snapshot',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'action_feedback',
      column: 'direction_snapshot',
      definition: 'TEXT',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exploration_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        started_at TEXT NOT NULL
      );
    ''');
  }

  /// v10：为重构草稿与重构记录补充「每日杠杆」字段。
  ///
  /// 原文建议为明天的 2–3 个行动安排时间块；既有的 `min_action_draft`
  /// 继续承载产品适配的「最小启动行动」，两者不再混用。
  Future<void> _addDailyLeversColumns(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'restructure_record',
      column: 'daily_levers',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_draft',
      column: 'daily_levers',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
  }

  /// v9：晨间"心理挖掘"阶段的探索原稿。
  ///
  /// 与 [restructure_draft]、[restructure_record] 的区别：
  /// 前者保存的是晚间综合后的结论与六组件；
  /// 这里保存的是晨间 14 问的原始回答，用于区分"探索原稿"与"综合结论"。
  Future<void> _createMorningAnswerTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS restructure_morning_answer (
        question_key TEXT PRIMARY KEY,
        answer TEXT NOT NULL DEFAULT '',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  /// v11：行动反馈闭环记录。
  ///
  /// 对齐规范 §8.1 建议的产品记录模板：
  /// 「尝试了什么 → 发生了什么 → 得到什么认识 → 下一次调整什么」。
  /// 只记录主观文本与时间，不派生分数或排名。
  Future<void> _createActionFeedbackTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS action_feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempted TEXT NOT NULL DEFAULT '',
        happened TEXT NOT NULL DEFAULT '',
        insight TEXT NOT NULL DEFAULT '',
        adjustment TEXT NOT NULL DEFAULT '',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_action_feedback_time ON action_feedback(created_at);',
    );
  }

  /// v8：为重构草稿与重构记录补充「价值约束」字段。
  ///
  /// 建议沿用原文六组件里 Constraints 的含义：为了愿景不愿牺牲的边界。
  /// 既有的 `constraints` 字段继续承载「环境避坑规则」，不改写历史答案的意思。
  Future<void> _addValueConstraintsColumns(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'restructure_record',
      column: 'value_constraints',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_draft',
      column: 'value_constraints',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
  }

  /// v6：把单日重构从 5 步升级为完整协议后，补齐游戏化 6 组件字段。
  Future<void> _addRestructureComponentColumns(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'restructure_record',
      column: 'vision_text',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_record',
      column: 'year_goal',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_record',
      column: 'month_project',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_record',
      column: 'constraints',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_draft',
      column: 'vision_text',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_draft',
      column: 'year_goal',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_draft',
      column: 'month_project',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'restructure_draft',
      column: 'constraints',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
  }

  /// v6：落地"日间打断"能力后，真空设置里补充打断开关与打断时点。
  Future<void> _addInterruptColumnsToVacuumSettings(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'vacuum_mode_settings',
      column: 'interrupt_enabled',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      table: 'vacuum_mode_settings',
      column: 'interrupt_times',
      definition: "TEXT NOT NULL DEFAULT '11:00,13:30,15:15,17:00,19:30,21:00'",
    );
  }

  Future<void> _addColumnIfMissing(
    DatabaseExecutor db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table);');
    final hasColumn = columns.any((row) => (row['name'] as String?) == column);
    if (!hasColumn) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition;');
    }
  }

  Future<void> _createDraftTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS restructure_draft (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        anti_vision TEXT NOT NULL DEFAULT '',
        fear_content TEXT NOT NULL DEFAULT '',
        belief_draft TEXT NOT NULL DEFAULT '',
        identity_draft TEXT NOT NULL DEFAULT '',
        min_action_draft TEXT NOT NULL DEFAULT '',
        daily_levers TEXT NOT NULL DEFAULT '',
        vision_text TEXT NOT NULL DEFAULT '',
        year_goal TEXT NOT NULL DEFAULT '',
        month_project TEXT NOT NULL DEFAULT '',
        constraints TEXT NOT NULL DEFAULT '',
        value_constraints TEXT NOT NULL DEFAULT '',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  Future<void> _createVacuumSettingsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vacuum_mode_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        focus_window_minutes INTEGER NOT NULL DEFAULT 90,
        noise_cut_enabled INTEGER NOT NULL DEFAULT 1,
        gentle_reminder_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_time TEXT NOT NULL DEFAULT '21:30',
        focus_rhythm_label TEXT NOT NULL DEFAULT '每晚一次温和提醒',
        interrupt_enabled INTEGER NOT NULL DEFAULT 1,
        interrupt_times TEXT NOT NULL DEFAULT '11:00,13:30,15:15,17:00,19:30,21:00',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  Future<void> _createVacuumFocusStateTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vacuum_focus_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_active INTEGER NOT NULL DEFAULT 0,
        started_at TEXT,
        planned_end_at TEXT,
        last_ended_at TEXT,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  Future<void> _createIdentityAnchorTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS identity_anchor (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anchor_text TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        is_active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_anchor_active ON identity_anchor(is_active);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_anchor_order ON identity_anchor(sort_order);',
    );
  }

  Future<void> _addCurrentAnchorIdToUserProfile(DatabaseExecutor db) async {
    final columns = await db.rawQuery('PRAGMA table_info(user_profile);');
    final hasColumn = columns.any(
      (row) => (row['name'] as String?) == 'current_anchor_id',
    );
    if (!hasColumn) {
      await db.execute(
        'ALTER TABLE user_profile ADD COLUMN current_anchor_id INTEGER;',
      );
    }
  }

  Future<void> _seedIdentityAnchorsFromProfile(DatabaseExecutor db) async {
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM identity_anchor;'),
    );
    if ((existing ?? 0) > 0) {
      return;
    }

    final profiles = await db.query('user_profile');
    if (profiles.isEmpty) {
      return;
    }

    final profile = profiles.first;
    final identityText = (profile['identity_text'] as String?)?.trim() ?? '';
    if (identityText.isEmpty) {
      return;
    }

    await db.insert('identity_anchor', {
      'anchor_text': identityText,
      'source': 'initial',
      'is_active': 1,
      'sort_order': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final inserted = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT id FROM identity_anchor WHERE anchor_text = ? LIMIT 1;',
        [identityText],
      ),
    );

    if (inserted != null) {
      await db.update('user_profile', {'current_anchor_id': inserted});
    }
  }
}
