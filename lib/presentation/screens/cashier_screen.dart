import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_event.dart';
import 'package:bradpos/presentation/blocs/inventory_state.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/domain/entities/category.dart' as ent;
import 'package:intl/intl.dart';
import 'package:bradpos/presentation/screens/payment_screen.dart';
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
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  String _activeCategory = 'All Items';
  List<ent.Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    context.read<InventoryBloc>().add(
      const LoadInventory(page: 1, limit: 10, skipSync: true),
    );
    context.read<InventoryBloc>().add(LoadCategoriesEvent());
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
                          context.read<InventoryBloc>().add(
                            const LoadInventory(
                              page: 1,
                              limit: 10,
                              skipSync: true,
                            ),
                          );
                          context.read<InventoryBloc>().add(
                            LoadCategoriesEvent(),
                          );
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
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  BlocBuilder<AuthBloc, AuthState>(
                                    builder: (context, state) {
                                      String shopName = 'BradPOS';
                                      if (state is AuthAuthenticated) {
                                        shopName = state.user.shopName ?? 'BradPOS';
                                      }
                                      return BradHeader(
                                        title: 'Kasir',
                                        subtitle: shopName,
                                        leadingIcon: Icons.point_of_sale_rounded,
                                        showBottomBorder: true,
                                        showSettings: !isLandscape,
                                        onSettingsTap: () =>
                                            SettingsModal.show(context),
                                        onSyncTap: () {
                                          context.read<InventoryBloc>().add(
                                                const LoadInventory(
                                                  page: 1,
                                                  limit: 10,
                                                  skipSync: true,
                                                ),
                                              );
                                          context
                                              .read<InventoryBloc>()
                                              .add(LoadCategoriesEvent());
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Menyingkronkan data...',
                                              ),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        actions: isLandscape
                                            ? [
                                                IconButton(
                                                  onPressed: () {
                                                    context
                                                        .read<InventoryBloc>()
                                                        .add(
                                                          const LoadInventory(
                                                            page: 1,
                                                            limit: 10,
                                                            skipSync: true,
                                                          ),
                                                        );
                                                    context
                                                        .read<InventoryBloc>()
                                                        .add(LoadCategoriesEvent());
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Menyingkronkan data...',
                                                        ),
                                                        duration:
                                                            Duration(seconds: 1),
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
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 32,
                                                    minHeight: 32,
                                                  ),
                                                ),
                                              ]
                                            : null,
                                      );
                                    },
                                  ),
                                  _buildSearchBar(isCompact: isLandscape),
                                  if (isLandscape) const SizedBox(height: 4),
                                  _buildCategories(isCompact: isLandscape),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ];
                        },
                        body: _buildProductGrid(
                          constraints.maxWidth -
                              (showSidebar ? sidebarWidth : 0) -
                              (isLandscape ? railWidth : 0),
                          isLandscape: isLandscape,
                        ),
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
          ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
          : const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: isCompact ? 22 : 56,
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          controller: _searchController,
          style: TextStyle(fontSize: isCompact ? 8 : 14),
          decoration: InputDecoration(
            hintText: 'Cari produk...',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: isCompact ? 8 : 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey,
              size: isCompact ? 12 : 20,
            ),
            prefixIconConstraints: isCompact
                ? const BoxConstraints(minWidth: 24, minHeight: 22)
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
            isDense: isCompact,
            contentPadding: isCompact
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (val) => context.read<InventoryBloc>().add(
            LoadInventory(
              page: 1,
              limit: 10,
              skipSync: true,
              searchQuery: val.isEmpty ? null : val,
              category: _activeCategory == 'All Items' ? null : _activeCategory,
            ),
          ),
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
      height: isCompact ? 22 : 44,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
        scrollDirection: Axis.horizontal,
        itemCount: catNames.length,
        itemBuilder: (context, index) {
          final cat = catNames[index];
          final isActive = _activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(cat, style: TextStyle(fontSize: isCompact ? 8 : 13)),
              labelPadding: isCompact ? EdgeInsets.zero : null,
              selected: isActive,
              materialTapTargetSize: isCompact
                  ? MaterialTapTargetSize.shrinkWrap
                  : null,
              visualDensity: isCompact
                  ? const VisualDensity(horizontal: -4, vertical: -4)
                  : null,
              onSelected: (val) {
                setState(() => _activeCategory = cat);
                context.read<InventoryBloc>().add(
                  LoadInventory(
                    page: 1,
                    limit: 10,
                    skipSync: true,
                    category: cat == 'All Items' ? null : cat,
                  ),
                );
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
                horizontal: isCompact ? 8 : 12,
                vertical: isCompact ? 0 : 4,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(double availableWidth, {bool isLandscape = false}) {
    int crossAxisCount = 2;
    double aspectRatio = 0.65;

    if (isLandscape) {
      if (availableWidth > 450) {
        crossAxisCount = 4;
        aspectRatio = 0.85;
      } else if (availableWidth > 300) {
        crossAxisCount = 3;
        aspectRatio = 0.8;
      } else {
        crossAxisCount = 2;
        aspectRatio = 0.75;
      }
    } else {
      if (availableWidth > 600) {
        crossAxisCount = 3;
        aspectRatio = 0.7;
      } else {
        crossAxisCount = 2;
        aspectRatio = 0.65;
      }
    }

    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, invState) {
        if (invState is InventoryLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF065F46)),
          );
        }
        if (invState is InventoryLoaded) {
          return BlocBuilder<CashierBloc, CashierState>(
            builder: (context, cashierState) {
              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isLandscape ? 4 : 20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: isLandscape ? 4 : 16,
                  mainAxisSpacing: isLandscape ? 4 : 16,
                ),
                itemCount: invState.items.length,
                itemBuilder: (context, index) {
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
                  return _buildProductCard(
                    product,
                    qty,
                    isGuest,
                    isCompact: isLandscape,
                  );
                },
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildProductCard(
    InventoryItem product,
    int qty,
    bool isGuest, {
    bool isCompact = false,
  }) {
    final trackStock = product.stock != -1;
    final isOutOfStock = trackStock && product.stock <= 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 20),
        border: Border.all(
          color: qty > 0 ? const Color(0xFF065F46) : const Color(0xFFCBD5E1),
          width: qty > 0 ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isCompact ? 3 : 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(isCompact ? 7 : 18),
                  ),
                  child: ColorFiltered(
                    colorFilter: isOutOfStock
                        ? const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
                    child: _buildImage(product, isGuest, isCompact: isCompact),
                  ),
                ),
                if (qty > 0)
                  Positioned(
                    top: isCompact ? 3 : 8,
                    left: isCompact ? 3 : 8,
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 3 : 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF065F46),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$qty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 8 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (trackStock)
                  Positioned(
                    top: isCompact ? 3 : 8,
                    right: isCompact ? 3 : 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(isCompact ? 4 : 10),
                      ),
                      child: Text(
                        isOutOfStock ? 'HABIS' : 'STOK: ${product.stock}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 6 : 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 4.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 8 : 13,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currencyFormatter.format(product.sellingPrice),
                  style: TextStyle(
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 9 : 14,
                  ),
                ),
                if (!isCompact) const SizedBox(height: 12),
                if (isCompact) const SizedBox(height: 4),
                _buildQuantityBar(product, qty, isCompact: isCompact),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBar(
    InventoryItem product,
    int qty, {
    bool isCompact = false,
  }) {
    final trackStock = product.stock != -1;
    if (qty == 0) {
      final canAdd = !trackStock || product.stock > 0;
      return SizedBox(
        width: double.infinity,
        height: isCompact ? 20 : 36,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF065F46),
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isCompact ? 4 : 10),
            ),
          ),
          onPressed: canAdd
              ? () => context.read<CashierBloc>().add(AddToCart(product))
              : null,
          child: Text(
            canAdd ? 'TAMBAH' : 'OUT',
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 7 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return Container(
      height: isCompact ? 20 : 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(isCompact ? 4 : 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _qBtn(
            Icons.remove,
            () => context.read<CashierBloc>().add(
              UpdateCartQuantity(product.id, -1),
            ),
            Colors.redAccent,
            isCompact: isCompact,
          ),
          Text(
            '$qty',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 9 : 14,
            ),
          ),
          _qBtn(
            Icons.add,
            () {
              if (!trackStock || qty < product.stock) {
                context.read<CashierBloc>().add(AddToCart(product));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stok tidak mencukupi!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            const Color(0xFF065F46),
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _qBtn(
    IconData icon,
    VoidCallback onTap,
    Color color, {
    bool isCompact = false,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(isCompact ? 4 : 10),
    child: Container(
      width: isCompact ? 20 : 40,
      height: isCompact ? 20 : 36,
      alignment: Alignment.center,
      child: Icon(icon, size: isCompact ? 10 : 18, color: color),
    ),
  );

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

  Widget _buildImage(
    InventoryItem product,
    bool isGuest, {
    bool isCompact = false,
  }) {
    final imageUrl = _getImg(product.name, product.imageUrl, isGuest);

    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) =>
            _buildFallbackImage(product, isCompact),
      );
    } else if (imageUrl.isNotEmpty) {
      final file = io.File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    return _buildFallbackImage(product, isCompact);
  }

  Widget _buildFallbackImage(InventoryItem product, bool isCompact) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fastfood_rounded,
                color: const Color(0xFF64748B),
                size: isCompact ? 16 : 40,
              ),
              if (!isCompact) ...[
                const SizedBox(height: 8),
                Text(
                  product.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getImg(String name, String? url, bool isGuest) {
    if (url != null && url.isNotEmpty) return url;
    return '';
  }
}

class CartSummaryView extends StatelessWidget {
  final CashierState state;
  final bool isSidebar;
  const CartSummaryView({
    super.key,
    required this.state,
    this.isSidebar = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSidebar) ...[
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
        Row(
          children: [
            Text(
              'Ringkasan',
              style: TextStyle(
                fontSize: isSidebar ? 12 : 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            if (state.cartItems.isNotEmpty)
              TextButton(
                onPressed: () {
                  context.read<CashierBloc>().add(ClearCart());
                  if (!isSidebar) Navigator.pop(context);
                },
                child: Text(
                  'HAPUS',
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w900,
                    fontSize: isSidebar ? 9 : 11,
                  ),
                ),
              ),
            if (!isSidebar)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
          ],
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        if (isSidebar) ...[
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
        ],
        const SizedBox(height: 8),
        if (state.cartItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: isSidebar ? 48 : 64,
                    color: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Keranjang Kosong',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: state.cartItems.length,
            itemBuilder: (context, index) {
              final item = state.cartItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: TextStyle(
                        fontSize: isSidebar ? 9 : 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4338CA),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            item.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: isSidebar ? 9 : 13,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currency.format(item.unitPrice),
                            style: TextStyle(
                              fontSize: isSidebar ? 8 : 9,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currency.format(item.subtotal),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isSidebar ? 9 : 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        if (isSidebar && state.cartItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Qty',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${state.cartItems.fold<int>(0, (s, i) => s + i.quantity)} item',
                  style: TextStyle(
                    fontSize: isSidebar ? 9 : 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rata-rata',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  currency.format(
                    state.total / state.cartItems.length,
                  ),
                  style: TextStyle(
                    fontSize: isSidebar ? 9 : 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tagihan',
                style: TextStyle(
                  fontSize: isSidebar ? 11 : 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                currency.format(state.total),
                style: TextStyle(
                  fontSize: isSidebar ? 14 : 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: isSidebar ? 32 : 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: state.cartItems.isEmpty
                ? null
                : () {
                    if (!isSidebar) Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(cashierState: state),
                      ),
                    );
                  },
            child: Text(
              'CHECKOUT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isSidebar ? 10 : 15,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        if (!isSidebar) const SizedBox(height: 20),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isSidebar ? 8 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isSidebar
            ? null
            : const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: !isSidebar,
        child: SingleChildScrollView(child: content),
      ),
    );
  }
}
