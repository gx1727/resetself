import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const dbName = 'resetself_v1.db';
  static const dbVersion = 4;

  Database? _database;
  String? _databasePath;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final opened = await _openDatabase();
    _database = opened;
    return opened;
  }

  Future<String> get databasePath async {
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
    if (existing == null) {
      return;
    }

    await existing.close();
    _database = null;
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
}
