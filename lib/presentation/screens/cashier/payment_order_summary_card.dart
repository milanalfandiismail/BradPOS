import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';

class OrderSummaryListCard extends StatelessWidget {
  final CashierState cashierState;
  final NumberFormat currencyFormatter;
  final bool isCompact;

  const OrderSummaryListCard({
    super.key,
    required this.cashierState,
    required this.currencyFormatter,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 6 : 12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 6 : 10,
              vertical: isCompact ? 3 : 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: isCompact ? 9 : 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF475569),
                  ),
                ),
                Text(
                  '${cashierState.cartItems.length} Items',
                  style: TextStyle(
                    color: const Color(0xFF059669),
                    fontSize: isCompact ? 8 : 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 10,
                vertical: isCompact ? 1 : 4,
              ),
              itemCount: cashierState.cartItems.length,
              itemBuilder: (context, index) {
                final item = cashierState.cartItems[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: isCompact ? 1 : 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x',
                              style: TextStyle(
                                fontSize: isCompact ? 9 : 10,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            SizedBox(width: isCompact ? 4 : 8),
                            Expanded(
                              child: Text(
                                item.productName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: isCompact ? 9 : 11,
                                  color: const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currencyFormatter.format(item.subtotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 9 : 11,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
