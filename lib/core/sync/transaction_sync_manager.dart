import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:bradpos/data/data_sources/transaction_local_data_source.dart';
import 'package:bradpos/data/data_sources/transaction_remote_data_source.dart';
import 'package:bradpos/domain/entities/transaction_item.dart';

class TransactionSyncManager {
  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource transactionRemoteDataSource;

  TransactionSyncManager({
    required this.localDataSource,
    required this.transactionRemoteDataSource,
  });

  Future<void> push(String userId) async {
    try {
      final unsyncedTrxs = await localDataSource.getUnsyncedTransactions();
      if (unsyncedTrxs.isEmpty) return;

      debugPrint("TransactionSync: Menemukan ${unsyncedTrxs.length} transaksi yang perlu push");

      for (var trxMap in unsyncedTrxs) {
        try {
          String id = trxMap['id'] as String;
          final trxNumber = trxMap['transaction_number'] as String? ?? 'N/A';

          if (id.isEmpty) continue;

          // UUID Fix
          if (id.length != 36 || !id.contains('-')) {
            final oldId = id;
            final newUuid = const Uuid().v4();
            debugPrint("TransactionSync: Fix ID non-UUID '$oldId' ($trxNumber) -> $newUuid");
            await localDataSource.fixInvalidTransactionId(oldId, newUuid);

            trxMap = Map<String, dynamic>.from(trxMap);
            trxMap['id'] = newUuid;
            id = newUuid;
          }

          debugPrint("TransactionSync: Push transaksi $trxNumber ($id) ke server...");

          final cleanTrx = Map<String, dynamic>.from(trxMap);
          cleanTrx.remove('sync_status');
          cleanTrx.remove('updated_at');

          final itemsMap = await localDataSource.getTransactionItems(id);
          final items = itemsMap.map((map) {
            return TransactionItem(
              id: map['id'],
              transactionId: map['transaction_id'],
              produkId: map['produk_id'],
              productName: map['product_name'],
              quantity: map['quantity'],
              unitPrice: (map['unit_price'] as num).toDouble(),
              discount: (map['discount'] as num).toDouble(),
              subtotal: (map['subtotal'] as num).toDouble(),
              createdAt: DateTime.parse(map['created_at']),
            );
          }).toList();

          final itemsData = items.map((i) => i.toMap()).toList();
          await transactionRemoteDataSource.pushUnsyncedTransaction(cleanTrx, itemsData);
          await localDataSource.updateSyncStatus(id, 'synced');
          debugPrint("TransactionSync: Push transaksi $id BERHASIL");
        } catch (e) {
          debugPrint("TransactionSync Push Error (${trxMap['id']}): $e");
        }
      }
    } catch (e) {
      debugPrint("TransactionSync Push Failed: $e");
    }
  }

  Future<void> pull(String userId) async {
    try {
      final lastSync = await localDataSource.getLastSyncTime(userId);
      debugPrint("TransactionSync: Pulling transactions from server (Last Sync: $lastSync)...");
      
      final remoteTrxs = await transactionRemoteDataSource.getTransactions(userId, lastSync: lastSync);
      
      if (remoteTrxs.isEmpty) {
        debugPrint("TransactionSync: Tidak ada transaksi baru di server.");
        return;
      }

      debugPrint("TransactionSync: Berhasil menarik ${remoteTrxs.length} transaksi aktif");
      await localDataSource.saveTransactions(remoteTrxs);
    } catch (e) {
      debugPrint("TransactionSync Pull Failed: $e");
    }
  }
}
