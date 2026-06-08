import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {
  final String? cashierId;
  final bool skipSync;
  const LoadHistoryEvent({this.cashierId, this.skipSync = false});
  @override
  List<Object?> get props => [cashierId, skipSync];
}

class LoadHistoryByRangeEvent extends HistoryEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? cashierId;
  final bool skipSync;
  const LoadHistoryByRangeEvent(this.startDate, this.endDate, {this.cashierId, this.skipSync = false});
  @override
  List<Object?> get props => [startDate, endDate, cashierId, skipSync];
}

class DeleteTransactionEvent extends HistoryEvent {
  final String id;
  const DeleteTransactionEvent(this.id);
  @override
  List<Object?> get props => [id];
}
