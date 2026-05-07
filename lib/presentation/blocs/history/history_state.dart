import 'package:equatable/equatable.dart';
import 'package:bradpos/domain/entities/transaction.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<Transaction> transactions;
  final double totalOmzet;
  const HistoryLoaded(this.transactions, this.totalOmzet);
  @override
  List<Object?> get props => [transactions, totalOmzet];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
