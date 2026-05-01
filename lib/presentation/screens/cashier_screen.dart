import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  String _activeCategory = 'All Items';
  List<ent.Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    context.read<InventoryBloc>().add(SyncAllEvent());
    context.read<InventoryBloc>().add(LoadCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: BlocListener<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventoryLoaded) {
            setState(() { _categories = state.categories; });
            // Refresh shop name from local storage (synced by SyncService)
            context.read<AuthBloc>().add(CheckAuthStatus());
          }
        },
        child: BlocListener<CashierBloc, CashierState>(
          listener: (context, state) {
            if (state.isSuccess) {
              context.read<InventoryBloc>().add(const LoadInventory(page: 1, limit: 5, skipSync: true));
              context.read<InventoryBloc>().add(LoadCategoriesEvent());
            }
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: Colors.redAccent));
            }
          },
          child: Column(
            children: [
              _buildSearchBar(),
              _buildCategories(),
              _buildProductGrid(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: const MainBottomNavBar(activeLabel: 'Kasir'),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: const Padding(padding: EdgeInsets.all(12.0), child: CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person, color: Color(0xFF065F46), size: 20))),
      titleSpacing: 0, 
      title: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String shopName = 'BradPOS';
          if (state is AuthAuthenticated) {
            shopName = state.user.shopName ?? 'BradPOS';
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('BradPOS', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
              Text(shopName, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          );
        },
      ),
      actions: [IconButton(icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)), onPressed: () {})],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        height: 56, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: 'Search products, SKUs, or barcodes.', hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14), prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16)),
          onChanged: (val) => context.read<InventoryBloc>().add(LoadInventory(searchQuery: val, category: _activeCategory == 'All Items' ? null : _activeCategory)),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final List<String> catNames = ['All Items', ..._categories.map((c) => c.name)];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal, itemCount: catNames.length,
        itemBuilder: (context, index) {
          final cat = catNames[index];
          final isActive = _activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat), selected: isActive,
              onSelected: (val) {
                setState(() => _activeCategory = cat);
                context.read<InventoryBloc>().add(LoadInventory(category: cat == 'All Items' ? null : cat, searchQuery: _searchController.text.isEmpty ? null : _searchController.text));
              },
              selectedColor: const Color(0xFF065F46), backgroundColor: Colors.white,
              labelStyle: TextStyle(color: isActive ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isActive ? Colors.transparent : Colors.grey.shade200)),
              showCheckmark: false, elevation: 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return Expanded(
      child: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, invState) {
          if (invState is InventoryLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF065F46)));
          if (invState is InventoryLoaded) {
            return BlocBuilder<CashierBloc, CashierState>(
              builder: (context, cashierState) {
                final items = invState.items;
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.6, crossAxisSpacing: 16, mainAxisSpacing: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final product = items[index];
                    final cartIdx = cashierState.cartItems.indexWhere((i) => i.produkId == product.id);
                    final qty = cartIdx >= 0 ? cashierState.cartItems[cartIdx].quantity : 0;
                    return _buildProductCard(product, qty);
                  },
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildProductCard(InventoryItem product, int qty) {
    final trackStock = product.stock != -1;
    final isOutOfStock = trackStock && product.stock <= 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: qty > 0 ? const Color(0xFF065F46) : const Color(0xFFE2E8F0), width: qty > 0 ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: ColorFiltered(
                    colorFilter: isOutOfStock ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: Image.network(
                      _getImg(product.name, product.imageUrl),
                      width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFF1F5F9), child: const Icon(Icons.fastfood, color: Colors.grey)),
                    ),
                  ),
                ),
                if (qty > 0)
                  Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF065F46), shape: BoxShape.circle), child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                if (trackStock)
                  Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isOutOfStock ? Colors.red.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)), child: Text(isOutOfStock ? 'OUT OF STOCK' : 'STOK: ${product.stock}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(currencyFormatter.format(product.sellingPrice), style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 12),
                _buildQuantityBar(product, qty),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBar(InventoryItem product, int qty) {
    final trackStock = product.stock != -1;
    if (qty == 0) {
      final canAdd = !trackStock || product.stock > 0;
      return SizedBox(
        width: double.infinity, height: 36,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF065F46), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: canAdd ? () => context.read<CashierBloc>().add(AddToCart(product)) : null,
          child: Text(canAdd ? 'ADD TO CART' : 'OUT OF STOCK', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      );
    }
    return Container(
      height: 36, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _qBtn(Icons.remove, () => context.read<CashierBloc>().add(UpdateCartQuantity(product.id, -1)), Colors.redAccent),
          Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          _qBtn(Icons.add, () {
            if (!trackStock || qty < product.stock) {
              context.read<CashierBloc>().add(AddToCart(product));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak mencukupi!'), duration: Duration(seconds: 1)));
            }
          }, const Color(0xFF065F46)),
        ],
      ),
    );
  }

  Widget _qBtn(IconData icon, VoidCallback onTap, Color color) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(width: 40, height: 36, alignment: Alignment.center, child: Icon(icon, size: 18, color: color)));

  Widget _buildFAB() {
    return BlocBuilder<CashierBloc, CashierState>(
      builder: (context, state) {
        if (state.cartItems.isEmpty) return const SizedBox();
        return Stack(alignment: Alignment.topRight, children: [FloatingActionButton(onPressed: () => _showCartSheet(context, state), backgroundColor: const Color(0xFF065F46), elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.shopping_cart_outlined, color: Colors.white)), Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF991B1B), shape: BoxShape.circle), child: Text('${state.cartItems.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))]);
      },
    );
  }

  void _showCartSheet(BuildContext context, CashierState state) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => _CartBottomSheet(state: state));
  }


  String _getImg(String name, String? url) {
    if (url != null && url.isNotEmpty) return url;
    final Map<String, String> m = { 'Classic Iced Latte': 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&q=80&w=400', 'Blueberry Muffin': 'https://images.unsplash.com/photo-1558301211-0d8c8ddee6ec?auto=format&fit=crop&q=80&w=400', 'Avocado Smash': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&q=80&w=400', 'Ceremonial Matcha': 'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?auto=format&fit=crop&q=80&w=400', 'Margherita Slice': 'https://images.unsplash.com/photo-1574071318508-1cdbad80ad50?auto=format&fit=crop&q=80&w=400', 'Fresh OJ': 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&q=80&w=400', 'Butter Croissant': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&q=80&w=400', 'Garden Power': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=400', 'Red Velvet Cupcake': 'https://images.unsplash.com/photo-1614707267537-b85aaf00c4b7?auto=format&fit=crop&q=80&w=400', 'Signature Burger': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&q=80&w=400' };
    return m[name] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=400';
  }
}

class _CartBottomSheet extends StatelessWidget {
  final CashierState state;
  const _CartBottomSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Flexible(child: ListView.builder(shrinkWrap: true, itemCount: state.cartItems.length, itemBuilder: (context, index) { final item = state.cartItems[index]; return ListTile(title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${item.quantity} x ${currency.format(item.unitPrice)}'), trailing: Text(currency.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46)))); })), const Divider(), Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(currency.format(state.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF065F46)))])), SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF065F46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentScreen(cashierState: state))); }, child: const Text('CHECKOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(height: 20)]));
  }
}
