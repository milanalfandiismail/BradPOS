import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_event.dart';
import 'package:bradpos/presentation/blocs/inventory_state.dart';
import 'package:bradpos/presentation/widgets/inventory_item_card.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/presentation/screens/inventory_form_screen.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/settings_modal.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/utils/app_navigator.dart';
import 'package:bradpos/core/widgets/main_navigation_rail.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<InventoryItem> _lastItems = [];
  int _currentPage = 1;
  int _itemsPerPage = 5;
  int _lastItemsPerPage = 0;
  String _selectedCategory = 'All';
  String _stockFilter = 'All';
  bool _isKaryawan = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _searchController.addListener(() {
      _currentPage = 1;
      _loadPage();
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final currentLimit = isLandscape ? 20 : 5;

    if (!_isInit) {
      _itemsPerPage = currentLimit;
      _lastItemsPerPage = currentLimit;
      _loadPage();
      _isInit = true;
    } else if (_lastItemsPerPage != currentLimit) {
      _itemsPerPage = currentLimit;
      _lastItemsPerPage = currentLimit;
      _currentPage = 1;
      _loadPage();
    }
  }

  Future<void> _checkUserRole() async {
    final authRepo = sl<AuthRepository>();
    final result = await authRepo.getCurrentUser();
    final user = result.getOrElse(() => null);
    if (user != null && mounted) setState(() => _isKaryawan = user.isKaryawan);
  }

  void _loadPage() {
    context.read<InventoryBloc>().add(
      LoadInventory(
        page: _currentPage,
        limit: _itemsPerPage,
        searchQuery: _searchController.text.trim(),
        category: _selectedCategory,
        stockStatus: _stockFilter,
      ),
    );
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<InventoryItem> _filteredItems(List<InventoryItem> items) {
    final query = _searchController.text.toLowerCase().trim();
    return items.where((item) {
      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          (item.barcode?.toLowerCase().contains(query) ?? false);
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      bool matchesStock = true;
      if (_stockFilter == 'Low Stock') {
        matchesStock = item.stock > 0 && item.stock <= 10;
      } else if (_stockFilter == 'Out of Stock') {
        matchesStock = item.stock == 0;
      } else if (_stockFilter == 'Unlimited') {
        matchesStock = item.stock == -1;
      }
      return matchesSearch && matchesCategory && matchesStock;
    }).toList();
  }

  void _openForm({InventoryItem? item}) {
    AppNavigator.push(
      context,
      BlocProvider.value(
        value: context.read<InventoryBloc>(),
        child: InventoryFormScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is InventoryLoaded) _lastItems = state.items;
        if (state is InventoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Row(
            children: [
              if (isLandscape)
                const MainNavigationRail(activeLabel: 'INVENTORY'),
              if (isLandscape)
                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, state) => Column(
                    children: [
                      _buildHeader(),
                      _buildSearchBar(),
                      _buildCategoryTabs(state),
                      Expanded(child: _buildContent(state)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: isLandscape
            ? null
            : const MainBottomNavBar(activeLabel: 'INVENTORY'),
        floatingActionButton: null,
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String shopName = 'BradPOS';
        if (state is AuthAuthenticated) {
          shopName = state.user.shopName ?? 'BradPOS';
        }
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        return BradHeader(
          title: 'Inventory',
          subtitle: shopName,
          leadingIcon: Icons.inventory_2_rounded,
          showBottomBorder: true,
          onSettingsTap: () => SettingsModal.show(context),
          actions: isLandscape
              ? [
                  IconButton(
                    onPressed: () {
                      context.read<InventoryBloc>().add(SyncAllEvent());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menyingkronkan data...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.sync_rounded,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                    tooltip: 'Sync',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ]
              : null,
        );
      },
    );
  }

  // ── Search bar (portrait & landscape) ──────────────────────────────────────
  Widget _buildSearchBar() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 22,
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  controller: _searchController,
                  style: const TextStyle(fontSize: 8),
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 8,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.grey,
                      size: 12,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 22,
                    ),
                    filled: true,
                    fillColor: Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 22,
              child: OutlinedButton.icon(
                onPressed: () => _showFilterSheet(),
                icon: const Icon(Icons.tune, size: 10),
                label: const Text('Filter', style: TextStyle(fontSize: 8)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            if (!_isKaryawan) ...[
              const SizedBox(width: 4),
              SizedBox(
                height: 22,
                child: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 10),
                  label: const Text('New', style: TextStyle(fontSize: 8)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF065F46),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Portrait
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  isDense: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _showFilterSheet(),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Filter', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ),
          if (!_isKaryawan) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF065F46),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Category pill tabs ──────────────────────────────────────────────────────
  Widget _buildCategoryTabs(InventoryState state) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    List<String> categories = ['All'];
    if (state is InventoryLoaded) {
      categories.addAll(
        state.categories.map((c) => c.name).where((n) => n != 'Tanpa Kategori'),
      );
    }
    if (!categories.contains('Tanpa Kategori')) {
      categories.add('Tanpa Kategori');
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: isLandscape ? 3 : 10,
        bottom: isLandscape ? 4 : 12,
      ),
      child: SizedBox(
        height: isLandscape ? 26 : 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 4),
          itemBuilder: (context, i) {
            final cat = categories[i];
            final isSel = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              labelStyle: TextStyle(
                fontSize: isLandscape ? 8 : 13,
                fontWeight: FontWeight.bold,
                color: isSel ? Colors.white : const Color(0xFF1E293B),
              ),
              selected: isSel,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                  _currentPage = 1;
                });
                _loadPage();
              },
              selectedColor: const Color(0xFF065F46),
              backgroundColor: Colors.white,
              showCheckmark: false,
              elevation: 0,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: isLandscape
                  ? const VisualDensity(horizontal: -4, vertical: -4)
                  : const VisualDensity(horizontal: -2, vertical: -2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isLandscape ? 6 : 12),
                side: BorderSide(
                  color: isSel
                      ? const Color(0xFF065F46)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(InventoryState state) {
    if (state is InventoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is InventoryError && _lastItems.isEmpty) {
      return Center(child: Text(state.message));
    }
    final itemsToShow = state is InventoryLoaded ? state.items : _lastItems;
    final totalItems = state is InventoryLoaded
        ? state.totalItems
        : _lastItems.length;
    if (itemsToShow.isEmpty && _searchController.text.isEmpty) {
      return _buildEmptyState();
    }
    final displayItems = _filteredItems(itemsToShow);
    if (displayItems.isEmpty) return _buildNoSearchResult();
    int totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<InventoryBloc>().add(SyncAllEvent());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: _buildInventoryList(displayItems),
          ),
        ),
        if (totalPages > 1) _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildInventoryList(List<InventoryItem> items) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      // Landscape: 4 kolom grid, mainAxisExtent cukup besar untuk semua konten card
      return GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          mainAxisExtent: 130,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InventoryItemCard(
            item: item,
            isKaryawan: _isKaryawan,
            isCompact: true,
            onEdit: () => _openForm(item: item),
            onDelete: () => _showDeleteConfirmation(item),
            onAddStock: item.stock == -1
                ? null
                : () => _showAddStockDialog(item),
            onReduceStock: item.stock == -1
                ? null
                : () => _showReduceStockDialog(item),
          );
        },
      );
    }

    // Portrait: ListView
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InventoryItemCard(
            item: item,
            isKaryawan: _isKaryawan,
            onEdit: () => _openForm(item: item),
            onDelete: () => _showDeleteConfirmation(item),
            onAddStock: item.stock == -1
                ? null
                : () => _showAddStockDialog(item),
            onReduceStock: item.stock == -1
                ? null
                : () => _showReduceStockDialog(item),
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 8 : 12,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadPage();
                  }
                : null,
            icon: Icons.chevron_left_rounded,
            isCompact: isLandscape,
          ),
          const SizedBox(width: 12),
          Text(
            '$_currentPage / $totalPages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: isLandscape ? 12 : 14,
            ),
          ),
          const SizedBox(width: 12),
          _buildPageButton(
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadPage();
                  }
                : null,
            icon: Icons.chevron_right_rounded,
            isCompact: isLandscape,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    VoidCallback? onPressed,
    required IconData icon,
    bool isCompact = false,
  }) => Material(
    color: onPressed == null
        ? Colors.grey.shade50
        : AppColors.primary.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
      child: Container(
        width: isCompact ? 32 : 40,
        height: isCompact ? 32 : 40,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: isCompact ? 18 : 22,
          color: onPressed == null ? Colors.grey.shade300 : AppColors.primary,
        ),
      ),
    ),
  );

  Widget _buildEmptyState() => RefreshIndicator(
    onRefresh: () async {
      context.read<InventoryBloc>().add(SyncAllEvent());
      await Future.delayed(const Duration(seconds: 1));
    },
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada produk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tambahkan produk pertama Anda atau tarik untuk sinkron',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildNoSearchResult() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text(
          'Produk tidak ditemukan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Coba gunakan kata kunci lain',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Filter Produk',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  _selectedCategory = 'All';
                                  _stockFilter = 'All';
                                });
                                setState(() {
                                  _selectedCategory = 'All';
                                  _stockFilter = 'All';
                                });
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
                        const SizedBox(height: 24),
                        const _FilterSectionTitle(title: 'Kategori Produk'),
                        const SizedBox(height: 12),
                        BlocBuilder<InventoryBloc, InventoryState>(
                          builder: (context, state) {
                            List<String> categories = ['All', 'Tanpa Kategori'];
                            if (state is InventoryLoaded) {
                              categories.addAll(
                                state.categories
                                    .map((c) => c.name)
                                    .where((name) => name != 'Tanpa Kategori'),
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories.map((c) {
                                final isSel = _selectedCategory == c;
                                return _CustomFilterChip(
                                  label: c,
                                  isSelected: isSel,
                                  onSelected: (val) {
                                    setSheetState(() => _selectedCategory = c);
                                    setState(() => _selectedCategory = c);
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const _FilterSectionTitle(title: 'Status Stok'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              [
                                'All',
                                'Low Stock',
                                'Out of Stock',
                                'Unlimited',
                              ].map((s) {
                                final isSel = _stockFilter == s;
                                return _CustomFilterChip(
                                  label: s,
                                  isSelected: isSel,
                                  onSelected: (val) {
                                    setSheetState(() => _stockFilter = s);
                                    setState(() => _stockFilter = s);
                                  },
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              _currentPage = 1;
                              _loadPage();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Terapkan Filter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(InventoryItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<InventoryBloc>().add(
                DeleteInventoryItemEvent(item.id),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddStockDialog(InventoryItem item) {
    final stockController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Tambah Stok - ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stok saat ini: ${item.stock} ${item.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah stok ditambahkan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(stockController.text);
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Masukkan jumlah yang valid')),
                );
                return;
              }
              final updatedItem = item.copyWith(
                stock: item.stock + qty,
                updatedAt: DateTime.now(),
              );
              context.read<InventoryBloc>().add(
                UpdateInventoryItemEvent(updatedItem),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showReduceStockDialog(InventoryItem item) {
    final stockController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Kurangi Stok - ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stok saat ini: ${item.stock} ${item.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah stok dikurangi',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(stockController.text);
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Masukkan jumlah yang valid')),
                );
                return;
              }
              if (qty > item.stock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stok tidak mencukupi')),
                );
                return;
              }
              final updatedItem = item.copyWith(
                stock: item.stock - qty,
                updatedAt: DateTime.now(),
              );
              context.read<InventoryBloc>().add(
                UpdateInventoryItemEvent(updatedItem),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  final String title;
  const _FilterSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: Color(0xFF475569),
      ),
    );
  }
}

class _CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _CustomFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF065F46),
      backgroundColor: Colors.white,
      showCheckmark: false,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF065F46) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
