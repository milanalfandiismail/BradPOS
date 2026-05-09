import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {
  final String? cashierId;
  const LoadHistoryEvent({this.cashierId});
  @override
  List<Object?> get props => [cashierId];
}

class LoadHistoryByRangeEvent extends HistoryEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? cashierId;
  const LoadHistoryByRangeEvent(this.startDate, this.endDate, {this.cashierId});
  @override
  List<Object?> get props => [startDate, endDate, cashierId];
}

class DeleteTransactionEvent extends HistoryEvent {
  final String id;
  const DeleteTransactionEvent(this.id);
  @override
  List<Object?> get props => [id];
}
