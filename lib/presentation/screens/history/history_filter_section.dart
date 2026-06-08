import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_state.dart';

class HistoryFilterContent extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final String? selectedCashierId;
  final bool isCompact;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final StateSetter setSheetState;
  final Future<void> Function() onSelectDateRange;
  final void Function(DateTimeRange?) onDateRangeChanged;
  final void Function(String?) onCashierChanged;
  final void Function() onLoadData;

  const HistoryFilterContent({
    super.key,
    required this.selectedDateRange,
    required this.selectedCashierId,
    this.isCompact = false,
    required this.onApply,
    required this.onReset,
    required this.setSheetState,
    required this.onSelectDateRange,
    required this.onDateRangeChanged,
    required this.onCashierChanged,
    required this.onLoadData,
  });

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF64748B)),
                    ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {});
                      onReset();
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
                overrideSelected: selectedDateRange == null,
                onTap: () {
                  setSheetState(() {});
                  onDateRangeChanged(null);
                  onLoadData();
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
                overrideSelected: selectedDateRange != null &&
                    _isSameDay(selectedDateRange!.start, DateTime.now()),
                onTap: () {
                  setSheetState(() {});
                  onDateRangeChanged(DateTimeRange(
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
                  ));
                  onLoadData();
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
                overrideSelected: selectedDateRange != null &&
                    _isSameDay(
                      selectedDateRange!.start,
                      DateTime.now().subtract(const Duration(days: 1)),
                    ),
                onTap: () {
                  setSheetState(() {});
                  onDateRangeChanged(DateTimeRange(
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
                  ));
                  onLoadData();
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
                overrideSelected: selectedDateRange != null &&
                    _isSameDay(
                      selectedDateRange!.start,
                      DateTime.now().subtract(const Duration(days: 6)),
                    ),
                onTap: () {
                  setSheetState(() {});
                  onDateRangeChanged(DateTimeRange(
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
                  ));
                  onLoadData();
                },
              ),
              _buildFilterChip(
                selectedDateRange != null &&
                        !_isQuickRange(selectedDateRange!)
                    ? '${DateFormat('dd/MM').format(selectedDateRange!.start)} - ${DateFormat('dd/MM').format(selectedDateRange!.end)}'
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
                    initialDateRange: selectedDateRange,
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
                    onDateRangeChanged(picked);
                    onLoadData();
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
                            overrideSelected: selectedCashierId == null,
                            onTap: () {
                              setSheetState(() {});
                              onCashierChanged(null);
                              onLoadData();
                            },
                          ),
                          ...state.karyawanList.map((k) {
                            return _buildFilterChip(
                              k.name,
                              null,
                              isCompact: isCompact,
                              isCashier: true,
                              cashierId: k.id,
                              overrideSelected: selectedCashierId == k.id,
                              onTap: () {
                                setSheetState(() {});
                                onCashierChanged(k.id);
                                onLoadData();
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
            ? selectedCashierId == cashierId
            : isDatePicker
                ? selectedDateRange != null &&
                    !_isQuickRange(selectedDateRange!)
                : (selectedDateRange == null && range == null) ||
                    (selectedDateRange != null &&
                        range != null &&
                        _isSameDay(selectedDateRange!.start, range.start) &&
                        _isSameDay(selectedDateRange!.end, range.end)));

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
                ? (_) => onSelectDateRange()
                : isCashier
                    ? (selected) {
                        if (selected) {
                          onCashierChanged(cashierId);
                        }
                      }
                    : (selected) {
                        if (selected) {
                          onDateRangeChanged(range);
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
      end:
          DateTime(yesterdayDate.year, yesterdayDate.month, yesterdayDate.day),
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
}
