import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/domain/entities/transaction.dart' as ent;
import 'package:bradpos/presentation/blocs/transaction_detail/transaction_detail_bloc.dart';
import 'package:bradpos/presentation/blocs/transaction_detail/transaction_detail_event.dart';
import 'package:bradpos/presentation/blocs/transaction_detail/transaction_detail_state.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/injection_container.dart';

class TransactionDetailScreen extends StatelessWidget {
  final ent.Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return BlocProvider(
      create: (context) =>
          sl<TransactionDetailBloc>()
            ..add(FetchTransactionItems(transaction.id)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Detail Transaksi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        String shopName = 'BradPOS Store';
                        if (authState is AuthAuthenticated) {
                          shopName = authState.user.shopName ?? 'BradPOS Store';
                        }
                        return Text(
                          shopName.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      transaction.transactionNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(
                        'dd MMMM yyyy, HH:mm',
                      ).format(transaction.createdAt),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(
                      'Status',
                      transaction.status.toUpperCase(),
                      isStatus: true,
                    ),
                    _buildInfoRow('Kasir', transaction.cashierName ?? 'System'),
                    if (transaction.customerName != null)
                      _buildInfoRow('Pelanggan', transaction.customerName!),
                    _buildInfoRow(
                      'Metode Bayar',
                      transaction.paymentMethod.toUpperCase(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'DAFTAR PRODUK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              // Items List
              BlocBuilder<TransactionDetailBloc, TransactionDetailState>(
                builder: (context, state) {
                  if (state is TransactionDetailLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (state is TransactionDetailError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is TransactionDetailLoaded) {
                    return Column(
                      children: state.items
                          .map(
                            (item) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity} x ${currencyFormatter.format(item.unitPrice)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormatter.format(item.subtotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }
                  return const SizedBox();
                },
              ),

              const SizedBox(height: 24),

              // Summary Calculation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(
                      'Subtotal',
                      transaction.subtotal,
                      currencyFormatter,
                    ),
                    if (transaction.discount > 0)
                      _buildPriceRow(
                        'Diskon',
                        -transaction.discount,
                        currencyFormatter,
                        isDiscount: true,
                      ),
                    if (transaction.tax > 0)
                      _buildPriceRow(
                        'Pajak',
                        transaction.tax,
                        currencyFormatter,
                      ),
                    const Divider(height: 24),
                    _buildPriceRow(
                      'Total',
                      transaction.total,
                      currencyFormatter,
                      isTotal: true,
                    ),
                    const SizedBox(height: 12),
                    _buildPriceRow(
                      'Bayar',
                      transaction.paymentAmount,
                      currencyFormatter,
                    ),
                    _buildPriceRow(
                      'Kembali',
                      transaction.changeAmount,
                      currencyFormatter,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isStatus ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double value,
    NumberFormat formatter, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatter.format(value),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isDiscount
                  ? Colors.red
                  : (isTotal ? AppColors.primary : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
