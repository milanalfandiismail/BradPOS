import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bradpos/domain/entities/transaction.dart' as ent;
import 'package:bradpos/domain/entities/transaction_item.dart';
import 'package:bradpos/data/models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<TransactionModel> createTransaction(ent.Transaction transaction, List<TransactionItem> items);
  Future<List<TransactionModel>> getTransactions(String userId);
  Future<void> pushUnsyncedTransaction(Map<String, dynamic> trxMap, List<Map<String, dynamic>> itemsData);
  Future<List<Map<String, dynamic>>> getTransactionItems(String transactionId);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final SupabaseClient supabase;

  TransactionRemoteDataSourceImpl({required this.supabase});

  @override
  Future<TransactionModel> createTransaction(ent.Transaction transaction, List<TransactionItem> items) async {
    // 1. Simpan Header + Items (Items sudah masuk di toMap() via TransactionModel)
    final trxModel = TransactionModel.fromEntity(transaction.copyWith(items: items));
    final trxMap = trxModel.toMap();
    
    final resTrx = await supabase.from('transactions').upsert(trxMap).select().maybeSingle();
    if (resTrx == null) throw Exception("Gagal membuat transaksi di remote");
    return TransactionModel.fromMap(resTrx);
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final response = await supabase
        .from('transactions')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return response.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<void> pushUnsyncedTransaction(Map<String, dynamic> trxMap, List<Map<String, dynamic>> itemsData) async {
    final cleanTrxMap = Map<String, dynamic>.from(trxMap);
    cleanTrxMap.remove('sync_status');
    // Note: cleanTrxMap sudah punya kolom 'items' berisi JSON string dari Local DS
    await supabase.from('transactions').upsert(cleanTrxMap);
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactionItems(String transactionId) async {
    final res = await supabase
        .from('transactions')
        .select('items')
        .eq('id', transactionId)
        .maybeSingle();
    
    if (res == null) return [];
    final items = res['items'];
    if (items == null) return [];
    if (items is String) {
      return List<Map<String, dynamic>>.from(jsonDecode(items));
    }
    return List<Map<String, dynamic>>.from(items);
  }
}
