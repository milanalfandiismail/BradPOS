import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, dynamic>? selectedReceipt;

  final List<Map<String, dynamic>> receipts = [
    {
      'id': '#QC-88421',
      'date': 'Oct 24, 2023',
      'time': '10:32 PM',
      'amount': 142.50,
      'cashier': 'Sarah Miller',
      'items': [
        {'name': 'Double Espresso', 'qty': 2, 'price': 4.50, 'total': 9.00},
        {'name': 'Artisan Pastry Box', 'qty': 1, 'price': 28.00, 'total': 28.00},
        {'name': 'Custom Celebration Cake', 'qty': 1, 'price': 95.00, 'total': 95.00},
        {'name': 'Service fee', 'qty': 1, 'price': 5.50, 'total': 5.50, 'isFixed': true},
      ],
      'subtotal': 137.50,
      'tax': 5.00,
      'payment': 'Visa ending in •••• 4242',
    },
    {
      'id': '#QC-88420',
      'date': 'Oct 24, 2023',
      'time': '09:45 PM',
      'amount': 54.20,
    },
    {
      'id': '#QC-88419',
      'date': 'Oct 24, 2023',
      'time': '12:10 PM',
      'amount': -89.00,
    },
    {
      'id': '#QC-88418',
      'date': 'Oct 24, 2023',
      'time': '11:55 AM',
      'amount': 210.00,
    },
    {
      'id': '#QC-88417',
      'date': 'Oct 23, 2023',
      'time': '10:30 PM',
      'amount': 12.99,
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedReceipt = receipts[0]; // Default select first
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildReceiptTable(),
                    if (selectedReceipt != null) _buildReceiptDetails(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(activeLabel: 'HISTORY'),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Receipt ID...',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      icon: Icon(Icons.search, size: 20, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tune, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Filter', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Today', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Header Table
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('Receipt ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text('Date & Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          // Rows
          ...receipts.map((r) {
            final isSelected = selectedReceipt?['id'] == r['id'];
            return GestureDetector(
              onTap: () => setState(() => selectedReceipt = r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0F9F4) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                    left: BorderSide(color: isSelected ? Colors.green : Colors.transparent, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(r['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['date'], style: const TextStyle(fontSize: 12)),
                          Text(r['time'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(
                      '\$${r['amount'].toStringAsFixed(2).replaceAll('-', '')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: r['amount'] < 0 ? Colors.red : Colors.black,
                      ),
                    ),
                    if (r['amount'] < 0) const Text(' -', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReceiptDetails() {
    final r = selectedReceipt!;
    if (r['items'] == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Receipt Details', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => selectedReceipt = null),
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF065F46),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Cashier: ${r['cashier']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items List
          ... (r['items'] as List).map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('x${item['qty']} @ \$${item['price'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                Text('\$${item['total'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTotalRow('Subtotal', r['subtotal']),
                const SizedBox(height: 8),
                _buildTotalRow('Tax (5.5%)', r['tax']),
                const SizedBox(height: 12),
                _buildTotalRow('Total', r['amount'], isTotal: true),
              ],
            ),
          ),
          // Payment Method
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, size: 20, color: Color(0xFF065F46)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Method', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(r['payment'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Re-print'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF065F46),
                      side: const BorderSide(color: Color(0xFF065F46)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('Refund'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF065F46),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 14 : 13, color: isTotal ? Colors.black : Colors.grey, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text('\$${val.toStringAsFixed(2)}', style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
