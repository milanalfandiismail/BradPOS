import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
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
      version: 4,
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
      await _createTransactionsTable(db);
      await _createTransactionItemsTable(db);
    }
    if (oldVersion < 4) {
      await _createProfilesTable(db);
    }
  }

  Future _createDB(Database db, int version) async {
    await _createProdukTable(db);
    await _createCategoriesTable(db);
    await _createKaryawanTable(db);
    await _createTransactionsTable(db);
    await _createTransactionItemsTable(db);
    await _createProfilesTable(db);
  }

  Future<void> _createProdukTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE produk (
  id $idType,
  owner_id $textType,
  category_id $textNullable,
  name $textType,
  category $textType,
  purchase_price $realType,
  selling_price $realType,
  stock $integerType,
  unit $textType,
  barcode $textNullable,
  image_url $textNullable,
  is_active $boolType,
  created_at $textType,
  
  -- Offline Sync Columns
  sync_status $textType DEFAULT 'created', 
  updated_at $textType
)
''');
  }

  Future<void> _createCategoriesTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  owner_id $textType,
  name $textType,
  description $textNullable,
  created_at $textType,
  
  -- Offline Sync Columns
  sync_status $textType DEFAULT 'created',
  updated_at $textType
)
''');
  }

  Future<void> _createKaryawanTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE karyawan (
  id $idType,
  owner_id $textType,
  full_name $textType,
  email $textType,
  password_hash $textType,
  is_active $boolType DEFAULT 1,
  created_at $textType,
  sync_status $textType DEFAULT 'synced',
  updated_at $textType
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
  transaction_number $textType,
  customer_name $textNullable,
  customer_phone $textNullable,
  subtotal $realType,
  discount $realType,
  tax $realType,
  total $realType,
  payment_method $textType,
  payment_amount $realType,
  change_amount $realType,
  notes $textNullable,
  status $textType,
  created_at $textType,
  sync_status $textType DEFAULT 'created',
  updated_at $textType
)
''');
  }

  Future<void> _createTransactionItemsTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE transaction_items (
  id $idType,
  transaction_id $textType,
  produk_id $textType,
  product_name $textType,
  quantity $integerType,
  unit_price $realType,
  discount $realType,
  subtotal $realType,
  created_at $textType,
  sync_status $textType DEFAULT 'created',
  updated_at $textType
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
  shop_name $textType,
  updated_at $textNullable
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
