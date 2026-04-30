import 'package:equatable/equatable.dart';
import '../../domain/entities/inventory_item.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventory extends InventoryEvent {
  final int? page;
  final int? limit;
  final String? searchQuery;

  const LoadInventory({this.page, this.limit, this.searchQuery});

  @override
  List<Object?> get props => [page, limit, searchQuery];
}

class AddInventoryItemEvent extends InventoryEvent {
  final InventoryItem item;
  const AddInventoryItemEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class UpdateInventoryItemEvent extends InventoryEvent {
  final InventoryItem item;
  const UpdateInventoryItemEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class DeleteInventoryItemEvent extends InventoryEvent {
  final String id;
  const DeleteInventoryItemEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadCategoriesEvent extends InventoryEvent {}

class RefreshAfterSyncEvent extends InventoryEvent {}

class SyncOfflineDataEvent extends InventoryEvent {}

class SyncAllEvent extends InventoryEvent {}
