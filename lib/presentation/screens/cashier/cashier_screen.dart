import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_event.dart';
import 'package:bradpos/presentation/blocs/inventory_state.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';
import 'package:bradpos/domain/entities/category.dart' as ent;
import 'package:intl/intl.dart';
import 'package:bradpos/presentation/screens/cashier/cart_summary_view.dart';
import 'package:bradpos/presentation/screens/cashier/cashier_product_card.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/settings_modal.dart';

import 'package:bradpos/core/widgets/main_navigation_rail.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  String _activeCategory = 'All Items';
  List<ent.Category> _categories = [];
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    // Data loaded via didChangeDependencies logic
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInit) {
      _doSync();
      _isInit = true;
    }
  }

  void _doSync() {
    context.read<InventoryBloc>().add(
          LoadInventory(
            searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
            category: _activeCategory == 'All Items' ? null : _activeCategory,
            limit: 1000, // Ambil semua barang sekaligus
            skipSync: true,
          ),
        );
    context.read<InventoryBloc>().add(LoadInventoryCategoriesEvent());
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool showSidebar = isLandscape && constraints.maxWidth > 550;
            final double sidebarWidth = isLandscape ? 220.0 : 350.0;
            const double railWidth = 64.0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLandscape)
                  const MainNavigationRail(activeLabel: 'CASHIER'),
                if (isLandscape)
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: BlocListener<InventoryBloc, InventoryState>(
                    listener: (context, state) {
                      if (state is InventoryLoaded) {
                        setState(() {
                          _categories = state.categories;
                        });
                      }
                    },
                    child: BlocListener<CashierBloc, CashierState>(
                      listener: (context, state) {
                        if (state.isSuccess) {
                          _doSync();
                        }
                        if (state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.error!),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      child: BlocBuilder<InventoryBloc, InventoryState>(
                        builder: (context, invState) {
                          return CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    BlocBuilder<AuthBloc, AuthState>(
                                      builder: (context, state) => BradHeader(
                                        title: 'Kasir',
                                        subtitle: state.displayShopName,
                                          leadingIcon: Icons.point_of_sale_rounded,
                                          showBottomBorder: true,
                                          showSettings: !isLandscape,
                                          onSettingsTap: () => SettingsModal.show(context),
                                          onSyncTap: _doSync,
                                          actions: isLandscape ? [
                                            IconButton(
                                              onPressed: _doSync,
                                              icon: const Icon(Icons.sync_rounded, color: Color(0xFF64748B), size: 18),
                                              tooltip: 'Sync',
                                            ),
                                          ] : null,
                                      ),
                                    ),
                                    _buildSearchBar(isCompact: isLandscape),
                                    if (isLandscape) const SizedBox(height: 4),
                                    _buildCategories(isCompact: isLandscape),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                              _buildProductGridSliver(
                                constraints.maxWidth -
                                    (showSidebar ? sidebarWidth : 0) -
                                    (isLandscape ? railWidth : 0),
                                isLandscape: isLandscape,
                                invState: invState,
                              ),
                              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (showSidebar) ...[
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                  Container(
                    width: sidebarWidth,
                    color: Colors.white,
                    child: BlocBuilder<CashierBloc, CashierState>(
                      builder: (context, state) {
                        return CartSummaryView(state: state, isSidebar: true);
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = isLandscape && mediaQuery.size.width > 550;
          if (showSidebar) return const SizedBox();
          return _buildFAB();
        },
      ),
      bottomNavigationBar: isLandscape
          ? null
          : const MainBottomNavBar(activeLabel: 'CASHIER'),
    );
  }

  Widget _buildSearchBar({bool isCompact = false}) {
    return Padding(
      padding: isCompact
          ? const EdgeInsets.fromLTRB(8, 8, 12, 8)
          : const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: isCompact ? 48 : 56,
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          controller: _searchController,
          style: TextStyle(fontSize: isCompact ? 14 : 14),
          decoration: InputDecoration(
            hintText: 'Cari produk...',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: isCompact ? 14 : 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey,
              size: isCompact ? 20 : 20,
            ),
            prefixIconConstraints: isCompact
                ? const BoxConstraints(minWidth: 40, minHeight: 48)
                : null,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 8 : 16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 8 : 16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 8 : 16),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      context.read<InventoryBloc>().add(
                            LoadInventory(
                              page: 1,
                              limit: 10,
                              skipSync: true,
                              searchQuery: null,
                              category: _activeCategory == 'All Items'
                                  ? null
                                  : _activeCategory,
                            ),
                          );
                      setState(() {});
                    },
                  )
                : null,
            isDense: isCompact,
            contentPadding: isCompact
                ? const EdgeInsets.symmetric(horizontal: 12)
                : const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (val) {
            _doSync();
          },
        ),
      ),
    );
  }

  Widget _buildCategories({bool isCompact = false}) {
    final List<String> catNames = [
      'All Items',
      ..._categories.map((c) => c.name),
    ];
    return SizedBox(
      height: isCompact ? 40 : 44,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
        scrollDirection: Axis.horizontal,
        itemCount: catNames.length,
        itemBuilder: (context, index) {
          final cat = catNames[index];
          final isActive = _activeCategory == cat;
          return Padding(
            padding: EdgeInsets.only(right: isCompact ? 4 : 6),
            child: ChoiceChip(
              label: Text(cat, style: TextStyle(fontSize: isCompact ? 13 : 13)),
              labelPadding: isCompact
                  ? const EdgeInsets.symmetric(horizontal: 12)
                  : null,
              selected: isActive,
              materialTapTargetSize: isCompact
                  ? MaterialTapTargetSize.shrinkWrap
                  : null,
              visualDensity: isCompact ? VisualDensity.comfortable : null,
              onSelected: (val) {
                setState(() {
                  _activeCategory = cat;
                });
                _doSync();
              },
              selectedColor: const Color(0xFF065F46),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isCompact ? 6 : 12),
                side: BorderSide(
                  color: isActive
                      ? Colors.transparent
                      : const Color(0xFFCBD5E1),
                ),
              ),
              showCheckmark: false,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 12,
                vertical: isCompact ? 8 : 4,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGridSliver(double availableWidth,
      {bool isLandscape = false, required InventoryState invState}) {
    int crossAxisCount = 2;
    double aspectRatio = 0.65;

    if (isLandscape) {
      crossAxisCount = 4;
      aspectRatio = 0.7;
    } else {
      if (availableWidth > 600) {
        crossAxisCount = 3;
        aspectRatio = 0.7;
      } else {
        crossAxisCount = 2;
        aspectRatio = 0.65;
      }
    }

    if (invState is InventoryLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 100),
            child: CircularProgressIndicator(color: Color(0xFF065F46)),
          ),
        ),
      );
    }

    if (invState is InventoryLoaded) {
      return BlocBuilder<CashierBloc, CashierState>(
        builder: (context, cashierState) {
          return SliverPadding(
            padding: EdgeInsets.fromLTRB(
              isLandscape ? 4 : 20,
              isLandscape ? 4 : 4,
              isLandscape ? 4 : 20,
              20,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: isLandscape ? 4 : 16,
                mainAxisSpacing: isLandscape ? 4 : 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = invState.items[index];
                  final cartIdx = cashierState.cartItems.indexWhere(
                    (i) => i.produkId == product.id,
                  );
                  final qty = cartIdx >= 0
                      ? cashierState.cartItems[cartIdx].quantity
                      : 0;
                  final authState = context.read<AuthBloc>().state;
                  final isGuest = authState is AuthAuthenticated &&
                      authState.user.isGuest;
                  return CashierProductCard(
                    product: product,
                    qty: qty,
                    isGuest: isGuest,
                    isCompact: isLandscape,
                    currencyFormatter: currencyFormatter,
                    onAddToCart: (p) =>
                        context.read<CashierBloc>().add(AddToCart(p)),
                    onUpdateQuantity: (p, delta) => context
                        .read<CashierBloc>()
                        .add(UpdateCartQuantity(p.id, delta)),
                  );
                },
                childCount: invState.items.length,
              ),
            ),
          );
        },
      );
    }
    return const SliverToBoxAdapter(child: SizedBox());
  }

  Widget _buildFAB() {
    return BlocBuilder<CashierBloc, CashierState>(
      builder: (context, state) {
        if (state.cartItems.isEmpty) return const SizedBox();
        return Stack(
          alignment: Alignment.topRight,
          children: [
            FloatingActionButton(
              onPressed: () => _showCartSheet(context, state),
              backgroundColor: const Color(0xFF065F46),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF991B1B),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${state.cartItems.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCartSheet(BuildContext context, CashierState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CartSummaryView(state: state),
    );
  }
}

