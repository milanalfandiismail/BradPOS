import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const int _databaseVersion = 14;
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bradpos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
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
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE produk (
  id $idType,
  owner_id $textType,
  category_id $textNullable,
  name $textType,
  category $textType,
  purchase_price $realType DEFAULT 0,
  selling_price $realType DEFAULT 0,
  stock $integerType,
  unit $textType DEFAULT 'pcs',
  barcode $textNullable,
  image_url $textNullable,
  is_active INTEGER DEFAULT 1,
  created_at $textNullable,
  sync_status $textType DEFAULT 'synced',
  updated_at $textNullable
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  owner_id $textType,
  name $textType,
  description $textNullable,
  created_at $textNullable,
  sync_status $textType DEFAULT 'synced',
  updated_at $textNullable
)
''');

    await _createTransactionsTable(db);
    await _createKaryawanTable(db);
    await _createProfilesTable(db);
  }

  Future<void> _createKaryawanTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE karyawan (
  id $idType,
  owner_id $textType,
  full_name $textType,
  email $textType,
  password_hash $textType,
  is_active $boolType DEFAULT 1,
  created_at $textNullable,
  sync_status $textType DEFAULT 'synced',
  updated_at $textNullable
)
''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  owner_id $textType,
  karyawan_id $textNullable,
  cashier_name $textNullable,
  transaction_number $textType,
  customer_name $textNullable,
  customer_phone $textNullable,
  shop_name $textNullable,
  subtotal $realType,
  discount $realType,
  tax $realType,
  total $realType,
  payment_method $textType,
  payment_amount $realType,
  change_amount $realType,
  notes $textNullable,
  status $textType,
  items $textType,
  created_at $textNullable,
  sync_status $textType DEFAULT 'created',
  updated_at $textNullable
)
''');
  }

  Future<void> _createProfilesTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE profiles (
  id $idType,
  shop_id $textNullable,
  shop_name $textType,
  full_name $textNullable,
  remote_image $textNullable,
  local_image $textNullable,
  updated_at $textNullable
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
