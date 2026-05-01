import 'package:dartz/dartz.dart';
import 'package:bradpos/domain/entities/transaction.dart';
import 'package:bradpos/domain/entities/transaction_item.dart';

abstract class TransactionRepository {
  Future<Either<String, Transaction>> createTransaction(
    Transaction transaction,
    List<TransactionItem> items,
  );
  Future<Either<String, List<Transaction>>> getTransactions();
  Future<Either<String, Transaction>> getTransactionById(String id);
}
