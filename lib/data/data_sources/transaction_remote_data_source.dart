import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bradpos/domain/entities/transaction.dart' as ent;
import 'package:bradpos/domain/entities/transaction_item.dart';
import 'package:bradpos/data/models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<TransactionModel> createTransaction(ent.Transaction transaction, List<TransactionItem> items);
  Future<List<TransactionModel>> getTransactions(String userId);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final SupabaseClient supabase;

  TransactionRemoteDataSourceImpl({required this.supabase});

  @override
  Future<TransactionModel> createTransaction(ent.Transaction transaction, List<TransactionItem> items) async {
    // 1. Simpan Header
    final trxMap = transaction.toMap();
    final resTrx = await supabase.from('transactions').insert(trxMap).select().single();
    final String transactionId = resTrx['id'];

    // 2. Simpan Items
    final List<Map<String, dynamic>> itemsData = items.map((item) {
      return {
        'transaction_id': transactionId,
        'produk_id': item.produkId,
        'product_name': item.productName,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'discount': item.discount,
        'subtotal': item.subtotal,
      };
    }).toList();

    await supabase.from('transaction_items').insert(itemsData);
    
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
}
