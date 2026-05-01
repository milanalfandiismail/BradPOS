import 'package:equatable/equatable.dart';
import 'package:bradpos/domain/entities/transaction_item.dart';

abstract class TransactionDetailState extends Equatable {
  const TransactionDetailState();
  
  @override
  List<Object> get props => [];
}

class TransactionDetailInitial extends TransactionDetailState {}

class TransactionDetailLoading extends TransactionDetailState {}

class TransactionDetailLoaded extends TransactionDetailState {
  final List<TransactionItem> items;

  const TransactionDetailLoaded(this.items);

  @override
  List<Object> get props => [items];
}

class TransactionDetailError extends TransactionDetailState {
  final String message;

  const TransactionDetailError(this.message);

  @override
  List<Object> get props => [message];
}
