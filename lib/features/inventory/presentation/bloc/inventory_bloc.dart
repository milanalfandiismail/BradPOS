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
  final AddInventoryItem addInventoryItem;
  final UpdateInventoryItem updateInventoryItem;
  final DeleteInventoryItem deleteInventoryItem;
  final GetCategories getCategories;
  final SyncService syncService;
  final SyncOfflineData syncOfflineData;

  InventoryBloc({
    required this.getInventory,
    required this.addInventoryItem,
    required this.updateInventoryItem,
    required this.deleteInventoryItem,
    required this.getCategories,
    required this.syncService,
    required this.syncOfflineData,
  }) : super(InventoryInitial()) {
    on<LoadInventory>((event, emit) async {
      emit(InventoryLoading());

      final results = await Future.wait([getInventory(), getCategories()]);
      final inventoryResult = results[0] as Either<String, List<InventoryItem>>;
      final categoriesResult = results[1] as Either<String, List<Category>>;

      inventoryResult.fold((failure) => emit(InventoryError(failure)), (items) {
        emit(
          InventoryLoaded(
            items,
            categories: categoriesResult.getOrElse(() => []),
          ),
        );

        // BACKGROUND SYNC: Tarik data terbaru dari server di balik layar
        // agar data lokal tetap fresh tanpa bikin loading lama
        syncService.syncAll().then((_) {
          add(RefreshAfterSyncEvent());
        });
      });
    });

    on<LoadCategoriesEvent>((event, emit) async {
      final result = await getCategories();
      result.fold((_) {}, (categories) {
        final currentState = state;
        if (currentState is InventoryLoaded) {
          emit(InventoryLoaded(currentState.items, categories: categories));
        }
      });
    });

    on<AddInventoryItemEvent>((event, emit) async {
      // Kita tidak perlu emit(InventoryLoading) di sini agar UI tidak terblokir
      // atau jika ingin tetap ada, pastikan prosesnya sangat cepat.
      final result = await addInventoryItem(event.item);
      result.fold((failure) => emit(InventoryError(failure)), (_) {
        emit(const InventoryOperationSuccess("Produk berhasil ditambahkan"));
        
        // INSTANT: Langsung update layar dari data lokal SQLite
        add(LoadInventory());

        // BACKGROUND: Jalankan sinkronisasi di balik layar
        syncService.syncAll().then((_) {
          add(RefreshAfterSyncEvent());
        });
      });
    });

    on<UpdateInventoryItemEvent>((event, emit) async {
      final result = await updateInventoryItem(event.item);
      result.fold((failure) => emit(InventoryError(failure)), (_) {
        emit(const InventoryOperationSuccess("Produk berhasil diperbarui"));
        
        // INSTANT: Langsung update layar dari data lokal SQLite
        add(LoadInventory());

        // BACKGROUND: Jalankan sinkronisasi di balik layar
        syncService.syncAll().then((_) {
          add(RefreshAfterSyncEvent());
        });
      });
    });

    on<DeleteInventoryItemEvent>((event, emit) async {
      emit(InventoryLoading());
      final result = await deleteInventoryItem(event.id);
      result.fold((failure) => emit(InventoryError(failure)), (_) {
        emit(const InventoryOperationSuccess("Produk berhasil dihapus"));
        add(LoadInventory());

        // AUTO SYNC: Langsung hapus di cloud di balik layar
        syncService.syncAll().then((_) {
          add(RefreshAfterSyncEvent());
        });
      });
    });

    on<RefreshAfterSyncEvent>((event, emit) async {
      // Sama seperti LoadInventory tapi tanpa emit(InventoryLoading)
      // agar tidak ada flickering loading di UI saat background sync selesai
      final results = await Future.wait([getInventory(), getCategories()]);
      final inventoryResult = results[0] as Either<String, List<InventoryItem>>;
      final categoriesResult = results[1] as Either<String, List<Category>>;

      inventoryResult.fold(
        (_) => {}, // Abaikan error jika background refresh
        (items) => emit(
          InventoryLoaded(
            items,
            categories: categoriesResult.getOrElse(() => []),
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
        // Jalankan full sync untuk ngepush data yang baru dimigrasi
        syncService.syncAll();
        add(LoadInventory());
      });
    });

    on<SyncAllEvent>((event, emit) async {
      // Manual refresh dari UI
      await syncService.syncAll();
      add(LoadInventory());
    });
  }
}
