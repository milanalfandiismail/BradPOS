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
  final ImagePicker _picker = ImagePicker();
  final _currencyFormat = NumberFormat.decimalPattern('id');
  bool _showPurchasePrice = false;
  bool _isSubmitting = false;

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
    _stockController = TextEditingController(
      text: (widget.item != null && widget.item!.stock != -1)
          ? widget.item!.stock.toString()
          : '',
    );
    _unitController = TextEditingController(text: widget.item?.unit ?? 'pcs');
    _barcodeController = TextEditingController(
      text: widget.item?.barcode ?? '',
    );
    _imagePath = widget.item?.imageUrl;

    if (widget.item != null) {
      _showPurchasePrice =
          widget.item!.purchasePrice > 0 || widget.item!.stock != -1;
    }
  }

  void _toggleRetailMode(bool value) {
    setState(() => _showPurchasePrice = value);
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
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
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
          setState(() => _isSubmitting = false);
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
          purchasePrice: _showPurchasePrice
              ? _parseCurrency(_purchasePriceController.text)
              : 0,
          sellingPrice: _parseCurrency(_sellingPriceController.text),
          stock: _showPurchasePrice
              ? (int.tryParse(_stockController.text.trim()) ?? 0)
              : -1,
          unit: _showPurchasePrice ? _unitController.text.trim() : 'pcs',
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  String _generateUuid() =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                String shopName = 'BradPOS';
                if (state is AuthAuthenticated)
                  shopName = state.user.shopName ?? 'BradPOS';
                return BradHeader(
                  title: isEditing ? 'Ubah Produk' : 'Tambah Produk Baru',
                  subtitle: shopName,
                  showBackButton: true,
                  leadingIcon: Icons.inventory_2_rounded,
                  showSettings: false,
                );
              },
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: isLandscape
                    ? _buildLandscapeLayout()
                    : _buildPortraitLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _buildSectionHeader(Icons.image_outlined, 'Foto Produk'),
        const SizedBox(height: 12),
        _buildImageCard(),
        const SizedBox(height: 24),
        _buildSectionHeader(Icons.inventory_2_outlined, 'Informasi Produk'),
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
          _buildModernTextField(
            controller: _sellingPriceController,
            label: 'Harga Jual',
            icon: Icons.upload_rounded,
            prefix: 'Rp',
            keyboard: TextInputType.number,
            formatters: [CurrencyInputFormatter()],
          ),
          if (_showPurchasePrice) ...[
            const SizedBox(height: 20),
            _buildModernTextField(
              controller: _purchasePriceController,
              label: 'Harga Beli (Opsional)',
              icon: Icons.download_rounded,
              prefix: 'Rp',
              keyboard: TextInputType.number,
              formatters: [CurrencyInputFormatter()],
            ),
            const SizedBox(height: 20),
            _buildModernTextField(
              controller: _stockController,
              label: 'Stok Saat Ini',
              icon: Icons.inventory_rounded,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _buildPickerField(
              label: 'Satuan',
              icon: Icons.straighten_rounded,
              value: _unitController.text,
              onTap: _showUnitPicker,
            ),
            const SizedBox(height: 20),
            _buildModernTextField(
              controller: _barcodeController,
              label: 'Barcode (Opsional)',
              icon: Icons.qr_code_scanner_rounded,
            ),
          ],
          const Divider(height: 40),
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Retail',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Text(
                      'Aktifkan untuk input harga beli & stok',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _showPurchasePrice,
                onChanged: _toggleRetailMode,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ]),
        const SizedBox(height: 40),
        _buildSubmitButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  Icons.image_outlined,
                  'Foto Produk',
                  isCompact: true,
                ),
                const SizedBox(height: 4),
                _buildImageCard(isCompact: true),
                const SizedBox(height: 10),
                _buildSectionHeader(
                  Icons.inventory_2_outlined,
                  'Informasi Produk',
                  isCompact: true,
                ),
                const SizedBox(height: 4),
                _buildSectionCard([
                  _buildModernTextField(
                    controller: _nameController,
                    label: 'Nama Produk',
                    icon: Icons.edit_note_rounded,
                    hint: 'Contoh: Kopi Susu Aren',
                    isCompact: true,
                  ),
                  const SizedBox(height: 6),
                  _buildPickerField(
                    label: 'Kategori',
                    icon: Icons.grid_view_rounded,
                    value: _categoryController.text.isEmpty
                        ? 'Pilih Kategori'
                        : _categoryController.text,
                    onTap: _showCategoryPicker,
                    isCompact: true,
                  ),
                ], isCompact: true),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  Icons.payments_outlined,
                  'Harga & Stok',
                  isCompact: true,
                ),
                const SizedBox(height: 6),
                _buildSectionCard([
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: _sellingPriceController,
                          label: 'Harga Jual',
                          icon: Icons.upload_rounded,
                          prefix: 'Rp',
                          keyboard: TextInputType.number,
                          formatters: [CurrencyInputFormatter()],
                          isCompact: true,
                        ),
                      ),
                      if (_showPurchasePrice) ...[
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildModernTextField(
                            controller: _purchasePriceController,
                            label: 'Harga Beli (Opsional)',
                            icon: Icons.download_rounded,
                            prefix: 'Rp',
                            keyboard: TextInputType.number,
                            formatters: [CurrencyInputFormatter()],
                            isCompact: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_showPurchasePrice) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildModernTextField(
                            controller: _stockController,
                            label: 'Stok',
                            icon: Icons.inventory_rounded,
                            keyboard: TextInputType.number,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: _buildPickerField(
                            label: 'Satuan',
                            icon: Icons.straighten_rounded,
                            value: _unitController.text,
                            onTap: _showUnitPicker,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 3,
                          child: _buildModernTextField(
                            controller: _barcodeController,
                            label: 'Barcode (Opsional)',
                            icon: Icons.qr_code_scanner_rounded,
                            isCompact: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 10,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Retail',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Color(0xFF475569),
                              ),
                            ),
                            Text(
                              'Input harga beli & stok',
                              style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 18,
                        child: Transform.scale(
                          scale: 0.6,
                          child: Switch(
                            value: _showPurchasePrice,
                            onChanged: _toggleRetailMode,
                            activeTrackColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ], isCompact: true),
                const SizedBox(height: 12),
                _buildSubmitButton(isCompact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({bool isCompact = false}) => Container(
    width: double.infinity,
    height: isCompact ? 32 : 56,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(isCompact ? 8 : 18),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withAlpha(50),
          blurRadius: isCompact ? 6 : 12,
          offset: Offset(0, isCompact ? 2 : 4),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 8 : 18),
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH PRODUK',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isCompact ? 10 : 14,
                letterSpacing: 0.5,
              ),
            ),
    ),
  );

  Widget _buildImageCard({bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 4 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: isCompact ? 50 : 120,
            height: isCompact ? 50 : 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(isCompact ? 8 : 24),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isCompact ? 8 : 22),
              child: _imagePath != null
                  ? (_imagePath!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: _imagePath!,
                            fit: BoxFit.cover,
                          )
                        : Image.file(File(_imagePath!), fit: BoxFit.cover))
                  : Icon(
                      Icons.add_a_photo_rounded,
                      size: isCompact ? 18 : 28,
                      color: AppColors.primary.withAlpha(100),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    IconData icon,
    String title, {
    bool isCompact = false,
  }) => Row(
    children: [
      Icon(icon, size: isCompact ? 10 : 18, color: AppColors.primary),
      SizedBox(width: isCompact ? 3 : 8),
      Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: isCompact ? 9 : 11,
          color: const Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    ],
  );

  Widget _buildSectionCard(List<Widget> children, {bool isCompact = false}) =>
      Container(
        padding: EdgeInsets.all(isCompact ? 8 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isCompact ? 10 : 24),
          boxShadow: isCompact
              ? const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
    bool isCompact = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!isCompact) ...[
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
      ],
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        style: TextStyle(
          fontSize: isCompact ? 10 : 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: isCompact ? label : hint,
          prefixText: prefix != null ? '$prefix ' : null,
          prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
            child: Icon(
              icon,
              size: isCompact ? 13 : 20,
              color: AppColors.primary,
            ),
          ),
          prefixIconConstraints: isCompact
              ? const BoxConstraints(minWidth: 30, minHeight: 0)
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 16,
            vertical: isCompact ? 8 : 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isCompact ? 8 : 16),
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
    bool isCompact = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!isCompact) ...[
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
      ],
      InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 16,
            vertical: isCompact ? 8 : 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(isCompact ? 8 : 16),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: isCompact ? 8 : 12),
                child: Icon(
                  icon,
                  size: isCompact ? 13 : 20,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 10 : 14,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: isCompact ? 13 : 20,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  void _showCategoryPicker() {
    final cats = _getCategories();
    final items =
        (cats.map((c) => c.name).toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())))
          ..add('+ Tambah Baru');
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: _PickerModal(
            title: 'Pilih Kategori',
            items: items,
            onSelect: (val) => _handleCategorySelect(val, cats),
            onAddNew: (name) => _handleCategoryAdd(name),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _PickerModal(
          title: 'Pilih Kategori',
          items: items,
          onSelect: (val) => _handleCategorySelect(val, cats),
          onAddNew: (name) => _handleCategoryAdd(name),
        ),
      );
    }
  }

  void _handleCategorySelect(String val, List<Category> cats) {
    final c = cats.firstWhere((x) => x.name == val);
    setState(() {
      _selectedCategoryId = c.id;
      _categoryController.text = c.name;
    });
  }

  void _handleCategoryAdd(String name) {
    sl<CategoryBloc>().add(AddCategoryEvent(name));
    setState(() {
      _categoryController.text = name;
      _selectedCategoryId = null;
    });
  }

  void _showUnitPicker() {
    final items =
        (List<String>.from(_unitOptions)
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())))
          ..add('+ Tambah Baru');
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: _PickerModal(
            title: 'Pilih Satuan',
            items: items,
            onSelect: _handleUnitSelect,
            onAddNew: (name) => setState(() => _unitController.text = name),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _PickerModal(
          title: 'Pilih Satuan',
          items: items,
          onSelect: _handleUnitSelect,
          onAddNew: (name) => setState(() => _unitController.text = name),
        ),
      );
    }
  }

  void _handleUnitSelect(String val) {
    setState(() => _unitController.text = val);
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

class _PickerModal extends StatefulWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelect;
  final Function(String) onAddNew;

  const _PickerModal({
    required this.title,
    required this.items,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  State<_PickerModal> createState() => _PickerModalState();
}

class _PickerModalState extends State<_PickerModal> {
  late List<String> currentItems;

  @override
  void initState() {
    super.initState();
    currentItems = List.from(widget.items);
  }

  void _handleAddNew() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(widget.title.replaceFirst('Pilih', 'Tambah')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama baru...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                final val = ctrl.text.trim();
                widget.onAddNew(val);
                setState(() {
                  currentItems.insert(currentItems.length - 1, val);
                  // Sort all items except the last one (+ Tambah Baru)
                  final addButton = currentItems.removeLast();
                  currentItems.sort(
                    (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                  );
                  currentItems.add(addButton);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, isLandscape ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * (isLandscape ? 0.85 : 0.6),
        maxWidth: isLandscape
            ? MediaQuery.of(context).size.width * 0.75
            : double.infinity,
        minWidth: isLandscape ? MediaQuery.of(context).size.width * 0.75 : 0.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title.toUpperCase(),
                style: TextStyle(
                  fontSize: isLandscape ? 12 : 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isLandscape)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(50),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          SizedBox(height: isLandscape ? 12 : 24),
          Flexible(
            child: isLandscape
                ? GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 2.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: currentItems.length,
                    itemBuilder: (context, index) =>
                        _buildPickerItem(currentItems[index], true),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: currentItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildPickerItem(currentItems[index], false),
                  ),
          ),
          if (!isLandscape) ...[
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
          ],
        ],
      ),
    );
  }

  Widget _buildPickerItem(String label, bool isCompact) {
    final isAdd = label == '+ Tambah Baru';
    return InkWell(
      onTap: () {
        if (isAdd) {
          _handleAddNew();
        } else {
          Navigator.pop(context);
          widget.onSelect(label);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isCompact ? 6 : 16,
        ),
        decoration: BoxDecoration(
          gradient: isAdd
              ? const LinearGradient(
                  colors: [
                    AppColors.primaryGradientStart,
                    AppColors.primaryGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isAdd ? null : const Color(0xFFF8FAFC),
          border: Border.all(
            color: isAdd ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isAdd
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (isAdd)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: isCompact ? 14 : 20,
                  color: Colors.white,
                ),
              ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isAdd ? FontWeight.w800 : FontWeight.w600,
                  fontSize: isCompact ? 10 : 14,
                  color: isAdd ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isAdd)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: isCompact ? 8 : 12,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
