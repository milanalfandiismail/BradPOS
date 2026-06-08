import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/domain/entities/transaction.dart' as ent;
import 'package:bradpos/presentation/blocs/transaction_detail/transaction_detail_bloc.dart';
import 'package:bradpos/presentation/blocs/transaction_detail/transaction_detail_event.dart';
import 'package:bradpos/presentation/blocs/transaction_detail/transaction_detail_state.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/widgets/receipt_dialog.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/presentation/screens/report/transaction_info_row.dart';
import 'package:bradpos/presentation/screens/report/transaction_price_row.dart';

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

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
          toolbarHeight: isLandscape ? 40 : 56,
        ),
        body: SafeArea(
          child: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side: Info & Summary
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            _buildHeaderCard(context, isLandscape),
                            const SizedBox(height: 6),
                            _buildSummaryCard(currencyFormatter, isLandscape),
                          ],
                        ),
                      ),
                    ),
                    // Right Side: Product List & Action
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAFTAR PRODUK',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: isLandscape ? 9 : 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(child: _buildItemsList(currencyFormatter, isLandscape)),
                            const SizedBox(height: 8),
                            _buildPrintButton(context, isLandscape),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(context, isLandscape),
                            const SizedBox(height: 24),
                            const Text(
                              'DAFTAR PRODUK',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildItemsList(currencyFormatter, isLandscape),
                            const SizedBox(height: 24),
                            _buildSummaryCard(currencyFormatter, isLandscape),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        bottomNavigationBar: isLandscape
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPrintButton(context, isLandscape),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 10 : 20),
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
                  fontSize: isLandscape ? 10 : 16,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              );
            },
          ),
          SizedBox(height: isLandscape ? 4 : 12),
          Text(
            transaction.transactionNumber,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isLandscape ? 12 : 20,
            ),
          ),
          SizedBox(height: isLandscape ? 2 : 8),
          Text(
            DateFormat(
              'dd MMM yyyy, HH:mm',
            ).format(transaction.createdAt),
            style: TextStyle(color: Colors.grey, fontSize: isLandscape ? 9 : 14),
          ),
          Divider(height: isLandscape ? 16 : 32),
          TransactionInfoRow(
            label: 'Status',
            value: transaction.status.toUpperCase(),
            isStatus: true,
            isLandscape: isLandscape,
          ),
          TransactionInfoRow(label: 'Kasir', value: transaction.cashierName ?? 'System', isLandscape: isLandscape),
          if (transaction.customerName != null)
            TransactionInfoRow(label: 'Pelanggan', value: transaction.customerName!, isLandscape: isLandscape),
          TransactionInfoRow(
            label: 'Metode Bayar',
            value: transaction.paymentMethod.toUpperCase(),
            isLandscape: isLandscape,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(NumberFormat currencyFormatter, bool isLandscape) {
    return BlocBuilder<TransactionDetailBloc, TransactionDetailState>(
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
          final list = state.items
                .map(
                  (item) => Container(
                    margin: EdgeInsets.only(bottom: isLandscape ? 4 : 8),
                    padding: EdgeInsets.all(isLandscape ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isLandscape ? 10 : 14,
                                ),
                              ),
                              Text(
                                '${item.quantity} x ${currencyFormatter.format(item.unitPrice)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: isLandscape ? 8 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormatter.format(item.subtotal),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isLandscape ? 10 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList();
          return isLandscape 
            ? ListView(
                padding: EdgeInsets.zero,
                children: list,
              )
            : Column(children: list);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSummaryCard(NumberFormat currencyFormatter, bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 10 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TransactionPriceRow(
            label: 'Subtotal',
            value: transaction.subtotal,
            formatter: currencyFormatter,
            isLandscape: isLandscape,
          ),
          if (transaction.discount > 0)
            TransactionPriceRow(
              label: 'Diskon',
              value: -transaction.discount,
              formatter: currencyFormatter,
              isDiscount: true,
              isLandscape: isLandscape,
            ),
          if (transaction.tax > 0)
            TransactionPriceRow(
              label: 'Pajak',
              value: transaction.tax,
              formatter: currencyFormatter,
              isLandscape: isLandscape,
            ),
          Divider(height: isLandscape ? 12 : 24),
          TransactionPriceRow(
            label: 'Total',
            value: transaction.total,
            formatter: currencyFormatter,
            isTotal: true,
            isLandscape: isLandscape,
          ),
          SizedBox(height: isLandscape ? 4 : 12),
          TransactionPriceRow(
            label: 'Bayar',
            value: transaction.paymentAmount,
            formatter: currencyFormatter,
            isLandscape: isLandscape,
          ),
          TransactionPriceRow(
            label: 'Kembali',
            value: transaction.changeAmount,
            formatter: currencyFormatter,
            isLandscape: isLandscape,
          ),
        ],
      ),
    );
  }

  Widget _buildPrintButton(BuildContext context, bool isLandscape) {
    return BlocBuilder<TransactionDetailBloc, TransactionDetailState>(
      builder: (context, state) {
        if (state is TransactionDetailLoaded) {
          return SizedBox(
            width: double.infinity,
            height: isLandscape ? 36 : 56,
            child: ElevatedButton.icon(
              onPressed: () => _showReceipt(context, state),
              icon: Icon(Icons.print_rounded, size: isLandscape ? 16 : 24),
              label: Text(
                'PRINT RECEIPT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isLandscape ? 12 : 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isLandscape ? 8 : 16),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showReceipt(BuildContext context, TransactionDetailLoaded state) {
    final authState = context.read<AuthBloc>().state;
    String shopName = 'BradPOS Store';
    String? shopAddress;
    String? shopPhone;
    if (authState is AuthAuthenticated) {
      shopName = authState.user.shopName ?? 'BradPOS Store';
      shopAddress = authState.user.address;
      shopPhone = authState.user.phone;
    }

    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(
        items: state.items
            .map((e) => ReceiptItem(
                  productName: e.productName,
                  quantity: e.quantity,
                  unitPrice: e.unitPrice,
                  subtotal: e.subtotal,
                ))
            .toList(),
        shopName: shopName,
        customerName: transaction.customerName ?? 'Pelanggan Umum',
        cashierName: transaction.cashierName ?? 'System',
        amountReceived: transaction.paymentAmount,
        change: transaction.changeAmount,
        paymentMethod: transaction.paymentMethod,
        total: transaction.total,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
        date: transaction.createdAt,
      ),
    );
  }

}
