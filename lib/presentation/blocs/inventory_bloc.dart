import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:bradpos/core/sync/sync_service.dart';
import 'package:bradpos/domain/entities/category.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/domain/repositories/inventory_repository.dart';
import 'package:bradpos/domain/repositories/category_repository.dart';
import 'package:bradpos/presentation/blocs/inventory_event.dart';
import 'package:bradpos/presentation/blocs/inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository repository;
  final CategoryRepository categoryRepository;
  final SyncService syncService;

  InventoryBloc({
    required this.repository,
    required this.categoryRepository,
    required this.syncService,
  }) : super(InventoryInitial()) {
    on<LoadInventory>((event, emit) async {
      emit(InventoryLoading());

      final int page = event.page ?? 1;
      final int limit = event.limit ?? 5;
      final int offset = (page - 1) * limit;

      final results = await Future.wait([
        repository.getInventory(
          limit: limit,
          offset: offset,
          searchQuery: event.searchQuery,
          category: event.category,
          stockStatus: event.stockStatus,
          skipSync: event.skipSync,
        ),
        categoryRepository.getCategories(),
        repository.getInventoryCount(
          searchQuery: event.searchQuery,
          category: event.category,
          stockStatus: event.stockStatus,
        ),
      ]);

      final inventoryResult = results[0] as Either<String, List<InventoryItem>>;
      final categoriesResult = results[1] as Either<String, List<Category>>;
      final countResult = results[2] as Either<String, int>;

      inventoryResult.fold((failure) => emit(InventoryError(failure)), (items) {
        emit(
          InventoryLoaded(
            items,
            categories: categoriesResult.getOrElse(() => []),
            totalItems: countResult.getOrElse(() => 0),
            currentPage: page,
            limit: limit,
            searchQuery: event.searchQuery,
            category: event.category,
            stockStatus: event.stockStatus,
          ),
        );
      });
    });

    on<LoadInventoryCategoriesEvent>((event, emit) async {
      final result = await categoryRepository.getCategories();
      result.fold((failure) {}, (categories) {
        final currentState = state;
        if (currentState is InventoryLoaded) {
          emit(
            InventoryLoaded(
              currentState.items,
              categories: categories,
              totalItems: currentState.totalItems,
              currentPage: currentState.currentPage,
              searchQuery: currentState.searchQuery,
            ),
          );
        } else {
          // If not in Loaded state, emit Loaded with empty inventory but filled categories
          emit(
            InventoryLoaded(
              const [],
              categories: categories,
              totalItems: 0,
              currentPage: 1,
            ),
          );
        }
      });
    });

    on<AddInventoryItemEvent>((event, emit) async {
      final result = await repository.addInventoryItem(event.item);
      await result.fold(
        (failure) async => emit(InventoryError(failure)),
        (_) async {
          await _reloadAndEmit(emit, resetPage: true);
          final s = state as InventoryLoaded;
          syncService.syncAll(limit: s.limit, offset: 0);
        },
      );
    });

    on<UpdateInventoryItemEvent>((event, emit) async {
      final result = await repository.updateInventoryItem(event.item);
      await result.fold(
        (failure) async => emit(InventoryError(failure)),
        (_) async {
          await _reloadAndEmit(emit, resetPage: false);
          final s = state as InventoryLoaded;
          syncService.syncAll(limit: s.limit, offset: (s.currentPage - 1) * s.limit);
        },
      );
    });

    on<DeleteInventoryItemEvent>((event, emit) async {
      final result = await repository.deleteInventoryItem(event.id);
      await result.fold(
        (failure) async => emit(InventoryError(failure)),
        (_) async {
          await _reloadAndEmit(emit, resetPage: true);
          final s = state as InventoryLoaded;
          syncService.syncAll(limit: s.limit, offset: 0);
        },
      );
    });

    on<SyncAllEvent>((event, emit) async {
      final currentState = state;
      int limit = 5;
      int page = 1;
      String? searchQuery;
      String? category;
      String? stockStatus;

      if (currentState is InventoryLoaded) {
        page = currentState.currentPage;
        limit = currentState.limit;
        searchQuery = currentState.searchQuery;
        category = currentState.category;
        stockStatus = currentState.stockStatus;
      }

      await syncService.syncAll(limit: limit, offset: (page - 1) * limit);
      add(
        LoadInventory(
          page: page,
          limit: limit,
          searchQuery: searchQuery,
          category: category,
          stockStatus: stockStatus,
        ),
      );
    });
  }

  Future<void> _reloadAndEmit(Emitter<InventoryState> emit, {required bool resetPage}) async {
    final currentState = state;
    final page = (!resetPage && currentState is InventoryLoaded)
        ? currentState.currentPage
        : 1;
    int limit = 5;
    String? searchQuery;
    String? category;
    String? stockStatus;

    if (currentState is InventoryLoaded) {
      limit = currentState.limit;
      searchQuery = currentState.searchQuery;
      category = currentState.category;
      stockStatus = currentState.stockStatus;
    }

    final results = await Future.wait([
      repository.getInventory(
        limit: limit,
        offset: (page - 1) * limit,
        searchQuery: searchQuery,
        category: category,
        stockStatus: stockStatus,
      ),
      categoryRepository.getCategories(),
      repository.getInventoryCount(
        searchQuery: searchQuery,
        category: category,
        stockStatus: stockStatus,
      ),
    ]);

    emit(InventoryLoaded(
      (results[0] as Either<String, List<InventoryItem>>).getOrElse(() => []),
      categories: (results[1] as Either<String, List<Category>>).getOrElse(() => []),
      totalItems: (results[2] as Either<String, int>).getOrElse(() => 0),
      currentPage: page,
      limit: limit,
      searchQuery: searchQuery,
      category: category,
      stockStatus: stockStatus,
    ));
  }
}
