import 'package:equatable/equatable.dart';

class InventoryItem extends Equatable {
  final String id;
  final String ownerId;
  final String? categoryId;
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final int stock; // -1 means unlimited
  final String unit;
  final String? barcode;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
    required this.id,
    required this.ownerId,
    this.categoryId,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    required this.unit,
    this.barcode,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      if (categoryId != null) 'category_id': categoryId,
      'name': name,
      'category': category,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'unit': unit,
      'barcode': barcode,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? ownerId,
    String? categoryId,
    String? name,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    int? stock,
    String? unit,
    String? barcode,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, ownerId, categoryId, name, category, purchasePrice, sellingPrice,
        stock, unit, barcode, imageUrl, isActive, createdAt, updatedAt,
      ];
}
