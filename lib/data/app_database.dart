import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class AppDatabase {
  AppDatabase._();

  static const _databaseName = 'financy_app.db';
  static const _databaseVersion = 2;

  static Database? _database;

  static void configureFactory() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWebBasicWebWorker;
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        break;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        break;
    }
  }

  static Future<Database> instance() async {
    final current = _database;
    if (current != null) return current;

    final databasePath = kIsWeb
        ? _databaseName
        : '${await databaseFactory.getDatabasesPath()}/$_databaseName';

    try {
      _database = await _openDatabase(databasePath);
    } catch (error) {
      if (!kIsWeb || !isRecoverableWebDatabaseError(error)) {
        rethrow;
      }

      databaseFactory = databaseFactoryFfiWebNoWebWorker;
      try {
        await databaseFactory.deleteDatabase(databasePath);
      } catch (_) {}
      _database = await _openDatabase(databasePath);
    }

    return _database!;
  }

  static Future<Database> _openDatabase(String databasePath) {
    return databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          if (!kIsWeb) {
            await db.execute('PRAGMA foreign_keys = ON');
          }
        },
      ),
    );
  }

  static bool isRecoverableWebDatabaseError(Object error) {
    if (!kIsWeb) return false;

    final message = error.toString().toLowerCase();
    return message.contains('unsupported result') ||
        message.contains('web worker') ||
        message.contains('webassembly') ||
        message.contains('sqlite') ||
        message.contains('sqflite') ||
        message.contains('getdatabasespath is null');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        supabase_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN supabase_id TEXT');
    }
  }
}
