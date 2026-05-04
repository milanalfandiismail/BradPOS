import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/domain/entities/category.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_event.dart';
import 'package:bradpos/presentation/blocs/inventory_state.dart';
import 'package:bradpos/presentation/blocs/category_bloc.dart';
import 'package:bradpos/presentation/blocs/category_event.dart';
import 'package:bradpos/domain/repositories/inventory_repository.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    try {
      double value = double.parse(newValue.text.replaceAll('.', ''));
      final formatter = NumberFormat.decimalPattern('id');
      String newText = formatter.format(value);
      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}

class InventoryFormScreen extends StatefulWidget {
  final InventoryItem? item;
  const InventoryFormScreen({super.key, this.item});

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _unitController;
  late TextEditingController _barcodeController;
  String? _selectedCategoryId;
  String? _imagePath;
  bool _trackStock = true;
  final ImagePicker _picker = ImagePicker();
  final _currencyFormat = NumberFormat.decimalPattern('id');

  bool get isEditing => widget.item != null;
  static const List<String> _unitOptions = [
    'pcs',
    'kg',
    'gram',
    'liter',
    'ml',
    'pack',
    'box',
    'lusin',
    'karton',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _categoryController = TextEditingController(
      text: widget.item?.category ?? '',
    );
    _selectedCategoryId = widget.item?.categoryId;
    _purchasePriceController = TextEditingController(
      text: widget.item != null
          ? _currencyFormat.format(widget.item!.purchasePrice)
          : '',
    );
    _sellingPriceController = TextEditingController(
      text: widget.item != null
          ? _currencyFormat.format(widget.item!.sellingPrice)
          : '',
    );
    _trackStock = widget.item == null || widget.item!.stock != -1;
    _stockController = TextEditingController(
      text: (widget.item != null && widget.item!.stock != -1)
          ? widget.item!.stock.toString()
          : '0',
    );
    _unitController = TextEditingController(text: widget.item?.unit ?? 'pcs');
    _barcodeController = TextEditingController(
      text: widget.item?.barcode ?? '',
    );
    _imagePath = widget.item?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  List<Category> _getCategories() {
    final state = context.read<InventoryBloc>().state;
    return state is InventoryLoaded ? state.categories : [];
  }

  double _parseCurrency(String text) =>
      double.tryParse(text.replaceAll('.', '')) ?? 0;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final repository = sl<InventoryRepository>();
      final isExists = await repository.isProductNameExists(
        name,
        excludeId: isEditing ? widget.item!.id : null,
      );
      if (isExists && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama produk sudah ada!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      String ownerId = widget.item?.ownerId ?? '';
      if (ownerId.isEmpty) {
        final res = await sl<AuthRepository>().getCurrentUser();
        final u = res.getOrElse(() => null);
        if (u != null) ownerId = u.isKaryawan ? u.ownerId! : u.id;
      }
      final newItem = InventoryItem(
        id: (widget.item == null || widget.item!.id.isEmpty)
            ? _generateUuid()
            : widget.item!.id,
        ownerId: ownerId,
        categoryId: _selectedCategoryId,
        name: name,
        category: _categoryController.text.trim(),
        purchasePrice: _parseCurrency(_purchasePriceController.text),
        sellingPrice: _parseCurrency(_sellingPriceController.text),
        stock: _trackStock
            ? (int.tryParse(_stockController.text.trim()) ?? 0)
            : -1,
        unit: _trackStock
            ? _unitController.text.trim()
            : 'pcs', // Default to pcs if not tracking
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        imageUrl: _imagePath,
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (!mounted) return;
      context.read<InventoryBloc>().add(
        isEditing
            ? UpdateInventoryItemEvent(newItem)
            : AddInventoryItemEvent(newItem),
      );
      Navigator.pop(context);
    }
  }

  String _generateUuid() =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  String shopName = 'BradPOS';
                  if (state is AuthAuthenticated) {
                    shopName = state.user.shopName ?? 'BradPOS';
                  }
                  return BradHeader(
                    title: isEditing ? 'Ubah Produk' : 'Tambah Produk Baru',
                    subtitle: shopName,
                    showBackButton: true,
                    leadingIcon: Icons.inventory_2_rounded,
                  );
                },
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  children: [
                    _buildSectionHeader(Icons.image_outlined, 'Foto Produk'),
                    const SizedBox(height: 12),
                    _buildImageCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      Icons.inventory_2_outlined,
                      'Informasi Produk',
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard([
                      _buildModernTextField(
                        controller: _nameController,
                        label: 'Nama Produk',
                        icon: Icons.edit_note_rounded,
                        hint: 'Contoh: Kopi Susu Aren',
                      ),
                      const SizedBox(height: 20),
                      _buildPickerField(
                        label: 'Kategori',
                        icon: Icons.grid_view_rounded,
                        value: _categoryController.text.isEmpty
                            ? 'Pilih Kategori'
                            : _categoryController.text,
                        onTap: _showCategoryPicker,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader(Icons.payments_outlined, 'Harga & Stok'),
                    const SizedBox(height: 12),
                    _buildSectionCard([
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              controller: _purchasePriceController,
                              label: 'Harga Beli',
                              icon: Icons.download_rounded,
                              prefix: 'Rp',
                              keyboard: TextInputType.number,
                              formatters: [CurrencyInputFormatter()],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernTextField(
                              controller: _sellingPriceController,
                              label: 'Harga Jual',
                              icon: Icons.upload_rounded,
                              prefix: 'Rp',
                              keyboard: TextInputType.number,
                              formatters: [CurrencyInputFormatter()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Kelola Stok Barang',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              Switch(
                                value: _trackStock,
                                onChanged: (v) => setState(() => _trackStock = v),
                                activeTrackColor: AppColors.primary,
                              ),
                            ],
                          ),
                          Text(
                            _trackStock
                                ? 'Stok akan berkurang otomatis setiap penjualan.'
                                : 'Stok tidak terbatas (cocok untuk jasa atau menu kustom).',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (_trackStock) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernTextField(
                                controller: _stockController,
                                label: 'Stok Saat Ini',
                                icon: Icons.inventory_rounded,
                                keyboard: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPickerField(
                                label: 'Satuan',
                                icon: Icons.straighten_rounded,
                                value: _unitController.text,
                                onTap: _showUnitPicker,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildModernTextField(
                        controller: _barcodeController,
                        label: 'Barcode (Opsional)',
                        icon: Icons.qr_code_scanner_rounded,
                      ),
                    ]),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH PRODUK',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _imagePath != null
                  ? (_imagePath!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: _imagePath!,
                            fit: BoxFit.cover,
                          )
                        : Image.file(File(_imagePath!), fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          size: 28,
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        const Text(
                          'Foto',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 1,
        ),
      ),
    ],
  );

  Widget _buildSectionCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefix,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix != null ? '$prefix ' : null,
          prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );

  Widget _buildPickerField({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  void _showCategoryPicker() {
    final cats = _getCategories();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PickerModal(
        title: 'Pilih Kategori',
        items: [...cats.map((c) => c.name), '+ Tambah Baru'],
        onSelect: (val) {
          if (val == '+ Tambah Baru') {
            _showNewItemDialog('Kategori Baru', (name) {
              // Add to Bloc so it saves to DB
              sl<CategoryBloc>().add(AddCategoryEvent(name));
              
              // Local update for immediate UI feedback
              setState(() {
                _categoryController.text = name;
                _selectedCategoryId = null; // Will be matched later or handled during save
              });
            });
          } else {
            final c = cats.firstWhere((x) => x.name == val);
            setState(() {
              _selectedCategoryId = c.id;
              _categoryController.text = c.name;
            });
          }
        },
      ),
    );
  }

  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PickerModal(
        title: 'Pilih Satuan',
        items: [..._unitOptions, '+ Tambah Baru'],
        onSelect: (val) {
          if (val == '+ Tambah Baru') {
            _showNewItemDialog('Satuan Baru', (name) {
              setState(() {
                _unitController.text = name;
              });
            });
          } else {
            setState(() {
              _unitController.text = val;
            });
          }
        },
      ),
    );
  }

  void _showNewItemDialog(String title, Function(String) onConfirm) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nama...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                onConfirm(ctrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final dir = await getApplicationDocumentsDirectory();
      final p = '${dir.path}/${path.basename(img.path)}';
      await File(img.path).copy(p);
      setState(() => _imagePath = p);
    }
  }
}

class _PickerModal extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelect;
  const _PickerModal({
    required this.title,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(
                    items[index],
                    style: TextStyle(
                      fontWeight: items[index].startsWith('+')
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: items[index].startsWith('+')
                          ? AppColors.primary
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade300,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(items[index]);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'TUTUP',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
