import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'web_database_adapter.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const int _databaseVersion = 16;
  static dynamic _database; // dynamic to support both sqlite.Database and WebDatabaseAdapter

  static const String _idType = 'TEXT PRIMARY KEY';
  static const String _textType = 'TEXT NOT NULL';
  static const String _textNullable = 'TEXT';
  static const String _integerType = 'INTEGER NOT NULL';
  static const String _realType = 'REAL NOT NULL';
  static const String _boolType = 'INTEGER NOT NULL';
  static Completer<dynamic>? _dbCompleter;
  static bool _initialized = false;

  DatabaseHelper._init();

  Future<dynamic> get database async {
    if (_initialized && _database != null) return _database;
    
    if (_dbCompleter != null) return _dbCompleter!.future;
    
    _dbCompleter = Completer<dynamic>();
    
    try {
      debugPrint("DatabaseHelper: Starting one-time initialization...");
      _database = await _initDB('bradpos.db');
      _initialized = true;
      _dbCompleter!.complete(_database);
      return _database;
    } catch (e) {
      _dbCompleter!.completeError(e);
      _dbCompleter = null; // Allow retry
      rethrow;
    }
  }

  Future<dynamic> _initDB(String filePath) async {
    if (kIsWeb) {
      final webDb = WebDatabaseAdapter();
      await webDb.init(filePath, onCreate: _createDB, onUpgrade: _upgradeDB, version: _databaseVersion);
      return webDb;
    }

    final dbPath = await sqlite.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await sqlite.openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(dynamic db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE produk ADD COLUMN image_url TEXT');
    }
    if (oldVersion < 3) {
      await _createKaryawanTable(db);
    }
    if (oldVersion < 4) {
      await _createProfilesTable(db);
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN cashier_name TEXT',
        );
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE produk ADD COLUMN category_id TEXT');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
          'ALTER TABLE produk ADD COLUMN purchase_price REAL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE produk ADD COLUMN selling_price REAL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE produk ADD COLUMN unit TEXT DEFAULT "pcs"',
        );
        await db.execute(
          'ALTER TABLE produk ADD COLUMN is_active INTEGER DEFAULT 1',
        );
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE produk ADD COLUMN barcode TEXT');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN description TEXT');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN shop_name TEXT');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 11) {
      try {
        await db.execute('ALTER TABLE profiles ADD COLUMN remote_image TEXT');
        await db.execute('ALTER TABLE profiles ADD COLUMN local_image TEXT');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 12) {
      try {
        await db.execute('ALTER TABLE profiles ADD COLUMN full_name TEXT');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 14) {
      try {
        await db.execute('ALTER TABLE profiles ADD COLUMN shop_id TEXT');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 15) {
      try {
        await db.execute('ALTER TABLE karyawan ADD COLUMN remote_image TEXT');
        await db.execute('ALTER TABLE karyawan ADD COLUMN local_image TEXT');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    if (oldVersion < 16) {
      try {
        // SQLite tidak dukung DROP COLUMN dengan mudah. 
        // Cara amannya: Rename table lama -> Create table baru -> Copy data -> Drop table lama.
        await db.execute('ALTER TABLE karyawan RENAME TO karyawan_old');
        await _createKaryawanTable(db);
        await db.execute('''
          INSERT INTO karyawan (id, owner_id, full_name, password_hash, is_active, remote_image, local_image, created_at, sync_status, updated_at)
          SELECT id, owner_id, full_name, password_hash, is_active, remote_image, local_image, created_at, sync_status, updated_at
          FROM karyawan_old
        ''');
        await db.execute('DROP TABLE karyawan_old');
      } catch (e) {
        debugPrint("Migration to v16 failed: $e");
      }
    }
  }

  Future _createDB(dynamic db, int version) async {
    await db.execute('''
CREATE TABLE produk (
  id $_idType,
  owner_id $_textType,
  category_id $_textNullable,
  name $_textType,
  category $_textType,
  purchase_price $_realType DEFAULT 0,
  selling_price $_realType DEFAULT 0,
  stock $_integerType,
  unit $_textType DEFAULT 'pcs',
  barcode $_textNullable,
  image_url $_textNullable,
  is_active INTEGER DEFAULT 1,
  created_at $_textNullable,
  sync_status $_textType DEFAULT 'synced',
  updated_at $_textNullable
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $_idType,
  owner_id $_textType,
  name $_textType,
  description $_textNullable,
  created_at $_textNullable,
  sync_status $_textType DEFAULT 'synced',
  updated_at $_textNullable
)
''');

    await _createTransactionsTable(db);
    await _createKaryawanTable(db);
    await _createProfilesTable(db);
  }

  Future<void> _createKaryawanTable(dynamic db) async {
    await db.execute('''
CREATE TABLE karyawan (
  id $_idType,
  owner_id $_textType,
  full_name $_textType,
  password_hash $_textType,
  is_active $_boolType DEFAULT 1,
  remote_image $_textNullable,
  local_image $_textNullable,
  created_at $_textNullable,
  sync_status $_textType DEFAULT 'synced',
  updated_at $_textNullable
)
''');
  }

  Future<void> _createTransactionsTable(dynamic db) async {
    await db.execute('''
CREATE TABLE transactions (
  id $_idType,
  owner_id $_textType,
  karyawan_id $_textNullable,
  cashier_name $_textNullable,
  transaction_number $_textType,
  customer_name $_textNullable,
  customer_phone $_textNullable,
  shop_name $_textNullable,
  subtotal $_realType,
  discount $_realType,
  tax $_realType,
  total $_realType,
  payment_method $_textType,
  payment_amount $_realType,
  change_amount $_realType,
  notes $_textNullable,
  status $_textType,
  items $_textType,
  created_at $_textNullable,
  sync_status $_textType DEFAULT 'created',
  updated_at $_textNullable
)
''');
  }

  Future<void> _createProfilesTable(dynamic db) async {
    await db.execute('''
CREATE TABLE profiles (
  id $_idType,
  shop_id $_textNullable,
  shop_name $_textType,
  full_name $_textNullable,
  remote_image $_textNullable,
  local_image $_textNullable,
  updated_at $_textNullable
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    if (db != null) {
      await db.close();
    }
  }
}
