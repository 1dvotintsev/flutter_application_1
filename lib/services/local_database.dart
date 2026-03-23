import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'plantcare_cache.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_profile (
            id INTEGER PRIMARY KEY,
            json_data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_plants (
            id INTEGER PRIMARY KEY,
            json_data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_plant_details (
            id INTEGER PRIMARY KEY,
            json_data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_schedules (
            id INTEGER PRIMARY KEY,
            schedule_type TEXT NOT NULL,
            json_data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_rooms (
            id INTEGER PRIMARY KEY,
            json_data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_events (
            plant_id INTEGER NOT NULL,
            json_data TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (plant_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_actions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_type TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            method TEXT NOT NULL,
            body TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
