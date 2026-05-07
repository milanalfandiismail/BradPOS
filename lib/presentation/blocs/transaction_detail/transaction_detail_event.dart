import 'package:equatable/equatable.dart';

abstract class TransactionDetailEvent extends Equatable {
  const TransactionDetailEvent();

  @override
  List<Object> get props => [];
}

class FetchTransactionItems extends TransactionDetailEvent {
  final String transactionId;

  const FetchTransactionItems(this.transactionId);

  @override
  List<Object> get props => [transactionId];
}
