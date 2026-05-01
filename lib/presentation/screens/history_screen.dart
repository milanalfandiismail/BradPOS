import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/history/history_bloc.dart';
import 'package:bradpos/presentation/blocs/history/history_event.dart';
import 'package:bradpos/presentation/blocs/history/history_state.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/screens/report/transaction_detail_screen.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (_selectedDateRange != null) {
      final start = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
        0, 0, 0
      );
      final end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23, 59, 59
      );
      context.read<HistoryBloc>().add(LoadHistoryByRangeEvent(start, end));
    } else {
      context.read<HistoryBloc>().add(LoadHistoryEvent());
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadData();
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Data transaksi ini akan dihapus permanen. Stok tidak akan dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryBloc>().add(DeleteTransactionEvent(id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DateTimeRange? range) {
    final isSelected = (_selectedDateRange == null && range == null) ||
        (_selectedDateRange != null && range != null && 
         _isSameDay(_selectedDateRange!.start, range.start) && 
         _isSameDay(_selectedDateRange!.end, range.end));

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedDateRange = range;
            });
            _loadData();
          }
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isQuickRange(DateTimeRange range) {
    final now = DateTime.now();
    final today = DateTimeRange(start: now, end: now);
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterday = DateTimeRange(start: yesterdayDate, end: yesterdayDate);
    final last7Days = DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
    
    return _isSameDay(range.start, today.start) && _isSameDay(range.end, today.end) ||
           _isSameDay(range.start, yesterday.start) && _isSameDay(range.end, yesterday.end) ||
           _isSameDay(range.start, last7Days.start) && _isSameDay(range.end, last7Days.end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Semua', null),
                _buildFilterChip('Hari Ini', DateTimeRange(
                  start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day), 
                  end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
                )),
                _buildFilterChip('Kemarin', DateTimeRange(
                  start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(const Duration(days: 1)), 
                  end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(const Duration(days: 1))
                )),
                _buildFilterChip('7 Hari', DateTimeRange(
                  start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(const Duration(days: 6)), 
                  end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
                )),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 16, color: Colors.white),
                  label: Text(
                    _selectedDateRange != null && !_isQuickRange(_selectedDateRange!)
                        ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                        : 'Pilih Tanggal',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _selectedDateRange != null && !_isQuickRange(_selectedDateRange!)
                      ? AppColors.primary
                      : Colors.grey[400],
                  onPressed: _selectDateRange,
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Gagal muat data: ${state.message}', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (state is HistoryLoaded) {
            if (state.transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _selectedDateRange == null 
                          ? 'Belum ada transaksi' 
                          : 'Tidak ada transaksi di rentang tanggal ini',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    if (_selectedDateRange != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedDateRange = null);
                          _loadData();
                        },
                        child: const Text('Hapus Filter'),
                      ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDateRange == null ? 'Total Omzet' : 'Omzet Periode Ini',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            currencyFormatter.format(state.totalOmzet),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedDateRange != null)
                            Text(
                              '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                        ],
                      ),
                      const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                    ],
                  ),
                ),
                
                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final trx = state.transactions[index];
                      final date = trx.createdAt;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.receipt_long, color: AppColors.primary),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  trx.transactionNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              if (trx.customerName != null && trx.customerName!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, size: 12, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        trx.customerName!,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(date),
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Kasir: ${trx.cashierName ?? 'System'}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                trx.paymentMethod.toUpperCase(),
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormatter.format(trx.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                                ],
                              ),
                              const SizedBox(width: 8),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, authState) {
                                  bool isOwner = false;
                                  if (authState is AuthAuthenticated) {
                                    isOwner = authState.user.role == 'owner';
                                  }
                                  if (!isOwner) return const SizedBox.shrink();
                                  
                                  return IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _confirmDelete(context, trx.id),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionDetailScreen(transaction: trx),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      bottomNavigationBar: const MainBottomNavBar(activeLabel: 'Riwayat'),
    );
  }
}
