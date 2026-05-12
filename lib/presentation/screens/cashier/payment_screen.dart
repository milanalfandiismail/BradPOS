import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';
import 'package:bradpos/presentation/widgets/numpad_widget.dart';
import 'package:bradpos/presentation/widgets/receipt_dialog.dart';

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
                          _buildPaymentMethods(isCompact: true),
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
                          _buildCustomerCard(isCompact: true),
                          const SizedBox(height: 4),
                          Expanded(
                            child: _buildOrderSummaryListCard(isCompact: true),
                          ),
                          const SizedBox(height: 4),
                          _buildCheckoutCard(isCompact: true),
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
                    _buildCustomerCard(isCompact: false),
                    const SizedBox(height: 8),
                    _buildPaymentMethods(isCompact: false),
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
                      child: _buildCombinedSummaryCard(isCompact: false),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: !isLandscape ? _buildBottomActionsPortrait() : null,
    );
  }

  Widget _buildOrderSummaryListCard({bool isCompact = false}) {
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
                  '${widget.cashierState.cartItems.length} Items',
                  style: TextStyle(
                    color: const Color(0xFF4338CA),
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
              itemCount: widget.cashierState.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cashierState.cartItems[index];
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
                                color: const Color(0xFF4338CA),
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

  Widget _buildCheckoutCard({bool isCompact = false}) {
    final canConfirm =
        _amountReceived >= _balanceDue || _selectedMethod != 'Cash';

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
      padding: EdgeInsets.all(isCompact ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tagihan',
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 8 : 10,
                ),
              ),
              Text(
                currencyFormatter.format(_balanceDue),
                style: TextStyle(
                  fontSize: isCompact ? 10 : 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (!isCompact) const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _change >= 0 ? 'Kembalian' : 'Kurang',
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 8 : 10,
                ),
              ),
              Text(
                currencyFormatter.format(_change.abs()),
                style: TextStyle(
                  fontSize: isCompact ? 10 : 13,
                  fontWeight: FontWeight.w900,
                  color: _change >= 0
                      ? const Color(0xFF059669)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 2 : 6),
          SizedBox(
            width: double.infinity,
            height: isCompact ? 20 : 36,
            child: ElevatedButton(
              onPressed: canConfirm ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
                ),
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 9 : 12,
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 2 : 4),
          SizedBox(
            width: double.infinity,
            height: isCompact ? 18 : 28,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
                ),
              ),
              child: Text(
                'Cancel Order',
                style: TextStyle(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 8 : 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedSummaryCard({bool isCompact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  '${widget.cashierState.cartItems.length} Items',
                  style: const TextStyle(
                    color: Color(0xFF4338CA),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: widget.cashierState.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cashierState.cartItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tagihan',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(_balanceDue),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _change >= 0 ? 'Kembalian' : 'Kurang',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(_change.abs()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _change >= 0
                            ? const Color(0xFF059669)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildPaymentMethods({bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 4 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 6 : 12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Row(
        children: [
          _methodCard('Cash', Icons.payments_outlined, isCompact: isCompact),
          SizedBox(width: isCompact ? 4 : 8),
          _methodCard('QRIS', Icons.qr_code_rounded, isCompact: isCompact),
        ],
      ),
    );
  }

  Widget _methodCard(String label, IconData icon, {bool isCompact = false}) {
    final isSelected = _selectedMethod == label;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = label;
            if (label == 'QRIS') {
              _amountReceivedStr = widget.cashierState.total.toInt().toString();
            }
          });
        },
        child: Container(
          height: isCompact ? 24 : 36,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF059669)
                    : const Color(0xFF475569),
                size: isCompact ? 11 : 16,
              ),
              SizedBox(width: isCompact ? 2 : 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isCompact ? 8 : 13,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? const Color(0xFF065F46)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard({bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 12,
        vertical: isCompact ? 2 : 12,
      ),
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
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: isCompact ? 12 : 22,
            color: const Color(0xFF64748B),
          ),
          SizedBox(width: isCompact ? 3 : 8),
          Expanded(
            child: TextField(
              controller: _customerController,
              decoration: InputDecoration(
                hintText: 'Nama Pelanggan',
                hintStyle: TextStyle(
                  fontSize: isCompact ? 8 : 13,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: isCompact ? 9 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomActionsPortrait() {
    final canConfirm =
        _amountReceived >= _balanceDue || _selectedMethod != 'Cash';
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: canConfirm ? _processPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel Order',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
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
