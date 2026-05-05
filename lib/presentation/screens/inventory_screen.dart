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
import 'package:bradpos/presentation/screens/category_list_screen.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/settings_modal.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/utils/app_navigator.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  List<InventoryItem> _lastItems = [];
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  String _selectedCategory = 'All';
  String _stockFilter = 'All';
  bool _isKaryawan = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadPage();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        context.read<InventoryBloc>().add(
          LoadInventory(limit: 100, searchQuery: query),
        );
      } else {
        _currentPage = 1;
        _loadPage();
      }
      setState(() {});
    });
  }

  Future<void> _checkUserRole() async {
    final authRepo = sl<AuthRepository>();
    final result = await authRepo.getCurrentUser();
    final user = result.getOrElse(() => null);
    if (user != null && mounted) setState(() => _isKaryawan = user.isKaryawan);
  }

  void _loadPage() => context.read<InventoryBloc>().add(
    LoadInventory(
      page: _currentPage,
      limit: _itemsPerPage,
      searchQuery: _searchController.text.trim(),
      category: _selectedCategory,
      stockStatus: _stockFilter,
    ),
  );

  @override
  void dispose() {
    _searchController.dispose();
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
          child: BlocBuilder<InventoryBloc, InventoryState>(
            builder: (context, state) => Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildContent(state)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const MainBottomNavBar(activeLabel: 'INVENTORY'),
      ),
    );
  }

  Widget _buildContent(InventoryState state) {
    if (state is InventoryLoading && _lastItems.isEmpty) {
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
    final isSearching = _searchController.text.trim().isNotEmpty;
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
        if (!isSearching && totalPages > 1)
          _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
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
          ),
          const SizedBox(width: 12),
          Text(
            '$_currentPage / $totalPages',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 12,
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
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({VoidCallback? onPressed, required IconData icon}) =>
      Material(
        color: onPressed == null
            ? Colors.grey.shade50
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: onPressed == null
                  ? Colors.grey.shade300
                  : AppColors.primary,
            ),
          ),
        ),
      );

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              String shopName = 'BradPOS';
              if (state is AuthAuthenticated) {
                shopName = state.user.shopName ?? 'BradPOS';
              }
              return BradHeader(
                title: 'Manajemen Inventory / Produk',
                subtitle: shopName,
                leadingIcon: Icons.inventory_2_rounded,
                onSettingsTap: () => SettingsModal.show(context),
                actions: [
                  IconButton(
                    onPressed: () {
                      AppNavigator.push(
                        context,
                        BlocProvider.value(
                          value: context.read<InventoryBloc>(),
                          child: const CategoryListScreen(),
                        ),
                      ).then((_) {
                        if (!mounted) return;
                        if (!context.mounted) return;
                        context.read<InventoryBloc>().add(
                          const LoadInventory(page: 1, limit: 5),
                        );
                      });
                    },
                    icon: const Icon(
                      Icons.category_outlined,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                    tooltip: 'Kategori',
                  ),
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
                      size: 22,
                    ),
                    tooltip: 'Sync Now',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products by name or SKU...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF0F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFilterSheet(),
                  icon: const Icon(Icons.tune, size: 20),
                  label: const Text('Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isKaryawan
                    ? const SizedBox.shrink()
                    : ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('New Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF065F46),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInventoryList(List<InventoryItem> items) => ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return InventoryItemCard(
        item: item,
        isKaryawan: _isKaryawan,
        onEdit: () => _openForm(item: item),
        onDelete: () => _showDeleteConfirmation(item),
        onAddStock: item.stock == -1 ? null : () => _showAddStockDialog(item),
        onReduceStock: item.stock == -1
            ? null
            : () => _showReduceStockDialog(item),
      );
    },
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
                // Handle bar
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : const Color(0xFF64748B),
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
    );
  }
}
