import 'package:bradpos/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.ownerId,
    super.karyawanId,
    required super.transactionNumber,
    super.customerName,
    super.customerPhone,
    required super.subtotal,
    super.discount = 0,
    super.tax = 0,
    required super.total,
    super.paymentMethod = 'cash',
    required super.paymentAmount,
    required super.changeAmount,
    super.notes,
    super.status = 'completed',
    required super.createdAt,
  });

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      id: entity.id,
      ownerId: entity.ownerId,
      karyawanId: entity.karyawanId,
      transactionNumber: entity.transactionNumber,
      customerName: entity.customerName,
      customerPhone: entity.customerPhone,
      subtotal: entity.subtotal,
      discount: entity.discount,
      tax: entity.tax,
      total: entity.total,
      paymentMethod: entity.paymentMethod,
      paymentAmount: entity.paymentAmount,
      changeAmount: entity.changeAmount,
      notes: entity.notes,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      ownerId: map['owner_id'],
      karyawanId: map['karyawan_id'],
      transactionNumber: map['transaction_number'],
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'],
      paymentAmount: (map['payment_amount'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num).toDouble(),
      notes: map['notes'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'karyawan_id': karyawanId,
      'transaction_number': transactionNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'payment_method': paymentMethod,
      'payment_amount': paymentAmount,
      'change_amount': changeAmount,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
