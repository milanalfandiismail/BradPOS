import 'package:dartz/dartz.dart';
import '../entities/category.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

/// Use Case untuk mengambil semua data inventori milik owner.
class GetInventory {
  final InventoryRepository repository;
  GetInventory(this.repository);

  Future<Either<String, List<InventoryItem>>> call({int? limit, int? offset}) async {
    return await repository.getInventory(limit: limit, offset: offset);
  }
}

class GetInventoryCount {
  final InventoryRepository repository;
  GetInventoryCount(this.repository);

  Future<Either<String, int>> call() async {
    return await repository.getInventoryCount();
  }
}

/// Use Case untuk menambah item inventori baru.
class AddInventoryItem {
  final InventoryRepository repository;
  AddInventoryItem(this.repository);

  Future<Either<String, InventoryItem>> call(InventoryItem item) async {
    return await repository.addInventoryItem(item);
  }
}

/// Use Case untuk memperbarui item inventori.
class UpdateInventoryItem {
  final InventoryRepository repository;
  UpdateInventoryItem(this.repository);

  Future<Either<String, InventoryItem>> call(InventoryItem item) async {
    return await repository.updateInventoryItem(item);
  }
}

/// Use Case untuk menghapus item inventori.
class DeleteInventoryItem {
  final InventoryRepository repository;
  DeleteInventoryItem(this.repository);

  Future<Either<String, void>> call(String id) async {
    return await repository.deleteInventoryItem(id);
  }
}

/// Use Case untuk mengambil daftar kategori.
class GetCategories {
  final InventoryRepository repository;
  GetCategories(this.repository);

  Future<Either<String, List<Category>>> call() async {
    return await repository.getCategories();
  }
}

class SyncOfflineData {
  final InventoryRepository repository;
  SyncOfflineData(this.repository);

  Future<Either<String, void>> call() async {
    return await repository.syncOfflineData();
  }
}

class HasOfflineData {
  final InventoryRepository repository;
  HasOfflineData(this.repository);

  Future<bool> call() async {
    return await repository.hasOfflineData();
  }
}