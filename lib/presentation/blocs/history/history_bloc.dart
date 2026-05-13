import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/domain/repositories/transaction_repository.dart';
import 'history_event.dart';
import 'history_state.dart';
import 'package:bradpos/core/sync/sync_service.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final TransactionRepository repository;
  final SyncService syncService;

  HistoryBloc({required this.repository, required this.syncService}) : super(HistoryInitial()) {
    on<LoadHistoryEvent>((event, emit) async {
      // 1. Tampilkan data lokal segera
      if (state is! HistoryLoaded) emit(HistoryLoading());
      
      final result = await repository.getTransactions(cashierId: event.cashierId);
      result.fold((failure) => emit(HistoryError(failure)), (transactions) {
        final total = transactions.fold(0.0, (sum, item) => sum + item.total);
        emit(HistoryLoaded(transactions, total));
      });

      // 2. Sync background jika diizinkan
      if (!event.skipSync) {
        final currentState = state;
        if (currentState is HistoryLoaded) {
          emit(currentState.copyWith(isSyncing: true));
        }
        syncService.syncAll().then((_) {
          if (!isClosed) {
            add(LoadHistoryEvent(cashierId: event.cashierId, skipSync: true));
          }
        });
      }
    });

    on<LoadHistoryByRangeEvent>((event, emit) async {
      // 1. Tampilkan data lokal segera
      if (state is! HistoryLoaded) emit(HistoryLoading());
      
      final result = await repository.getTransactionsByRange(
        event.startDate,
        event.endDate,
        cashierId: event.cashierId,
      );
      result.fold((failure) => emit(HistoryError(failure)), (transactions) {
        final total = transactions.fold(0.0, (sum, item) => sum + item.total);
        emit(HistoryLoaded(transactions, total));
      });

      // 2. Sync background jika diizinkan
      if (!event.skipSync) {
        final currentState = state;
        if (currentState is HistoryLoaded) {
          emit(currentState.copyWith(isSyncing: true));
        }
        syncService.syncAll().then((_) {
          if (!isClosed) {
            add(LoadHistoryByRangeEvent(
              event.startDate,
              event.endDate,
              cashierId: event.cashierId,
              skipSync: true,
            ));
          }
        });
      }
    });

    on<DeleteTransactionEvent>((event, emit) async {
      final result = await repository.deleteTransaction(event.id);
      result.fold(
        (failure) => emit(HistoryError(failure)),
        (_) {
          syncService.syncAll();
          add(LoadHistoryEvent()); // Reload data
        },
      );
    });
  }
}
