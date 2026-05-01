import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {}

class LoadHistoryByRangeEvent extends HistoryEvent {
  final DateTime startDate;
  final DateTime endDate;
  const LoadHistoryByRangeEvent(this.startDate, this.endDate);
  @override
  List<Object?> get props => [startDate, endDate];
}

class DeleteTransactionEvent extends HistoryEvent {
  final String id;
  const DeleteTransactionEvent(this.id);
  @override
  List<Object?> get props => [id];
}
