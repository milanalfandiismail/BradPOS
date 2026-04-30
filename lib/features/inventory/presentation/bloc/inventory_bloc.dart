import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/usecases/inventory_usecases.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GetInventory getInventory;
  final GetInventoryCount getInventoryCount;
  final AddInventoryItem addInventoryItem;
  final UpdateInventoryItem updateInventoryItem;
  final DeleteInventoryItem deleteInventoryItem;
  final GetCategories getCategories;
  final SyncService syncService;
  final SyncOfflineData syncOfflineData;

  InventoryBloc({
    required this.getInventory,
    required this.getInventoryCount,
    required this.addInventoryItem,
    required this.updateInventoryItem,
    required this.deleteInventoryItem,
    required this.getCategories,
    required this.syncService,
    required this.syncOfflineData,
  }) : super(InventoryInitial()) {
    on<LoadInventory>((event, emit) async {
      emit(InventoryLoading());

      final int page = event.page ?? 1;
      final int limit = event.limit ?? 5;
      final int offset = (page - 1) * limit;

      final results = await Future.wait([
        getInventory(limit: limit, offset: offset), 
        getCategories(),
        getInventoryCount(),
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
      final result = await getCategories();
      result.fold((_) {}, (categories) {
        final currentState = state;
        if (currentState is InventoryLoaded) {
          emit(InventoryLoaded(
            currentState.items, 
            categories: categories,
            totalItems: currentState.totalItems,
            currentPage: currentState.currentPage,
            searchQuery: currentState.searchQuery,
          ));
        }
      });
    });

    on<AddInventoryItemEvent>((event, emit) async {
      final result = await addInventoryItem(event.item);
      result.fold((failure) => emit(InventoryError(failure)), (_) {
        emit(const InventoryOperationSuccess("Produk berhasil ditambahkan"));
        
        // Refresh UI dari lokal saja
        add(const LoadInventory(page: 1, limit: 5));

        // PUSH saja ke server (SyncAll handles push and pull, but we don't refresh UI from pull)
        // Kita biarkan jalan di background tanpa mengganggu UI
        syncService.syncAll(limit: 5, offset: 0);
      });
    });

    on<UpdateInventoryItemEvent>((event, emit) async {
      final result = await updateInventoryItem(event.item);
      result.fold((failure) => emit(InventoryError(failure)), (_) {
        emit(const InventoryOperationSuccess("Produk berhasil diperbarui"));
        
        // Refresh UI dari lokal saja
        final currentState = state;
        int page = 1;
        if (currentState is InventoryLoaded) page = currentState.currentPage;
        add(LoadInventory(page: page, limit: 5));

        // PUSH saja ke server di background
        syncService.syncAll(limit: 5, offset: 0);
      });
    });

    on<DeleteInventoryItemEvent>((event, emit) async {
      emit(InventoryLoading());
      final result = await deleteInventoryItem(event.id);
      result.fold((failure) => emit(InventoryError(failure)), (_) {
        emit(const InventoryOperationSuccess("Produk berhasil dihapus"));
        
        // Refresh UI dari lokal saja
        add(const LoadInventory(page: 1, limit: 5));

        // PUSH saja ke server di background
        syncService.syncAll(limit: 5, offset: 0);
      });
    });

    on<RefreshAfterSyncEvent>((event, emit) async {
      final currentState = state;
      // JANGAN REFRESH jika sedang mode search agar hasil cari tidak tertimpa
      if (currentState is InventoryLoaded && currentState.searchQuery != null && currentState.searchQuery!.isNotEmpty) {
        return;
      }

      int page = 1;
      if (currentState is InventoryLoaded) {
        page = currentState.currentPage;
      }

      int limit = 5;
      int offset = (page - 1) * limit;
      
      final results = await Future.wait([
        getInventory(limit: limit, offset: offset),
        getCategories(),
        getInventoryCount(),
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
      final result = await syncOfflineData();
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
