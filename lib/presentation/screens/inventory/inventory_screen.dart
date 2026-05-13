import 'dart:async';
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
import 'package:bradpos/presentation/screens/inventory/inventory_filter_section.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_add_stock_dialog.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_reduce_stock_dialog.dart';

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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
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
      _loadPage(); // Sync pas pertama kali masuk tab
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

  void _loadPage({bool skipSync = false}) {
    context.read<InventoryBloc>().add(
      LoadInventory(
        page: _currentPage,
        limit: _itemsPerPage,
        searchQuery: _searchController.text.trim(),
        category: _selectedCategory,
        stockStatus: _stockFilter,
        skipSync: skipSync,
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
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentPage = 1;
        });
        _loadPage();
      }
    });
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

          // Jika ada produk baru, otomatis search produk tersebut
          if (state.addedItemName != null) {
            setState(() {
              _searchController.text = state.addedItemName!;
              _currentPage = 1;
            });
            _loadPage();
          }
        }
        if (state is InventoryLoaded) {
          _lastItems = state.items;
          setState(() {
            _currentPage = state.currentPage;
          });
        }
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
            title: 'Inventory | Produk',
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
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
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
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                          )
                        : null,
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
                  label: const Text('Tambah', style: TextStyle(fontSize: 13)),
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
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                      setState(() {});
                    },
                  )
                : null,
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: _onSearchChanged,
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
                      _loadPage(skipSync: true);
                    }
                  : null,
              onNext: _currentPage < totalPages
                  ? () {
                      setState(() => _currentPage++);
                      _loadPage(skipSync: true);
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
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = items[index];
            return InventoryItemCard(
              item: item,
              isKaryawan: _isKaryawan,
              isCompact: true,
              onEdit: () => _openForm(item: item),
              onDelete: () => _showDeleteConfirmation(item),
              onAddStock: _isKaryawan || item.stock == -1
                  ? null
                  : () => showAddStockDialog(context, item),
              onReduceStock: _isKaryawan || item.stock == -1
                  ? null
                  : () => showReduceStockDialog(context, item),
            );
          }, childCount: items.length),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InventoryItemCard(
              item: item,
              isKaryawan: _isKaryawan,
              onEdit: () => _openForm(item: item),
              onDelete: () => _showDeleteConfirmation(item),
              onAddStock: _isKaryawan || item.stock == -1
                  ? null
                  : () => showAddStockDialog(context, item),
              onReduceStock: _isKaryawan || item.stock == -1
                  ? null
                  : () => showReduceStockDialog(context, item),
            ),
          );
        }, childCount: items.length),
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
                    child: InventoryFilterContent(
                      selectedCategory: _selectedCategory,
                      stockFilter: _stockFilter,
                      categories: modalCategories,
                      onCategoryChanged: (cat) {
                        setSheetState(() => _selectedCategory = cat);
                        _selectedCategory = cat;
                        _currentPage = 1;
                        _loadPage();
                      },
                      onStockFilterChanged: (filter) {
                        setSheetState(() => _stockFilter = filter);
                        _stockFilter = filter;
                        _currentPage = 1;
                        _loadPage();
                      },
                      onApply: () {
                        _currentPage = 1;
                        _loadPage();
                        Navigator.pop(context);
                      },
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
    final modalCategories = _getFilterCategories();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return InventoryFilterContent(
              selectedCategory: _selectedCategory,
              stockFilter: _stockFilter,
              categories: modalCategories,
              isCompact: true,
              onCategoryChanged: (cat) {
                setSheetState(() => _selectedCategory = cat);
                _selectedCategory = cat;
                _currentPage = 1;
                _loadPage();
              },
              onStockFilterChanged: (filter) {
                setSheetState(() => _stockFilter = filter);
                _stockFilter = filter;
                _currentPage = 1;
                _loadPage();
              },
              onApply: () {
                _currentPage = 1;
                _loadPage();
                Navigator.pop(context);
              },
            );
          },
        ),
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
}
