import 'package:bradpos/domain/entities/inventory_item.dart';

class InventoryItemModel extends InventoryItem {
  const InventoryItemModel({
    required super.id,
    required super.ownerId,
    super.categoryId,
    required super.name,
    required super.category,
    required super.purchasePrice,
    required super.sellingPrice,
    required super.stock,
    required super.unit,
    super.barcode,
    super.imageUrl,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      categoryId: json['category_id'],
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
      sellingPrice: (json['selling_price'] ?? 0).toDouble(),
      stock: json['stock'] ?? -1,
      unit: json['unit'] ?? 'pcs',
      barcode: json['barcode'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.parse(json['created_at']),
    );
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: map['id'] ?? '',
      ownerId: map['owner_id'] ?? '',
      categoryId: map['category_id'],
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      purchasePrice: (map['purchase_price'] ?? 0).toDouble(),
      sellingPrice: (map['selling_price'] ?? 0).toDouble(),
      stock: map['stock'] ?? -1,
      unit: map['unit'] ?? 'pcs',
      barcode: map['barcode'],
      imageUrl: map['image_url'],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'category_id': categoryId,
      'name': name,
      'category': category,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'unit': unit,
      'barcode': barcode,
      'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItemModel.fromEntity(InventoryItem item) {
    return InventoryItemModel(
      id: item.id,
      ownerId: item.ownerId,
      categoryId: item.categoryId,
      name: item.name,
      category: item.category,
      purchasePrice: item.purchasePrice,
      sellingPrice: item.sellingPrice,
      stock: item.stock,
      unit: item.unit,
      barcode: item.barcode,
      imageUrl: item.imageUrl,
      isActive: item.isActive,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }
}
