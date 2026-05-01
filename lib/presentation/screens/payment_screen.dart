import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';

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
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

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
        _amountReceivedStr = _amountReceivedStr.substring(0, _amountReceivedStr.length - 1);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildPaymentMethods(),
              const SizedBox(height: 20),
              _buildNumpadSection(),
              const SizedBox(height: 20),
              if (_selectedMethod == 'QRIS') _buildInfoCard('QRIS Dynamic', 'Ready to scan', Icons.qr_code_scanner_rounded),
              if (_selectedMethod == 'Card') _buildInfoCard('Card Terminal', 'Terminal ID: 4421', Icons.contactless_rounded),
              const SizedBox(height: 20),
              _buildOrderSummary(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
      title: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String shopName = 'BradPOS';
          if (state is AuthAuthenticated) shopName = state.user.shopName ?? 'BradPOS';
          return Row(
            children: [
              Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Center(child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 16))),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shopName, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900)),
                  Text('TRX-#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
      actions: [IconButton(icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)), onPressed: () {})],
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Methods', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          Row(
            children: [
              _methodCard('Cash', Icons.payments_outlined),
              const SizedBox(width: 12),
              _methodCard('QRIS', Icons.qr_code_rounded),
              const SizedBox(width: 12),
              _methodCard('Card', Icons.credit_card_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _methodCard(String label, IconData icon) {
    final isSelected = _selectedMethod == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = label),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF059669) : const Color(0xFF475569), size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isSelected ? const Color(0xFF065F46) : const Color(0xFF475569))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Received', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
              TextButton.icon(onPressed: _onClear, icon: const Icon(Icons.cancel, size: 16, color: Color(0xFFEF4444)), label: const Text('Clear', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Text(currencyFormatter.format(_amountReceived), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5,
                  children: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '00', 'DEL'].map((e) => _numBtn(e)).toList(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _shortcutBtn('Pas', _balanceDue),
                    const SizedBox(height: 10),
                    _shortcutBtn('20k', 20000),
                    const SizedBox(height: 10),
                    _shortcutBtn('50k', 50000),
                    const SizedBox(height: 10),
                    _shortcutBtn('100k', 100000),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numBtn(String val) => InkWell(
    onTap: () => val == 'DEL' ? _onBackspace() : _onNumberPressed(val),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      alignment: Alignment.center, 
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), 
      child: val == 'DEL' 
          ? const Icon(Icons.backspace_rounded, size: 20, color: Color(0xFF1E293B))
          : Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))
    ),
  );

  Widget _shortcutBtn(String label, double amount) => InkWell(
    onTap: () => _onShortcutPressed(amount),
    borderRadius: BorderRadius.circular(12),
    child: Container(height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)), child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF4338CA)))),
  );

  Widget _buildInfoCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF4338CA), size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))]),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)), child: Text('${widget.cashierState.cartItems.length} Items', style: const TextStyle(color: Color(0xFF4338CA), fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              controller: _customerController,
              decoration: const InputDecoration(
                hintText: 'Customer Name (Optional)',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                icon: Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.cashierState.cartItems.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))), Text('Qty: ${item.quantity}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))])),
                Text(currencyFormatter.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
              ],
            ),
          )),
          if (widget.cashierState.cartItems.length > 3) const Center(child: Icon(Icons.more_horiz, color: Colors.grey)),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Amount', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)), Text(currencyFormatter.format(_balanceDue), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_change >= 0 ? 'Change' : 'Balance Due', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  Text(currencyFormatter.format(_change.abs()), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _change >= 0 ? const Color(0xFF1E293B) : const Color(0xFFEF4444))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final canConfirm = _amountReceived >= _balanceDue || _selectedMethod != 'Cash';
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: canConfirm ? _processPayment : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Confirm Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)), SizedBox(width: 8), Icon(Icons.check_circle_rounded, color: Colors.white, size: 20)]),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel Order', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 8),
            Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${currencyFormatter.format(_balanceDue)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Bayar: ${currencyFormatter.format(_amountReceived)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (_change > 0) ...[
              const SizedBox(height: 4),
              Text('Kembalian: ${currencyFormatter.format(_change)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF059669))),
            ],
            const SizedBox(height: 12),
            const Text('Yakin ingin memproses pembayaran ini?', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _executePayment();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Ya, Proses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _executePayment() {
    context.read<CashierBloc>().add(ProcessPayment(
      paymentAmount: _amountReceived,
      paymentMethod: _selectedMethod.toLowerCase(),
      customerName: _customerController.text.trim().isEmpty ? 'Pelanggan Umum' : _customerController.text.trim(),
    ));
    Navigator.pop(context); // Close PaymentScreen
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 80),
            const SizedBox(height: 24),
            const Text('Payment Successful', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('Transaction has been recorded.', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Dialog
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('DONE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
