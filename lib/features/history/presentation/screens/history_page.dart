import 'package:bradpos/features/settings/presentation/screens/settings_page.dart';
import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String dateTime;
  final double amount;
  final bool isRefunded;
  final bool isSelected;

  Transaction({
    required this.id,
    required this.dateTime,
    required this.amount,
    this.isRefunded = false,
    this.isSelected = false,
  });
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedTransactionId = "QC-88421";
  bool isDetailsExpanded = true;

  final List<Transaction> transactions = [
    Transaction(id: "QC-88421", dateTime: "Oct 24, 2023\n11:42 AM", amount: 142.38, isSelected: true),
    Transaction(id: "QC-88420", dateTime: "Oct 24, 2023\n10:15 AM", amount: 54.28),
    Transaction(id: "QC-88419", dateTime: "Oct 24, 2023\n09:30 AM", amount: -88.10, isRefunded: true),
    Transaction(id: "QC-88418", dateTime: "Oct 23, 2023\n18:42 PM", amount: 210.00),
    Transaction(id: "QC-88417", dateTime: "Oct 23, 2023\n17:20 PM", amount: 12.00),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey),
          ),
        ),
        title: const Text(
          "QuickCash POS",
          style: TextStyle(
            color: Color(0xFF1A1D1E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Cari ID Struk atau Pelanggan...",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: const Icon(Icons.tune, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF1F4FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("Hari Ini", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFFF1F4FA),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text("ID Struk", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Text("Tanggal & Waktu", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 1, child: Text("Jumlah", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.right)),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final t = transactions[index];
                bool isSelected = t.id == selectedTransactionId;
                return InkWell(
                  onTap: () => setState(() => selectedTransactionId = t.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                        left: BorderSide(color: isSelected ? const Color(0xFF007A5E) : Colors.transparent, width: 4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(t.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(flex: 2, child: Text(t.dateTime, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "${t.amount < 0 ? '-' : ''}Rp ${t.amount.abs().toStringAsFixed(0)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (t.isRefunded) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                                  child: const Text("REF", style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Receipt Details (Persistent Bottom Section)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: isDetailsExpanded ? MediaQuery.of(context).size.height * 0.5 : 80,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SingleChildScrollView(
              physics: isDetailsExpanded ? null : const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => isDetailsExpanded = !isDetailsExpanded),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Detail Struk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Icon(
                          isDetailsExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  if (isDetailsExpanded) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF007A5E), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("#QC-88421", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("Kasir: Sarah Miller", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _ReceiptItem(name: "Double Espresso", qty: 2, price: 4.00, total: 8.00),
                    const _ReceiptItem(name: "Kotak Kue Artisan", qty: 1, price: 24.50, total: 24.50),
                    const _ReceiptItem(name: "Kue Perayaan Custom", qty: 1, price: 95.00, total: 95.00, subtitle: "dengan lilin"),
                    const _ReceiptItem(name: "Biaya Layanan", total: 10.50, isFixed: true),
                    const Divider(height: 32),
                    const _SummaryRow(label: "Subtotal", value: 138.00),
                    const _SummaryRow(label: "Pajak (5.0%)", value: 4.38),
                    const _SummaryRow(label: "Total", value: 142.38, isTotal: true),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF1F4FA), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.payment, color: Color(0xFF007A5E), size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Metode Pembayaran", style: TextStyle(color: Colors.grey, fontSize: 10)),
                              Text("Visa berakhiran **** 4242", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text("Kode Auth: 789412", style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text("Cetak Ulang"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF007A5E),
                              side: const BorderSide(color: Color(0xFF007A5E)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.keyboard_return, size: 18),
                            label: const Text("Refund"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007A5E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  final String name;
  final int? qty;
  final double? price;
  final double total;
  final String? subtitle;
  final bool isFixed;

  const _ReceiptItem({
    required this.name,
    this.qty,
    this.price,
    required this.total,
    this.subtitle,
    this.isFixed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (qty != null && price != null)
                  Text("x$qty @ Rp ${price!.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                if (isFixed)
                  const Text("Tetap", style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text("Rp ${total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _SummaryRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.black : Colors.grey, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 14 : 13)),
          Text(
            "Rp ${value.toStringAsFixed(0)}",
            style: TextStyle(
              color: isTotal ? const Color(0xFF007A5E) : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
