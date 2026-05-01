import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:bradpos/core/database/database_helper.dart';
import 'package:bradpos/domain/entities/transaction.dart' as ent;
import 'package:bradpos/domain/entities/transaction_item.dart';
import 'package:bradpos/data/models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<TransactionModel> createTransaction(
    ent.Transaction transaction,
    List<TransactionItem> items,
  );
  Future<List<TransactionModel>> getTransactions(String userId);
  Future<List<TransactionModel>> getTransactionsByRange(
    String userId,
    DateTime start,
    DateTime end,
  );
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions();
  Future<List<Map<String, dynamic>>> getTransactionItems(String transactionId);
  Future<void> updateSyncStatus(String id, String status);
  Future<void> saveTransactions(List<TransactionModel> transactions);
  Future<void> saveTransactionItems(List<Map<String, dynamic>> items);
  Future<void> deleteTransaction(String id);
  Future<void> fixInvalidTransactionId(String oldId, String newUuid);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final DatabaseHelper dbHelper;

  TransactionLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<TransactionModel> createTransaction(
    ent.Transaction transaction,
    List<TransactionItem> items,
  ) async {
    final db = await dbHelper.database;
    final transactionId = transaction.id.isEmpty
        ? _generateId()
        : transaction.id;

    String trxNumber = transaction.transactionNumber;
    if (trxNumber.isEmpty) {
      final yearStr = DateFormat('yyyy').format(transaction.createdAt);
      final monthStr = DateFormat('M').format(transaction.createdAt);
      final dayStr = DateFormat('d').format(transaction.createdAt);
      
      // Ambil Nama Toko (dari profile yang dipassing Repo)
      final shopBase = (transaction.shopName ?? transaction.cashierName ?? 'TRX')
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
          .toUpperCase();
      
      final prefix = shopBase.length >= 3 
          ? shopBase.substring(0, 3) 
          : shopBase.padRight(3, 'X');
      
      final randomStr = transactionId.substring(0, 4).toUpperCase();
      trxNumber = '$prefix-$yearStr-$monthStr-$dayStr-$randomStr';
    }

    final trxModel = TransactionModel.fromEntity(
      transaction.copyWith(
        id: transactionId, 
        transactionNumber: trxNumber,
        items: items,
      ),
    );

    debugPrint('DEBUG toMap: ${trxModel.toMap()}');

    try {
      // CEK APAKAH SUDAH ADA (Cegah double stock deduction)
      final existing = await db.query('transactions', where: 'id = ?', whereArgs: [transactionId]);
      final isNew = existing.isEmpty;

      // 1. Simpan Transaction (Header + Items dalam JSON)
      await db.insert('transactions', trxModel.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Potong Stok (Hanya jika transaksi baru)
      if (isNew) {
        for (var item in items) {
          debugPrint('DEBUG: Deduct stock for ${item.produkId}, qty: ${item.quantity}');
          final before = await db.query('produk', columns: ['stock'], where: 'id = ?', whereArgs: [item.produkId]);
          debugPrint('DEBUG stock before: ${before.first}');
          await db.execute(
            'UPDATE produk SET stock = CASE WHEN stock = -1 OR stock IS NULL THEN -1 ELSE stock - ? END WHERE id = ?',
            [item.quantity, item.produkId],
          );
          final after = await db.query('produk', columns: ['stock'], where: 'id = ?', whereArgs: [item.produkId]);
          debugPrint('DEBUG stock after: ${after.first}');
        }
      }
    } catch (e, st) {
      debugPrint('DB ERROR createTransaction: $e');
      debugPrint('STACK: $st');
      rethrow;
    }

    return trxModel;
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'owner_id = ? AND status != ?',
      whereArgs: [userId, 'deleted'],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'owner_id = ? AND status != ? AND created_at BETWEEN ? AND ?',
      whereArgs: [
        userId,
        'deleted',
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await dbHelper.database;
    return await db.query(
      'transactions',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactionItems(String transactionId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      columns: ['items'],
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    if (maps.isEmpty) return [];
    
    final String itemsJson = maps.first['items'] as String;
    final List<dynamic> decoded = jsonDecode(itemsJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> updateSyncStatus(String id, String status) async {
    final db = await dbHelper.database;
    await db.update(
      'transactions',
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var trx in transactions) {
      final map = trx.toMap();
      map['sync_status'] = 'synced';
      batch.insert(
        'transactions',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveTransactionItems(List<Map<String, dynamic>> items) async {
    // No-op: Items are now part of the transaction row
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> fixInvalidTransactionId(String oldId, String newUuid) async {
    final db = await dbHelper.database;
    await db.update(
      'transactions',
      {'id': newUuid},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }

  String _generateId() => const Uuid().v4();
}
