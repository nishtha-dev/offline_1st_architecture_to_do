import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "todo_database.db";
  static const _databaseVersion = 1;

  static const todoTable = 'todos';
  static const syncMetadataTable = 'sync_metadata';

  // Todo table columns
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnDescription = 'description';
  static const columnIsCompleted = 'is_completed';
  static const columnCreatedAt = 'created_at';
  static const columnUpdatedAt = 'updated_at';
  static const columnUserId = 'user_id';
  static const columnVersion = 'version';
  static const columnDeleted = 'deleted';

  // Sync metadata columns
  static const columnLastSyncTime = 'last_sync_time';
  static const columnPendingSync = 'pending_sync';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Create todos table
    await db.execute('''
      CREATE TABLE $todoTable (
        $columnId TEXT PRIMARY KEY,
        $columnTitle TEXT NOT NULL,
        $columnDescription TEXT,
        $columnIsCompleted INTEGER NOT NULL DEFAULT 0,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        $columnUserId TEXT NOT NULL,
        $columnVersion INTEGER NOT NULL DEFAULT 1,
        $columnDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create sync metadata table
    await db.execute('''
      CREATE TABLE $syncMetadataTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnLastSyncTime TEXT,
        $columnPendingSync INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insert initial sync metadata
    await db.insert(syncMetadataTable, {
      columnLastSyncTime: DateTime.now().toIso8601String(),
      columnPendingSync: 0,
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
