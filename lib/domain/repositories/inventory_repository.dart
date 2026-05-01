import 'package:dartz/dartz.dart';
import '../entities/inventory_item.dart';
import '../entities/category.dart';

abstract class InventoryRepository {
  Future<Either<String, List<InventoryItem>>> getInventory({
    int? limit,
    int? offset,
    String? searchQuery,
    String? category,
    String? stockStatus,
  });
  Future<Either<String, int>> getInventoryCount({
    String? searchQuery,
    String? category,
    String? stockStatus,
  });


  Future<Either<String, InventoryItem>> addInventoryItem(InventoryItem item);

  Future<Either<String, InventoryItem>> updateInventoryItem(InventoryItem item);

  Future<Either<String, void>> deleteInventoryItem(String id);
  Future<bool> isProductNameExists(String name, {String? excludeId});

  Future<Either<String, List<Category>>> getCategories();

  Future<bool> hasOfflineData();
  Future<Either<String, void>> syncOfflineData();
}
