import 'package:sqflite/sqflite.dart';
import 'package:bradpos/core/database/database_helper.dart';
import 'package:bradpos/domain/entities/transaction.dart' as ent;
import 'package:bradpos/domain/entities/transaction_item.dart';
import 'package:bradpos/data/models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<TransactionModel> createTransaction(ent.Transaction transaction, List<TransactionItem> items);
  Future<List<TransactionModel>> getTransactions(String userId);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final DatabaseHelper dbHelper;

  TransactionLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<TransactionModel> createTransaction(ent.Transaction transaction, List<TransactionItem> items) async {
    final db = await dbHelper.database;
    
    return await db.transaction((txn) async {
      // 1. Simpan Transaksi Header
      final trxModel = TransactionModel.fromEntity(transaction);
      final trxMap = trxModel.toMap();
      trxMap['sync_status'] = 'created';
      trxMap['updated_at'] = DateTime.now().toIso8601String();
      
      await txn.insert('transactions', trxMap, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Simpan Transaction Items & Potong Stok
      for (var item in items) {
        final itemMap = {
          'id': item.id.isEmpty ? _generateId() : item.id,
          'transaction_id': transaction.id,
          'produk_id': item.produkId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': item.discount,
          'subtotal': item.subtotal,
          'created_at': item.createdAt.toIso8601String(),
          'sync_status': 'created',
          'updated_at': DateTime.now().toIso8601String(),
        };
        await txn.insert('transaction_items', itemMap);

        // 3. POTONG STOK DI TABEL PRODUK
        // Ambil stok sekarang
        final product = await txn.query('produk', where: 'id = ?', whereArgs: [item.produkId], limit: 1);
        if (product.isNotEmpty) {
          int currentStock = product.first['stock'] as int;
          // Hanya kurangi jika bukan produk non-stok (-1)
          if (currentStock != -1) {
            await txn.update(
              'produk', 
              {'stock': currentStock - item.quantity, 'sync_status': 'updated', 'updated_at': DateTime.now().toIso8601String()},
              where: 'id = ?', 
              whereArgs: [item.produkId]
            );
          }
        }
      }

      return trxModel;
    });
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'owner_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}
