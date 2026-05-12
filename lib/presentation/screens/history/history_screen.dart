import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/history/history_bloc.dart';
import 'package:bradpos/presentation/blocs/history/history_event.dart';
import 'package:bradpos/presentation/blocs/history/history_state.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/screens/report/transaction_detail_screen.dart';
import 'package:bradpos/presentation/screens/history/history_transaction_card.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/settings_modal.dart';
import 'package:bradpos/presentation/blocs/karyawan_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_event.dart';
import 'package:bradpos/presentation/blocs/karyawan_state.dart';
import 'package:bradpos/core/widgets/main_navigation_rail.dart';

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
  final TextEditingController _searchController = TextEditingController();
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
                    child: _buildFilterContent(setSheetState, onApply: () {
                      _loadData();
                      Navigator.pop(context);
                    }),
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
              return _buildFilterContent(setSheetState, onApply: () {
                _loadData();
                Navigator.pop(context);
              }, isCompact: true);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterContent(
    StateSetter setSheetState, {
    VoidCallback? onApply,
    bool isCompact = false,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transaksi',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  if (isCompact)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {});
                      setState(() {
                        _selectedDateRange = null;
                        _selectedCashierId = null;
                      });
                      _searchController.clear();
                      _searchQuery = '';
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 24),
          Text(
            'Rentang Waktu',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 12 : 15,
              color: const Color(0xFF475569),
            ),
          ),
          SizedBox(height: isCompact ? 8 : 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildFilterChip(
                'Semua',
                null,
                isCompact: isCompact,
                overrideSelected: _selectedDateRange == null,
                onTap: () {
                  setSheetState(() {});
                  setState(() => _selectedDateRange = null);
                  _loadData();
                },
              ),
              _buildFilterChip(
                'Hari Ini',
                DateTimeRange(
                  start: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                  end: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                ),
                isCompact: isCompact,
                overrideSelected: _selectedDateRange != null &&
                    _isSameDay(_selectedDateRange!.start, DateTime.now()),
                onTap: () {
                  setSheetState(() {});
                  setState(
                    () => _selectedDateRange = DateTimeRange(
                      start: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ),
                      end: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ),
                    ),
                  );
                  _loadData();
                },
              ),
              _buildFilterChip(
                'Kemarin',
                DateTimeRange(
                  start: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ).subtract(const Duration(days: 1)),
                  end: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ).subtract(const Duration(days: 1)),
                ),
                isCompact: isCompact,
                overrideSelected: _selectedDateRange != null &&
                    _isSameDay(
                      _selectedDateRange!.start,
                      DateTime.now().subtract(const Duration(days: 1)),
                    ),
                onTap: () {
                  setSheetState(() {});
                  setState(
                    () => _selectedDateRange = DateTimeRange(
                      start: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ).subtract(const Duration(days: 1)),
                      end: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ).subtract(const Duration(days: 1)),
                    ),
                  );
                  _loadData();
                },
              ),
              _buildFilterChip(
                '7 Hari',
                DateTimeRange(
                  start: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ).subtract(const Duration(days: 6)),
                  end: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                ),
                isCompact: isCompact,
                overrideSelected: _selectedDateRange != null &&
                    _isSameDay(
                      _selectedDateRange!.start,
                      DateTime.now().subtract(const Duration(days: 6)),
                    ),
                onTap: () {
                  setSheetState(() {});
                  setState(
                    () => _selectedDateRange = DateTimeRange(
                      start: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ).subtract(const Duration(days: 6)),
                      end: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ),
                    ),
                  );
                  _loadData();
                },
              ),
              _buildFilterChip(
                _selectedDateRange != null &&
                        !_isQuickRange(_selectedDateRange!)
                    ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                    : 'Pilih Tanggal',
                null,
                isCompact: isCompact,
                isDatePicker: true,
                overrideSelected: false,
                onTap: () async {
                  final picked = await showDateRangePicker(
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
                  if (picked != null) {
                    setSheetState(() {});
                    setState(() => _selectedDateRange = picked);
                    _loadData();
                  }
                },
              ),
            ],
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (ctx, authState) {
              final bool isOwner = authState is AuthAuthenticated &&
                  authState.user.role == 'owner';
              if (!isOwner) return const SizedBox.shrink();

              return BlocBuilder<KaryawanBloc, KaryawanState>(
                builder: (ctx, state) {
                  if (state is! KaryawanListLoaded) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isCompact ? 12 : 24),
                      Text(
                        'Kasir',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 12 : 15,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildFilterChip(
                            'Semua Kasir',
                            null,
                            isCompact: isCompact,
                            isCashier: true,
                            cashierId: null,
                            overrideSelected: _selectedCashierId == null,
                            onTap: () {
                              setSheetState(() {});
                              setState(() => _selectedCashierId = null);
                              _loadData();
                            },
                          ),
                          ...state.karyawanList.map((k) {
                            return _buildFilterChip(
                              k.name,
                              null,
                              isCompact: isCompact,
                              isCashier: true,
                              cashierId: k.id,
                              overrideSelected: _selectedCashierId == k.id,
                              onTap: () {
                                setSheetState(() {});
                                setState(() => _selectedCashierId = k.id);
                                _loadData();
                              },
                            );
                          }),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
          SizedBox(height: isCompact ? 16 : 32),
          SizedBox(
            width: double.infinity,
            height: isCompact ? 40 : 56,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 10 : 16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Terapkan Filter',
                style: TextStyle(
                  fontSize: isCompact ? 13 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    DateTimeRange? range, {
    bool isCompact = false,
    bool isDatePicker = false,
    bool isCashier = false,
    String? cashierId,
    bool? overrideSelected,
    VoidCallback? onTap,
  }) {
    final bool isSelected = overrideSelected ??
        (isCashier
            ? _selectedCashierId == cashierId
            : isDatePicker
                ? _selectedDateRange != null &&
                    !_isQuickRange(_selectedDateRange!)
                : (_selectedDateRange == null && range == null) ||
                    (_selectedDateRange != null &&
                        range != null &&
                        _isSameDay(_selectedDateRange!.start, range.start) &&
                        _isSameDay(_selectedDateRange!.end, range.end)));

    return Padding(
      padding: EdgeInsets.only(right: isCompact ? 4 : 8),
      child: ChoiceChip(
        showCheckmark: false,
        avatar: isDatePicker
            ? Icon(
                Icons.date_range,
                size: isCompact ? 11 : 14,
                color: isSelected ? Colors.white : const Color(0xFF065F46),
              )
            : null,
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1E293B),
            fontSize: isCompact ? 8 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        labelPadding: EdgeInsets.zero,
        selected: isSelected,
        selectedColor: const Color(0xFF065F46),
        backgroundColor: Colors.white,
        visualDensity: isCompact
            ? const VisualDensity(horizontal: -4, vertical: -4)
            : null,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 10,
          vertical: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 6 : 12),
          side: BorderSide(
            color: isSelected ? Colors.transparent : const Color(0xFFCBD5E1),
          ),
        ),
        elevation: 0,
        onSelected: onTap != null
            ? (_) => onTap()
            : isDatePicker
                ? (_) => _selectDateRange()
                : isCashier
                    ? (selected) {
                        if (selected) {
                          setState(() => _selectedCashierId = cashierId);
                          _loadData();
                        }
                      }
                    : (selected) {
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
    final today = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterday = DateTimeRange(
      start: DateTime(
        yesterdayDate.year,
        yesterdayDate.month,
        yesterdayDate.day,
      ),
      end: DateTime(yesterdayDate.year, yesterdayDate.month, yesterdayDate.day),
    );
    final last7Days = DateTimeRange(
      start: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6)),
      end: DateTime(now.year, now.month, now.day),
    );

    return _isSameDay(range.start, today.start) &&
            _isSameDay(range.end, today.end) ||
        _isSameDay(range.start, yesterday.start) &&
            _isSameDay(range.end, yesterday.end) ||
        _isSameDay(range.start, last7Days.start) &&
            _isSameDay(range.end, last7Days.end);
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isLandscape,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isLandscape ? 6 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isLandscape ? 8 : 16),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isLandscape ? 3 : 8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isLandscape ? 4 : 8),
              ),
              child: Icon(icon, color: iconColor, size: isLandscape ? 12 : 20),
            ),
            SizedBox(height: isLandscape ? 3 : 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isLandscape ? 7 : 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isLandscape ? 1 : 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isLandscape ? 12 : 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages, bool isLandscape) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 4 : 8,
        horizontal: isLandscape ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            iconSize: isLandscape ? 16 : 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            'Halaman ${_currentPage + 1} dari $totalPages',
            style: TextStyle(fontSize: isLandscape ? 11 : 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            iconSize: isLandscape ? 16 : 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
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
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _buildHeaderSection(isLandscape),
                    ),
                    BlocBuilder<HistoryBloc, HistoryState>(
                      builder: (context, state) {
                        if (state is HistoryLoaded && state.transactions.isNotEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLandscape ? 8 : 16,
                                vertical: isLandscape ? 4 : 8,
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    _buildMiniStatCard(
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
                                    _buildMiniStatCard(
                                      icon: Icons.receipt_long,
                                      iconColor: const Color(0xFF10B981),
                                      title: 'Total Transaksi',
                                      value: '${state.transactions.length}',
                                      isLandscape: isLandscape,
                                    ),
                                    SizedBox(width: isLandscape ? 6 : 12),
                                    _buildMiniStatCard(
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
                        return const SliverToBoxAdapter(child: SizedBox.shrink());
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
                                    ? GridView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(8),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          mainAxisExtent: 130,
                                          crossAxisSpacing: 4,
                                          mainAxisSpacing: 4,
                                        ),
                                        itemCount: displayed.length,
                                        itemBuilder: (context, index) {
                                          final trx = displayed[index];
                                          return HistoryTransactionCard(
                                            transaction: trx,
                                            isLandscape: isLandscape,
                                            currencyFormatter: currencyFormatter,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => TransactionDetailScreen(transaction: trx),
                                              ),
                                            ),
                                            onDelete: (ctx) => _confirmDelete(ctx, trx.id),
                                          );
                                        },
                                      )
                                    : ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        children: displayed
                                            .map(
                                              (trx) => HistoryTransactionCard(
                                                transaction: trx,
                                                isLandscape: isLandscape,
                                                currencyFormatter: currencyFormatter,
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => TransactionDetailScreen(transaction: trx),
                                                  ),
                                                ),
                                                onDelete: (ctx) => _confirmDelete(ctx, trx.id),
                                              ),
                                            )
                                            .toList(),
                                      ),
                          ),
                          if (filtered.isNotEmpty && totalPages > 1)
                            _buildPagination(totalPages, isLandscape),
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

  Widget _buildHeaderSection(bool isLandscape) {
    return Column(
      children: [
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => BradHeader(
            title: 'Riwayat Transaksi',
            subtitle: state.displayShopName,
              leadingIcon: Icons.history_rounded,
              showBottomBorder: true,
              showSettings: !isLandscape,
              onSettingsTap: () => SettingsModal.show(context),
              onSyncTap: () {
                context.read<AuthBloc>().syncService.syncAll();
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menyingkronkan data...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              actions: isLandscape
                  ? [
                      IconButton(
                        icon: const Icon(
                          Icons.sync_rounded,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                        onPressed: _loadData,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ]
                  : null,
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: isLandscape
                    ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
                    : const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: isLandscape ? 48 : 56,
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          controller: _searchController,
                          style: TextStyle(
                            fontSize: isLandscape ? 14 : 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari nomor transaksi...',
                            hintStyle: TextStyle(
                              fontSize: isLandscape ? 14 : 14,
                              color: Colors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.grey,
                              size: isLandscape ? 20 : 20,
                            ),
                            prefixIconConstraints: isLandscape
                                ? const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 48,
                                  )
                                : null,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: isLandscape ? 12 : 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(
                                        () => _searchQuery = '',
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isLandscape ? 12 : 16,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isLandscape ? 12 : 16,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isLandscape ? 12 : 16,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            isDense: isLandscape,
                            contentPadding: isLandscape
                                ? const EdgeInsets.symmetric(horizontal: 12)
                                : const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _searchQuery = v;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: isLandscape ? 6 : 8),
                    if (isLandscape)
                      SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: _showFilterModal,
                          icon: const Icon(Icons.tune, size: 18),
                          label: const Text('Filter',
                              style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.white,
                            visualDensity: VisualDensity.comfortable,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 56,
                        child: Material(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _showFilterModal,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune,
                                    color: Color(0xFF64748B),
                                    size: 24,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Filter',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
