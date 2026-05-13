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
  final bool isSyncing;

  const InventoryLoaded(
    this.items, {
    this.categories = const [],
    this.totalItems = 0,
    this.currentPage = 1,
    this.limit = 5,
    this.searchQuery,
    this.category,
    this.stockStatus,
    this.isSyncing = false,
  });

  InventoryLoaded copyWith({
    List<InventoryItem>? items,
    List<Category>? categories,
    int? totalItems,
    int? currentPage,
    int? limit,
    String? searchQuery,
    String? category,
    String? stockStatus,
    bool? isSyncing,
  }) {
    return InventoryLoaded(
      items ?? this.items,
      categories: categories ?? this.categories,
      totalItems: totalItems ?? this.totalItems,
      currentPage: currentPage ?? this.currentPage,
      limit: limit ?? this.limit,
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      stockStatus: stockStatus ?? this.stockStatus,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

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
    isSyncing,
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
  final String? addedItemName;
  const InventoryOperationSuccess(this.message, {this.addedItemName});

  @override
  List<Object?> get props => [message, addedItemName];
}
