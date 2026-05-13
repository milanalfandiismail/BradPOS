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
  final bool isSyncing;

  const HistoryLoaded(
    this.transactions, 
    this.totalOmzet, {
    this.isSyncing = false,
  });

  HistoryLoaded copyWith({
    List<Transaction>? transactions,
    double? totalOmzet,
    bool? isSyncing,
  }) {
    return HistoryLoaded(
      transactions ?? this.transactions,
      totalOmzet ?? this.totalOmzet,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [transactions, totalOmzet, isSyncing];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
