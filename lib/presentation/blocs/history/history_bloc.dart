import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/domain/repositories/transaction_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final TransactionRepository repository;

  HistoryBloc({required this.repository}) : super(HistoryInitial()) {
    on<LoadHistoryEvent>((event, emit) async {
      emit(HistoryLoading());
      final result = await repository.getTransactions();
      result.fold(
        (failure) => emit(HistoryError(failure)),
        (transactions) {
          final total = transactions.fold(0.0, (sum, item) => sum + item.total);
          emit(HistoryLoaded(transactions, total));
        },
      );
    });

    on<LoadHistoryByRangeEvent>((event, emit) async {
      emit(HistoryLoading());
      final result = await repository.getTransactionsByRange(event.startDate, event.endDate);
      result.fold(
        (failure) => emit(HistoryError(failure)),
        (transactions) {
          final total = transactions.fold(0.0, (sum, item) => sum + item.total);
          emit(HistoryLoaded(transactions, total));
        },
      );
    });

    on<DeleteTransactionEvent>((event, emit) async {
      final result = await repository.deleteTransaction(event.id);
      result.fold(
        (failure) => emit(HistoryError(failure)),
        (_) => add(LoadHistoryEvent()), // Reload data
      );
    });
  }
}
