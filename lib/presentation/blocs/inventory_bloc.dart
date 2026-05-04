import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:bradpos/core/sync/sync_service.dart';
import 'package:bradpos/domain/entities/category.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/domain/repositories/inventory_repository.dart';
import 'package:bradpos/domain/repositories/category_repository.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

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
            searchQuery: event.searchQuery,
          ),
        );
      });
    });

    on<LoadCategoriesEvent>((event, emit) async {
      final result = await categoryRepository.getCategories();
      result.fold((failure) {
      }, (categories) {
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
      await result.fold((failure) async => emit(InventoryError(failure)), (
        _,
      ) async {
        final loadResult = await repository.getInventory(limit: 5, offset: 0);
        final categoriesResult = await categoryRepository.getCategories();

        loadResult.fold((failure) => emit(InventoryError(failure)), (items) {
          emit(
            InventoryLoaded(
              items,
              categories: categoriesResult.getOrElse(() => []),
              totalItems: items.length,
              currentPage: 1,
            ),
          );
        });

        syncService.syncAll(limit: 5, offset: 0);
      });
    });

    on<UpdateInventoryItemEvent>((event, emit) async {
      final result = await repository.updateInventoryItem(event.item);
      await result.fold((failure) async => emit(InventoryError(failure)), (
        _,
      ) async {
        final currentState = state;
        int page = 1;
        if (currentState is InventoryLoaded) page = currentState.currentPage;

        final loadResult = await repository.getInventory(
          limit: 5,
          offset: (page - 1) * 5,
        );
        final categoriesResult = await categoryRepository.getCategories();

        loadResult.fold((failure) => emit(InventoryError(failure)), (items) {
          emit(
            InventoryLoaded(
              items,
              categories: categoriesResult.getOrElse(() => []),
              totalItems: items.length,
              currentPage: page,
            ),
          );
        });

        syncService.syncAll(limit: 5, offset: 0);
      });
    });

    on<DeleteInventoryItemEvent>((event, emit) async {
      final result = await repository.deleteInventoryItem(event.id);
      await result.fold((failure) async => emit(InventoryError(failure)), (
        _,
      ) async {
        final loadResult = await repository.getInventory(limit: 5, offset: 0);
        final categoriesResult = await categoryRepository.getCategories();

        loadResult.fold((failure) => emit(InventoryError(failure)), (items) {
          emit(
            InventoryLoaded(
              items,
              categories: categoriesResult.getOrElse(() => []),
              totalItems: items.length,
              currentPage: 1,
            ),
          );
        });

        syncService.syncAll(limit: 5, offset: 0);
      });
    });

    on<RefreshAfterSyncEvent>((event, emit) async {
      final currentState = state;
      if (currentState is InventoryLoaded &&
          currentState.searchQuery != null &&
          currentState.searchQuery!.isNotEmpty) {
        return;
      }

      int page = 1;
      if (currentState is InventoryLoaded) {
        page = currentState.currentPage;
      }

      int limit = 5;
      int offset = (page - 1) * limit;

      final results = await Future.wait([
        repository.getInventory(limit: limit, offset: offset),
        categoryRepository.getCategories(),
        repository.getInventoryCount(),
      ]);
      final inventoryResult = results[0] as Either<String, List<InventoryItem>>;
      final categoriesResult = results[1] as Either<String, List<Category>>;
      final countResult = results[2] as Either<String, int>;

      inventoryResult.fold(
        (_) => {},
        (items) => emit(
          InventoryLoaded(
            items,
            categories: categoriesResult.getOrElse(() => []),
            totalItems: countResult.getOrElse(() => 0),
            currentPage: page,
            searchQuery: null,
          ),
        ),
      );
    });

    on<SyncOfflineDataEvent>((event, emit) async {
      emit(InventoryLoading());
      final result = await repository.syncOfflineData();
      result.fold((failure) => emit(InventoryError(failure)), (_) {
        emit(
          const InventoryOperationSuccess(
            "Data offline berhasil disinkronkan ke akun",
          ),
        );
        syncService.syncAll(limit: 5, offset: 0);
        add(const LoadInventory(page: 1, limit: 5));
      });
    });

    on<SyncAllEvent>((event, emit) async {
      await syncService.syncAll(limit: 5, offset: 0);
      add(const LoadInventory(page: 1, limit: 5));
    });
  }
}
