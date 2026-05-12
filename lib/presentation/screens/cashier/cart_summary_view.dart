import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';
import 'package:bradpos/presentation/screens/cashier/payment_screen.dart';

class CartSummaryView extends StatelessWidget {
  final CashierState state;
  final bool isSidebar;
  const CartSummaryView({
    super.key,
    required this.state,
    this.isSidebar = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSidebar) ...[
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
        Row(
          children: [
            Text(
              'Ringkasan',
              style: TextStyle(
                fontSize: isSidebar ? 12 : 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            if (state.cartItems.isNotEmpty)
              TextButton(
                onPressed: () {
                  context.read<CashierBloc>().add(ClearCart());
                  if (!isSidebar) Navigator.pop(context);
                },
                child: Text(
                  'HAPUS',
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w900,
                    fontSize: isSidebar ? 9 : 11,
                  ),
                ),
              ),
            if (!isSidebar)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
          ],
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        if (isSidebar) ...[const Divider(height: 1, color: Color(0xFFE2E8F0))],
        const SizedBox(height: 8),
        if (state.cartItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: isSidebar ? 48 : 64,
                    color: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Keranjang Kosong',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: state.cartItems.length,
            itemBuilder: (context, index) {
              final item = state.cartItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: TextStyle(
                        fontSize: isSidebar ? 9 : 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4338CA),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: isSidebar ? 9 : 13,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            currency.format(item.unitPrice),
                            style: TextStyle(
                              fontSize: isSidebar ? 8 : 9,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currency.format(item.subtotal),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isSidebar ? 9 : 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        if (isSidebar && state.cartItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Qty',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${state.cartItems.fold<int>(0, (s, i) => s + i.quantity)} item',
                  style: TextStyle(
                    fontSize: isSidebar ? 9 : 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rata-rata',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  currency.format(state.total / state.cartItems.length),
                  style: TextStyle(
                    fontSize: isSidebar ? 9 : 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tagihan',
                style: TextStyle(
                  fontSize: isSidebar ? 11 : 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                currency.format(state.total),
                style: TextStyle(
                  fontSize: isSidebar ? 14 : 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: isSidebar ? 32 : 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: state.cartItems.isEmpty
                ? null
                : () {
                    if (!isSidebar) Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(cashierState: state),
                      ),
                    );
                  },
            child: Text(
              'CHECKOUT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isSidebar ? 10 : 15,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        if (!isSidebar) const SizedBox(height: 20),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isSidebar ? 8 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isSidebar
            ? null
            : const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: !isSidebar,
        child: SingleChildScrollView(child: content),
      ),
    );
  }
}
