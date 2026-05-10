import 'package:equatable/equatable.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/domain/entities/category.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;
  final List<Category> categories;
  final int totalItems;
  final int currentPage;
  final int limit;
  final String? searchQuery;
  final String? category;
  final String? stockStatus;

  const InventoryLoaded(
    this.items, {
    this.categories = const [],
    this.totalItems = 0,
    this.currentPage = 1,
    this.limit = 5,
    this.searchQuery,
    this.category,
    this.stockStatus,
  });

  @override
  List<Object?> get props => [
    items,
    categories,
    totalItems,
    currentPage,
    limit,
    searchQuery,
    category,
    stockStatus,
  ];
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class InventoryOperationSuccess extends InventoryState {
  final String message;
  const InventoryOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
