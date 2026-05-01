import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/domain/repositories/transaction_repository.dart';
import 'transaction_detail_event.dart';
import 'transaction_detail_state.dart';

class TransactionDetailBloc extends Bloc<TransactionDetailEvent, TransactionDetailState> {
  final TransactionRepository repository;

  TransactionDetailBloc({required this.repository}) : super(TransactionDetailInitial()) {
    on<FetchTransactionItems>((event, emit) async {
      emit(TransactionDetailLoading());
      final result = await repository.getTransactionItems(event.transactionId);
      result.fold(
        (failure) => emit(TransactionDetailError(failure)),
        (items) => emit(TransactionDetailLoaded(items)),
      );
    });
  }
}
