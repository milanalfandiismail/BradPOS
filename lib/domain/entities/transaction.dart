import 'package:bradpos/domain/entities/transaction_item.dart';
import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String ownerId;
  final String? karyawanId;
  final String? cashierName;
  final String transactionNumber;
  final String? customerName;
  final String? customerPhone;
  final String? shopName;
  final List<TransactionItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final double paymentAmount;
  final double changeAmount;
  final String? notes;
  final String status;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.ownerId,
    this.karyawanId,
    this.cashierName,
    required this.transactionNumber,
    this.customerName,
    this.customerPhone,
    this.shopName,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    this.paymentMethod = 'cash',
    required this.paymentAmount,
    required this.changeAmount,
    this.notes,
    this.status = 'completed',
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    String? ownerId,
    String? karyawanId,
    String? cashierName,
    String? transactionNumber,
    String? customerName,
    String? customerPhone,
    String? shopName,
    List<TransactionItem>? items,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    String? paymentMethod,
    double? paymentAmount,
    double? changeAmount,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      karyawanId: karyawanId ?? this.karyawanId,
      cashierName: cashierName ?? this.cashierName,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    karyawanId,
    cashierName,
    transactionNumber,
    customerName,
    customerPhone,
    shopName,
    items,
    subtotal,
    discount,
    tax,
    total,
    paymentMethod,
    paymentAmount,
    changeAmount,
    notes,
    status,
    createdAt,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'karyawan_id': karyawanId,
      'cashier_name': cashierName,
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
