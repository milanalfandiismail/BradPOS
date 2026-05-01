import 'package:equatable/equatable.dart';

class TransactionItem extends Equatable {
  final String id;
  final String transactionId;
  final String? produkId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double subtotal;
  final DateTime createdAt;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    this.produkId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    required this.subtotal,
    required this.createdAt,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] ?? '',
      transactionId: map['transaction_id'],
      produkId: map['produk_id'],
      productName: map['product_name'],
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      subtotal: (map['subtotal'] as num).toDouble(),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      if (produkId != null) 'produk_id': produkId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TransactionItem copyWith({
    String? id,
    String? transactionId,
    String? produkId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? discount,
    double? subtotal,
    DateTime? createdAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      produkId: produkId ?? this.produkId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, transactionId, produkId, productName, quantity,
        unitPrice, discount, subtotal, createdAt,
      ];
}
