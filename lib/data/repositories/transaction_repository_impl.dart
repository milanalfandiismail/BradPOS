import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bradpos/domain/entities/transaction.dart' as ent;
import 'package:bradpos/domain/entities/transaction_item.dart';
import 'package:bradpos/domain/repositories/transaction_repository.dart';
import 'package:bradpos/data/data_sources/transaction_local_data_source.dart';
import 'package:bradpos/data/data_sources/transaction_remote_data_source.dart';

import 'package:bradpos/domain/repositories/auth_repository.dart';

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
      if (user == null) return const Left('Sesi berakhir. Silakan login ulang.');

      final userId = user.role == 'karyawan' ? user.ownerId : user.id;
      final karyawanId = user.role == 'karyawan' ? user.id : null;

      // 1. Simpan ke LOKAL (Sekaligus potong stok di SQLite)
      final localTrx = await localDataSource.createTransaction(
        transaction.copyWith(
          ownerId: userId, 
          karyawanId: karyawanId,
          id: transaction.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : transaction.id
        ), 
        items
      );

      // 2. Coba SINKRON ke REMOTE (Fire & Forget atau Silent Sync)
      _syncTransactionToRemote(localTrx, items);

      return Right(localTrx);
    } catch (e) {
      return Left('Gagal simpan transaksi: $e');
    }
  }

  Future<void> _syncTransactionToRemote(ent.Transaction transaction, List<TransactionItem> items) async {
    try {
      await remoteDataSource.createTransaction(transaction, items);
      // Jika sukses, nanti bisa update sync_status di lokal jadi 'synced'
    } catch (e) {
      // Abaikan jika gagal (akan disinkronkan oleh SyncService nanti)
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
      return Right(localTransactions);
    } catch (e) {
      return Left('Gagal muat riwayat: $e');
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
      return Right(trx);
    } catch (e) {
      return Left('Transaksi tidak ditemukan: $e');
    }
  }
}
