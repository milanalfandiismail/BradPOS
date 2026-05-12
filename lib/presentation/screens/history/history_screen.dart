import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/history/history_bloc.dart';
import 'package:bradpos/presentation/blocs/history/history_event.dart';
import 'package:bradpos/presentation/blocs/history/history_state.dart';
import 'package:bradpos/presentation/screens/report/transaction_detail_screen.dart';
import 'package:bradpos/presentation/screens/history/history_transaction_card.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';
import 'package:bradpos/presentation/blocs/karyawan_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_event.dart';
import 'package:bradpos/core/widgets/main_navigation_rail.dart';
import 'package:bradpos/presentation/screens/history/history_header_section.dart';
import 'package:bradpos/presentation/screens/history/history_filter_section.dart';
import 'package:bradpos/presentation/screens/history/history_mini_stat_card.dart';
import 'package:bradpos/presentation/screens/history/history_pagination_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  DateTimeRange? _selectedDateRange;
  String? _selectedCashierId;
  int _currentPage = 0;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    context.read<KaryawanBloc>().add(LoadKaryawanList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadData() {
    _currentPage = 0;
    if (_selectedDateRange != null) {
      final start = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
        0,
        0,
        0,
      );
      final end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23,
        59,
        59,
      );
      context.read<HistoryBloc>().add(
        LoadHistoryByRangeEvent(start, end, cashierId: _selectedCashierId),
      );
    } else {
      context.read<HistoryBloc>().add(
        LoadHistoryEvent(cashierId: _selectedCashierId),
      );
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
        content: const Text(
          'Data transaksi ini akan dihapus permanen. Stok tidak akan dikembalikan.',
        ),
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

  void _showFilterModal() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      _showFilterSidePanel();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Flexible(
                    child: HistoryFilterContent(
                      selectedDateRange: _selectedDateRange,
                      selectedCashierId: _selectedCashierId,
                      setSheetState: setSheetState,
                      onApply: () {
                        _loadData();
                        Navigator.pop(context);
                      },
                      onReset: () {
                        setState(() {
                          _selectedDateRange = null;
                          _selectedCashierId = null;
                        });
                        _searchController.clear();
                        _searchQuery = '';
                      },
                      onSelectDateRange: _selectDateRange,
                      onDateRangeChanged: (range) {
                        setState(() => _selectedDateRange = range);
                      },
                      onCashierChanged: (id) {
                        setState(() => _selectedCashierId = id);
                      },
                      onLoadData: _loadData,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSidePanel() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: SizedBox(
          width: 400, // Fixed width for dialog in landscape
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return HistoryFilterContent(
                selectedDateRange: _selectedDateRange,
                selectedCashierId: _selectedCashierId,
                isCompact: true,
                setSheetState: setSheetState,
                onApply: () {
                  _loadData();
                  Navigator.pop(context);
                },
                onReset: () {
                  setState(() {
                    _selectedDateRange = null;
                    _selectedCashierId = null;
                  });
                  _searchController.clear();
                  _searchQuery = '';
                },
                onSelectDateRange: _selectDateRange,
                onDateRangeChanged: (range) {
                  setState(() => _selectedDateRange = range);
                },
                onCashierChanged: (id) {
                  setState(() => _selectedCashierId = id);
                },
                onLoadData: _loadData,
              );
            },
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Row(
          children: [
            if (isLandscape) const MainNavigationRail(activeLabel: 'HISTORY'),
            if (isLandscape)
              const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: HistoryHeaderSection(
                        searchController: _searchController,
                        searchQuery: _searchQuery,
                        isLandscape: isLandscape,
                        onFilterTap: _showFilterModal,
                        onSyncTap: _loadData,
                        onSearchChanged: (v) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              setState(() {
                                _searchQuery = v;
                                _currentPage = 0;
                              });
                              _loadData();
                            }
                          });
                        },
                        onClearSearch: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),
                    BlocBuilder<HistoryBloc, HistoryState>(
                      builder: (context, state) {
                        if (state is HistoryLoaded &&
                            state.transactions.isNotEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLandscape ? 8 : 16,
                                vertical: isLandscape ? 4 : 8,
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    HistoryMiniStatCard(
                                      icon: Icons.account_balance_wallet,
                                      iconColor: const Color(0xFF1A73E8),
                                      title: _selectedDateRange == null
                                          ? 'Total Omzet'
                                          : 'Omzet',
                                      value: currencyFormatter.format(
                                        state.totalOmzet,
                                      ),
                                      isLandscape: isLandscape,
                                    ),
                                    SizedBox(width: isLandscape ? 6 : 12),
                                    HistoryMiniStatCard(
                                      icon: Icons.receipt_long,
                                      iconColor: const Color(0xFF10B981),
                                      title: 'Total Transaksi',
                                      value: '${state.transactions.length}',
                                      isLandscape: isLandscape,
                                    ),
                                    SizedBox(width: isLandscape ? 6 : 12),
                                    HistoryMiniStatCard(
                                      icon: Icons.trending_up,
                                      iconColor: const Color(0xFF8B5CF6),
                                      title: 'Rata-rata',
                                      value: currencyFormatter.format(
                                        state.transactions.isEmpty
                                            ? 0
                                            : state.totalOmzet ~/
                                                state.transactions.length,
                                      ),
                                      isLandscape: isLandscape,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        );
                      },
                    ),
                  ];
                },
                body: BlocBuilder<HistoryBloc, HistoryState>(
                  builder: (context, state) {
                    if (state is HistoryLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is HistoryError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal muat data: ${state.message}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text(
                                'Coba Lagi',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is HistoryLoaded) {
                      final filtered = _searchQuery.isEmpty
                          ? state.transactions
                          : state.transactions
                              .where(
                                (t) => t.transactionNumber
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()),
                              )
                              .toList();
                      final itemsPerPage = isLandscape ? 20 : 10;
                      final totalPages = filtered.isEmpty
                          ? 1
                          : (filtered.length + itemsPerPage - 1) ~/
                              itemsPerPage;
                      final startIndex = (_currentPage * itemsPerPage)
                          .clamp(0, filtered.length);
                      final endIndex = (startIndex + itemsPerPage).clamp(
                        0,
                        filtered.length,
                      );
                      final displayed = filtered.sublist(
                        startIndex,
                        endIndex,
                      );

                      return Column(
                        children: [
                          Expanded(
                            child: filtered.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height: MediaQuery.of(context)
                                                .size
                                                .height *
                                            0.2,
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.receipt_long_outlined,
                                              size: isLandscape ? 48 : 80,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _searchQuery.isNotEmpty
                                                  ? 'Tidak ada hasil untuk "$_searchQuery"'
                                                  : _selectedDateRange == null
                                                      ? 'Belum ada transaksi'
                                                      : 'Tidak ada transaksi di rentang tanggal ini',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: isLandscape ? 12 : 16,
                                              ),
                                            ),
                                            if (_selectedDateRange != null)
                                              TextButton(
                                                onPressed: () {
                                                  setState(
                                                    () => _selectedDateRange =
                                                        null,
                                                  );
                                                  _loadData();
                                                },
                                                child: const Text(
                                                  'Hapus Filter',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : isLandscape
                                    ? CustomScrollView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        slivers: [
                                          SliverPadding(
                                            padding: const EdgeInsets.all(8),
                                            sliver: SliverGrid(
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 4,
                                                mainAxisExtent: 130,
                                                crossAxisSpacing: 4,
                                                mainAxisSpacing: 4,
                                              ),
                                              delegate:
                                                  SliverChildBuilderDelegate(
                                                (context, index) {
                                                  final trx = displayed[index];
                                                  return HistoryTransactionCard(
                                                    transaction: trx,
                                                    isLandscape: isLandscape,
                                                    currencyFormatter:
                                                        currencyFormatter,
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            TransactionDetailScreen(
                                                          transaction: trx,
                                                        ),
                                                      ),
                                                    ),
                                                    onDelete: (ctx) =>
                                                        _confirmDelete(
                                                            ctx, trx.id),
                                                  );
                                                },
                                                childCount: displayed.length,
                                              ),
                                            ),
                                          ),
                                          if (filtered.isNotEmpty &&
                                              totalPages > 1)
                                            SliverToBoxAdapter(
                                              child: HistoryPaginationBar(
                                                currentPage: _currentPage,
                                                totalPages: totalPages,
                                                isLandscape: isLandscape,
                                                onPrevious: _currentPage > 0
                                                    ? () {
                                                        setState(() =>
                                                            _currentPage--);
                                                        _scrollController
                                                            .animateTo(
                                                          0,
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      300),
                                                          curve: Curves.easeOut,
                                                        );
                                                      }
                                                    : null,
                                                onNext: _currentPage <
                                                        totalPages - 1
                                                    ? () {
                                                        setState(() =>
                                                            _currentPage++);
                                                        _scrollController
                                                            .animateTo(
                                                          0,
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      300),
                                                          curve: Curves.easeOut,
                                                        );
                                                      }
                                                    : null,
                                              ),
                                            ),
                                          const SliverPadding(
                                              padding:
                                                  EdgeInsets.only(bottom: 20)),
                                        ],
                                      )
                                    : ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        children: [
                                          ...displayed.map(
                                            (trx) => HistoryTransactionCard(
                                              transaction: trx,
                                              isLandscape: isLandscape,
                                              currencyFormatter:
                                                  currencyFormatter,
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      TransactionDetailScreen(
                                                    transaction: trx,
                                                  ),
                                                ),
                                              ),
                                              onDelete: (ctx) =>
                                                  _confirmDelete(ctx, trx.id),
                                            ),
                                          ),
                                          if (filtered.isNotEmpty &&
                                              totalPages > 1)
                                            HistoryPaginationBar(
                                              currentPage: _currentPage,
                                              totalPages: totalPages,
                                              isLandscape: isLandscape,
                                              onPrevious: _currentPage > 0
                                                  ? () {
                                                      setState(() =>
                                                          _currentPage--);
                                                      _scrollController
                                                          .animateTo(
                                                        0,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    300),
                                                        curve: Curves.easeOut,
                                                      );
                                                    }
                                                  : null,
                                              onNext: _currentPage <
                                                      totalPages - 1
                                                  ? () {
                                                      setState(() =>
                                                          _currentPage++);
                                                      _scrollController
                                                          .animateTo(
                                                        0,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    300),
                                                        curve: Curves.easeOut,
                                                      );
                                                    }
                                                  : null,
                                            ),
                                          const Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 20)),
                                        ],
                                      ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isLandscape
          ? null
          : const MainBottomNavBar(activeLabel: 'HISTORY'),
    );
  }
}
