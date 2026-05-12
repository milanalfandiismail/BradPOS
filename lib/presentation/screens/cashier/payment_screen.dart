import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';
import 'package:bradpos/presentation/widgets/numpad_widget.dart';
import 'package:bradpos/presentation/widgets/receipt_dialog.dart';
import 'package:bradpos/presentation/screens/cashier/payment_order_summary_card.dart';
import 'package:bradpos/presentation/screens/cashier/payment_checkout_card.dart';
import 'package:bradpos/presentation/screens/cashier/payment_combined_summary_card.dart';
import 'package:bradpos/presentation/screens/cashier/payment_methods_widget.dart';
import 'package:bradpos/presentation/screens/cashier/payment_customer_card.dart';
import 'package:bradpos/presentation/screens/cashier/payment_bottom_actions.dart';

class PaymentScreen extends StatefulWidget {
  final CashierState cashierState;

  const PaymentScreen({super.key, required this.cashierState});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _customerController = TextEditingController();
  String _amountReceivedStr = '0';
  String _selectedMethod = 'Cash';
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  void _onNumberPressed(String val) {
    setState(() {
      if (_amountReceivedStr == '0') {
        if (val == '0' || val == '00') return;
        _amountReceivedStr = val;
      } else {
        _amountReceivedStr += val;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountReceivedStr.length > 1) {
        _amountReceivedStr = _amountReceivedStr.substring(
          0,
          _amountReceivedStr.length - 1,
        );
      } else {
        _amountReceivedStr = '0';
      }
    });
  }

  void _onClear() {
    setState(() => _amountReceivedStr = '0');
  }

  void _onPaymentMethodChanged(String method) {
    setState(() {
      _selectedMethod = method;
      if (method == 'QRIS') {
        _amountReceivedStr = widget.cashierState.total.toInt().toString();
      }
    });
  }

  void _onShortcutPressed(double amount) {
    setState(() => _amountReceivedStr = amount.toInt().toString());
  }

  double get _amountReceived => double.tryParse(_amountReceivedStr) ?? 0;
  double get _balanceDue => widget.cashierState.total;
  double get _change => _amountReceived - _balanceDue;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final canConfirm =
        _amountReceived >= _balanceDue || _selectedMethod != 'Cash';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(isLandscape: isLandscape),
      body: SafeArea(
        child: isLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          PaymentMethodsWidget(
                            selectedMethod: _selectedMethod,
                            isCompact: true,
                            onMethodChanged: _onPaymentMethodChanged,
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: NumpadWidget(
                              amountReceived: _amountReceived,
                              balanceDue: _balanceDue,
                              currencyFormatter: currencyFormatter,
                              isCompact: true,
                              onNumberPressed: _onNumberPressed,
                              onBackspace: _onBackspace,
                              onClear: _onClear,
                              onShortcutPressed: _onShortcutPressed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          CustomerCard(
                            controller: _customerController,
                            isCompact: true,
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: OrderSummaryListCard(
                              cashierState: widget.cashierState,
                              currencyFormatter: currencyFormatter,
                              isCompact: true,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CheckoutCard(
                            amountReceived: _amountReceived,
                            balanceDue: _balanceDue,
                            change: _change,
                            currencyFormatter: currencyFormatter,
                            isCompact: true,
                            onConfirm: _processPayment,
                            onCancel: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomerCard(
                      controller: _customerController,
                      isCompact: false,
                    ),
                    const SizedBox(height: 8),
                    PaymentMethodsWidget(
                      selectedMethod: _selectedMethod,
                      isCompact: false,
                      onMethodChanged: _onPaymentMethodChanged,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 5,
                      child: NumpadWidget(
                        amountReceived: _amountReceived,
                        balanceDue: _balanceDue,
                        currencyFormatter: currencyFormatter,
                        isCompact: false,
                        onNumberPressed: _onNumberPressed,
                        onBackspace: _onBackspace,
                        onClear: _onClear,
                        onShortcutPressed: _onShortcutPressed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 4,
                      child: CombinedSummaryCard(
                        cashierState: widget.cashierState,
                        currencyFormatter: currencyFormatter,
                        balanceDue: _balanceDue,
                        change: _change,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: !isLandscape
          ? PaymentBottomActions(
              canConfirm: canConfirm,
              onConfirm: _processPayment,
              onCancel: () => Navigator.pop(context),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar({bool isLandscape = false}) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: isLandscape ? 36 : 48,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.black,
          size: isLandscape ? 14 : 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) => Text(
          state.displayShopName,
          style: TextStyle(
              color: const Color(0xFF0F172A),
              fontSize: isLandscape ? 11 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

  void _processPayment() {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      FocusScope.of(context).unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B),
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'Konfirmasi',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${currencyFormatter.format(_balanceDue)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Bayar: ${currencyFormatter.format(_amountReceived)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_change > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Kembalian: ${currencyFormatter.format(_change)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF059669),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Yakin ingin memproses pembayaran ini?',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executePayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Ya, Proses',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executePayment() {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      FocusScope.of(context).unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
    context.read<CashierBloc>().add(
      ProcessPayment(
        paymentAmount: _amountReceived,
        paymentMethod: _selectedMethod.toLowerCase(),
        customerName: _customerController.text.trim().isEmpty
            ? 'Pelanggan Umum'
            : _customerController.text.trim(),
      ),
    );
    Navigator.pop(context);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Transaction has been recorded.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _printReceipt,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.print_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  label: const Text(
                    'PRINT RECEIPT',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _printReceipt() {
    final state = context.read<AuthBloc>().state;
    final shopName = state.displayShopName;
    String? shopAddress;
    String? shopPhone;
    if (state is AuthAuthenticated) {
      shopAddress = state.user.address;
      shopPhone = state.user.phone;
    }

    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(
        items: widget.cashierState.cartItems
            .map(
              (e) => ReceiptItem(
                productName: e.productName,
                quantity: e.quantity,
                unitPrice: e.unitPrice,
                subtotal: e.subtotal,
              ),
            )
            .toList(),
        shopName: shopName,
        customerName: _customerController.text.trim().isEmpty
            ? 'Pelanggan Umum'
            : _customerController.text.trim(),
        cashierName: state is AuthAuthenticated
            ? (state.user.name ?? 'System')
            : 'System',
        amountReceived: _amountReceived,
        change: _change,
        paymentMethod: _selectedMethod,
        total: widget.cashierState.total,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
      ),
    );
  }
}
