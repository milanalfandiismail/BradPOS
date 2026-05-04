import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bradpos/domain/entities/transaction.dart' as ent;
import 'package:bradpos/domain/entities/transaction_item.dart';
import 'package:bradpos/domain/repositories/transaction_repository.dart';
import 'package:bradpos/data/data_sources/transaction_local_data_source.dart';
import 'package:bradpos/data/data_sources/transaction_remote_data_source.dart';

import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final SupabaseClient supabase;
  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource remoteDataSource;
  final AuthRepository authRepository;

  TransactionRepositoryImpl({
    required this.supabase,
    required this.localDataSource,
    required this.remoteDataSource,
    required this.authRepository,
  });

  @override
  Future<Either<String, ent.Transaction>> createTransaction(
    ent.Transaction transaction,
    List<TransactionItem> items,
  ) async {
    try {
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((l) => null, (r) => r);
      if (user == null) {
        return const Left('Sesi berakhir. Silakan login ulang.');
      }

      final userId = user.role == 'karyawan' ? user.ownerId : user.id;
      final karyawanId = user.role == 'karyawan' ? user.id : null;
      final cashierName = user.name;
      final transactionId = transaction.id.isEmpty
          ? const Uuid().v4()
          : transaction.id;

      // Ensure all items have the same transaction_id
      final updatedItems = items
          .map(
            (item) => item.copyWith(
              id: const Uuid().v4(), // Item ID must be UUID too
              transactionId: transactionId,
            ),
          )
          .toList();

      // 1. Simpan ke LOKAL (Sekaligus potong stok di SQLite)
      final localTrx = await localDataSource.createTransaction(
        transaction.copyWith(
          id: transactionId,
          ownerId: userId,
          karyawanId: karyawanId,
          cashierName: cashierName,
          shopName: user.shopName,
        ),
        updatedItems,
      );

      // 2. Coba SINKRON ke REMOTE (Fire & Forget atau Silent Sync)
      _syncTransactionToRemote(localTrx, updatedItems);

      return Right(localTrx);
    } catch (e, st) {
      debugPrint('ERROR createTransaction: $e');
      debugPrint('STACK: $st');
      return Left('Gagal simpan transaksi: $e');
    }
  }

  Future<void> _syncTransactionToRemote(
    ent.Transaction transaction,
    List<TransactionItem> items,
  ) async {
    try {
      await remoteDataSource.createTransaction(transaction, items);

      // Update stock di remote Supabase
      for (var item in items) {
        final pid = item.produkId;
        if (pid != null && pid.isNotEmpty) {
          try {
            final res = await supabase
                .from('produk')
                .select('stock')
                .eq('id', pid)
                .single();
            final rawStock = res['stock'];
            final currentStock = rawStock is int
                ? rawStock
                : int.tryParse(rawStock.toString()) ?? 0;
            final newStock = currentStock == -1
                ? -1
                : currentStock - item.quantity;
            await supabase
                .from('produk')
                .update({'stock': newStock})
                .eq('id', pid);
          } catch (_) {}
        }
      }

      // Push sukses → tandai 'synced' biar SyncService gak push ulang
      await localDataSource.updateSyncStatus(transaction.id, 'synced');
    } catch (e) {
      // Offline? Gak masalah. SyncService akan push nanti
      debugPrint('Immediate sync gagal (akan retry via SyncService): $e');
    }
  }

  @override
  Future<Either<String, List<ent.Transaction>>> getTransactions() async {
    try {
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((l) => null, (r) => r);
      if (user == null) return const Left("User tidak terautentikasi.");

      final userId = (user.role == 'karyawan' ? user.ownerId : user.id) ?? '';

      // Ambil dari lokal untuk kecepatan
      final localTransactions = await localDataSource.getTransactions(userId);
      return Right(localTransactions.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left('Gagal muat riwayat: $e');
    }
  }

  @override
  Future<Either<String, List<ent.Transaction>>> getTransactionsByRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((l) => null, (r) => r);
      if (user == null) return const Left("User tidak terautentikasi.");

      final userId = (user.role == 'karyawan' ? user.ownerId : user.id) ?? '';

      final transactionModels = await localDataSource.getTransactionsByRange(
        userId,
        startDate,
        endDate,
      );
      return Right(transactionModels.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left('Gagal muat laporan: $e');
    }
  }

  @override
  Future<Either<String, ent.Transaction>> getTransactionById(String id) async {
    try {
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((l) => null, (r) => r);
      if (user == null) return const Left("User tidak terautentikasi.");

      final userId = (user.role == 'karyawan' ? user.ownerId : user.id) ?? '';

      // Cari di lokal saja dulu
      final localTransactions = await localDataSource.getTransactions(userId);
      final trx = localTransactions.firstWhere((t) => t.id == id);
      return Right(trx.toEntity());
    } catch (e) {
      return Left('Transaksi tidak ditemukan: $e');
    }
  }

  @override
  Future<Either<String, List<TransactionItem>>> getTransactionItems(
    String transactionId,
  ) async {
    try {
      final itemsMap = await localDataSource.getTransactionItems(transactionId);
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
      return Right(items);
    } catch (e) {
      return Left('Gagal muat detail transaksi: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteTransaction(String id) async {
    try {
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((l) => null, (r) => r);

      if (user == null) {
        return const Left('Sesi berakhir.');
      }
      if (user.role != 'owner') {
        return const Left('Hanya Owner yang boleh menghapus transaksi!');
      }

      await localDataSource.deleteTransaction(id);

      // Hapus di Supabase juga (CASCADE hapus transaction_items)
      try {
        await supabase.from('transactions').delete().eq('id', id);
      } catch (e) {
        // Offline? Gak masalah, data lokal udah bersih
        debugPrint('Gagal hapus transaksi di Supabase (mungkin offline): $e');
      }

      return const Right(null);
    } catch (e) {
      return Left('Gagal hapus transaksi: $e');
    }
  }
}
