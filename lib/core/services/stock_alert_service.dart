import 'package:bradpos/data/data_sources/inventory_local_data_source.dart';

class StockAlertService {
  final InventoryLocalDataSource inventoryLocalDataSource;

  /// Total stok alert dari query terakhir (dipakai oleh MainBottomNavBar).
  int lastTotalAlert = 0;

  StockAlertService({required this.inventoryLocalDataSource});

  Future<int> getLowStockCount(String userId) async {
    try {
      return await inventoryLocalDataSource.getInventoryCount(
        userId,
        stockStatus: 'Low Stock',
      );
    } catch (_) {
      return 0;
    }
  }

  Future<int> getOutOfStockCount(String userId) async {
    try {
      return await inventoryLocalDataSource.getInventoryCount(
        userId,
        stockStatus: 'Out of Stock',
      );
    } catch (_) {
      return 0;
    }
  }

  Future<void> refreshCache(String userId) async {
    final results = await Future.wait([
      getLowStockCount(userId),
      getOutOfStockCount(userId),
    ]);
    lastTotalAlert = results[0] + results[1];
  }
}
