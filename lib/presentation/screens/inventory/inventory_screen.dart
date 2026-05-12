import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_event.dart';
import 'package:bradpos/presentation/blocs/inventory_state.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_item_card.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_form_screen.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/settings_modal.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/utils/app_navigator.dart';
import 'package:bradpos/core/widgets/main_navigation_rail.dart';
import 'package:bradpos/presentation/screens/category/category_screen.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_pagination_bar.dart';

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

  Future<void> _openForm({InventoryItem? item}) async {
    final inventoryBloc = context.read<InventoryBloc>();
    await AppNavigator.push(
      context,
      BlocProvider.value(
        value: inventoryBloc,
        child: InventoryFormScreen(item: item),
      ),
    );
    inventoryBloc.add(const LoadInventoryCategoriesEvent());
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
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Row(
            children: [
              if (isLandscape)
                const MainNavigationRail(activeLabel: 'INVENTORY'),
              if (isLandscape)
                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: _buildHeaderSection(isLandscape),
                      ),
                    ];
                  },
                  body: BlocBuilder<InventoryBloc, InventoryState>(
                    builder: (context, state) => _buildContent(state),
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

  Widget _buildHeaderSection(bool isLandscape) {
    return Column(
      children: [
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => BradHeader(
            title: 'Produk | Inventory',
            subtitle: state.displayShopName,
              leadingIcon: Icons.inventory_2_rounded,
              showBottomBorder: true,
              showSettings: !isLandscape,
              onSettingsTap: () => SettingsModal.show(context),
              onSyncTap: () {
                context.read<InventoryBloc>().add(SyncAllEvent());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menyingkronkan data...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              actions: [
                IconButton(
                  onPressed: () async {
                    final inventoryBloc = context.read<InventoryBloc>();
                    await AppNavigator.push(context, const CategoryScreen());
                    inventoryBloc.add(const LoadInventoryCategoriesEvent());
                  },
                  icon: Icon(
                    Icons.category_rounded,
                    color: const Color(0xFF64748B),
                    size: isLandscape ? 18 : 24,
                  ),
                  tooltip: 'Kategori',
                  padding: isLandscape ? EdgeInsets.zero : null,
                  constraints: isLandscape
                      ? const BoxConstraints(minWidth: 32, minHeight: 32)
                      : null,
                ),
                if (isLandscape)
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
              ],
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
              _buildSearchBarAndActions(isLandscape),
              if (!isLandscape) ...[
                const SizedBox(height: 12),
                _buildFilterActions(),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }

  // ── Search bar (portrait & landscape) ──────────────────────────────────────
  Widget _buildSearchBarAndActions(bool isLandscape) {
    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
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
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 48,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _showFilterSheet(),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Filter', style: TextStyle(fontSize: 13)),
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
            ),
            if (!_isKaryawan) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Tambah',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF065F46),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    visualDensity: VisualDensity.comfortable,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
    );
  }

  // ── Filter + New buttons row (portrait only) ───────────────────────────────
  Widget _buildFilterActions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
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
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Tambah Produk',
                    style: TextStyle(fontSize: 13),
                  ),
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
            ),
          ],
        ],
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

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        _buildInventorySliver(displayItems),
        if (totalPages > 1)
          SliverToBoxAdapter(
            child: InventoryPaginationBar(
  currentPage: _currentPage,
  totalPages: totalPages,
  onPrevious: _currentPage > 1
      ? () {
          setState(() => _currentPage--);
          _loadPage();
        }
      : null,
  onNext: _currentPage < totalPages
      ? () {
          setState(() => _currentPage++);
          _loadPage();
        }
      : null,
),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildInventorySliver(List<InventoryItem> items) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            mainAxisExtent: 160,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
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
            childCount: items.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
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
          childCount: items.length,
        ),
      ),
    );
  }


  Widget _buildEmptyState() => ListView(
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
              'Tambahkan produk pertama Anda',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ],
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

  List<String> _getFilterCategories() {
    final inventoryState = context.read<InventoryBloc>().state;
    final cats = ['All', 'Tanpa Kategori'];
    if (inventoryState is InventoryLoaded) {
      cats.addAll(
        inventoryState.categories
            .map((c) => c.name)
            .where((name) => name != 'Tanpa Kategori'),
      );
    }
    return cats;
  }

  void _showFilterSheet() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      _showFilterSidePanel();
      return;
    }

    final modalCategories = _getFilterCategories();

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
                      _currentPage = 1;
                      _loadPage();
                      Navigator.pop(context);
                    }, categories: modalCategories),
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
    final modalCategories = _getFilterCategories();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return _buildFilterContent(setSheetState, onApply: () {
              _currentPage = 1;
              _loadPage();
              Navigator.pop(context);
            }, isCompact: true, categories: modalCategories);
          },
        ),
      ),
    );
  }

  Widget _buildFilterContent(
    StateSetter setSheetState, {
    VoidCallback? onApply,
    bool isCompact = false,
    List<String>? categories,
  }) {
    final cats = categories ??
        ['All', 'Tanpa Kategori', 'Makanan', 'Minuman'];
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Produk',
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
            ],
          ),
          SizedBox(height: isCompact ? 12 : 24),
          _FilterSectionTitle(
            title: 'Kategori Produk',
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 8 : 12),
          Wrap(
              spacing: isCompact ? 6 : 8,
              runSpacing: isCompact ? 6 : 8,
              children: cats.map((c) {
                final isSel = _selectedCategory == c;
                return _CustomFilterChip(
                  label: c,
                  isSelected: isSel,
                  isCompact: isCompact,
                  onSelected: (val) {
                    setSheetState(() => _selectedCategory = c);
                    _selectedCategory = c;
                    _currentPage = 1;
                    _loadPage();
                  },
                );
              }).toList(),
            ),
          SizedBox(height: isCompact ? 12 : 24),
          _FilterSectionTitle(
            title: 'Status Stok',
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 8 : 12),
          Wrap(
            spacing: isCompact ? 6 : 8,
            runSpacing: isCompact ? 6 : 8,
            children: ['All', 'Low Stock', 'Out of Stock', 'Unlimited'].map((
              s,
            ) {
              final isSel = _stockFilter == s;
              return _CustomFilterChip(
                label: s,
                isSelected: isSel,
                isCompact: isCompact,
                onSelected: (val) {
                  setSheetState(() => _stockFilter = s);
                  _stockFilter = s;
                  _currentPage = 1;
                  _loadPage();
                },
              );
            }).toList(),
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
      builder: (dialogContext) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            constraints: BoxConstraints(maxWidth: isLandscape ? 380 : 400),
            padding: EdgeInsets.fromLTRB(20, isLandscape ? 6 : 20, 20, isLandscape ? 6 : 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLandscape)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tambah Stok',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900)),
                              Text(item.name,
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis),
                              Text('Stok: ${item.stock} ${item.unit}',
                                  style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: stockController,
                                  keyboardType: TextInputType.number,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: const InputDecoration(
                                    labelText: 'Qty',
                                    labelStyle: TextStyle(fontSize: 10),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.redAccent, size: 18),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final qty =
                                      int.tryParse(stockController.text);
                                  if (qty == null || qty <= 0) return;
                                  final updatedItem = item.copyWith(
                                      stock: item.stock + qty,
                                      updatedAt: DateTime.now());
                                  context.read<InventoryBloc>().add(
                                      UpdateInventoryItemEvent(updatedItem));
                                  Navigator.pop(dialogContext);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('OK',
                                    style: TextStyle(fontSize: 10)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tambah Stok',
                                  style: TextStyle(
                                      fontSize: isLandscape ? 14 : 18,
                                      fontWeight: FontWeight.w900)),
                              Text(item.name,
                                  style: TextStyle(
                                      fontSize: isLandscape ? 11 : 13,
                                      color: Colors.grey),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isLandscape ? 8 : 12),
                    Text('Stok saat ini: ${item.stock} ${item.unit}',
                        style: TextStyle(fontSize: isLandscape ? 11 : 13)),
                    SizedBox(height: isLandscape ? 8 : 12),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: TextStyle(fontSize: isLandscape ? 12 : 14),
                      decoration: InputDecoration(
                        labelText: 'Jumlah ditambahkan',
                        labelStyle: TextStyle(fontSize: isLandscape ? 11 : 13),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 12 : 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text('Batal',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: isLandscape ? 11 : 13)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final qty = int.tryParse(stockController.text);
                            if (qty == null || qty <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Masukkan jumlah yang valid')));
                              return;
                            }
                            final updatedItem = item.copyWith(
                                stock: item.stock + qty,
                                updatedAt: DateTime.now());
                            context
                                .read<InventoryBloc>()
                                .add(UpdateInventoryItemEvent(updatedItem));
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                                horizontal: isLandscape ? 16 : 24,
                                vertical: isLandscape ? 8 : 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Simpan',
                              style:
                                  TextStyle(fontSize: isLandscape ? 11 : 13)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReduceStockDialog(InventoryItem item) {
    final stockController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isLandscape ? 12 : 20)),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(isLandscape ? 12 : 20)),
            constraints: BoxConstraints(maxWidth: isLandscape ? 380 : 400),
            padding: EdgeInsets.fromLTRB(isLandscape ? 12 : 24, isLandscape ? 8 : 20, isLandscape ? 12 : 24, isLandscape ? 8 : 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLandscape)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kurangi Stok',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900)),
                              Text(item.name,
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis),
                              Text('Stok: ${item.stock} ${item.unit}',
                                  style: const TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: stockController,
                                  keyboardType: TextInputType.number,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 10),
                                  decoration: const InputDecoration(
                                    labelText: 'Qty',
                                    labelStyle: TextStyle(fontSize: 9),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.redAccent, size: 16),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final qty =
                                      int.tryParse(stockController.text);
                                  if (qty == null || qty <= 0) return;
                                  if (qty > item.stock) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content:
                                                Text('Stok tidak mencukupi')));
                                    return;
                                  }
                                  final updatedItem = item.copyWith(
                                      stock: item.stock - qty,
                                      updatedAt: DateTime.now());
                                  context.read<InventoryBloc>().add(
                                      UpdateInventoryItemEvent(updatedItem));
                                  Navigator.pop(dialogContext);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  minimumSize: const Size(0, 26),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                                child: const Text('OK',
                                    style: TextStyle(fontSize: 9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kurangi Stok',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900)),
                              Text(item.name,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Stok saat ini: ${item.stock} ${item.unit}',
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Jumlah dikurangi',
                        labelStyle: TextStyle(fontSize: 13),
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Batal',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final qty = int.tryParse(stockController.text);
                            if (qty == null || qty <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Masukkan jumlah yang valid')));
                              return;
                            }
                            if (qty > item.stock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Stok tidak mencukupi')));
                              return;
                            }
                            final updatedItem = item.copyWith(
                                stock: item.stock - qty,
                                updatedAt: DateTime.now());
                            context
                                .read<InventoryBloc>()
                                .add(UpdateInventoryItemEvent(updatedItem));
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Simpan',
                              style:
                                  TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  final String title;
  final bool isCompact;

  const _FilterSectionTitle({
    required this.title,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: isCompact ? 12 : 15,
        color: const Color(0xFF475569),
      ),
    );
  }
}

class _CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCompact;
  final Function(bool) onSelected;

  const _CustomFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: isCompact ? 11 : 13,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF065F46),
      backgroundColor: Colors.white,
      showCheckmark: false,
      elevation: 0,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8),
      visualDensity: isCompact
          ? const VisualDensity(horizontal: -4, vertical: -4)
          : const VisualDensity(horizontal: -2, vertical: -2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF065F46) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
