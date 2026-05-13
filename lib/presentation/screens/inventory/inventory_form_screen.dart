import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:bradpos/presentation/blocs/category_bloc.dart';
import 'package:bradpos/presentation/blocs/category_event.dart';
import 'package:bradpos/presentation/blocs/category_state.dart';
import 'package:bradpos/domain/repositories/inventory_repository.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/screens/inventory/category_picker_modal.dart';
import 'package:bradpos/presentation/widgets/currency_input_formatter.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_form_image_picker.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_form_common.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_form_fields.dart';
import 'package:intl/intl.dart';

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
    final state = sl<CategoryBloc>().state;
    return state is CategoryLoaded ? state.categories : [];
  }

  double _parseCurrency(String text) =>
      double.tryParse(text.replaceAll('.', '')) ?? 0;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final name = _nameController.text.trim();

        // Skip duplicate check if editing and name hasn't changed
        if (!isEditing || name != widget.item!.name) {
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
              builder: (context, state) => BradHeader(
                title: isEditing ? 'Ubah Produk' : 'Tambah Produk Baru',
                subtitle: state.displayShopName,
                  showBackButton: true,
                  leadingIcon: Icons.inventory_2_rounded,
                  showSettings: false,
                ),
              ),
            Expanded(
              child: BlocProvider.value(
                value: sl<CategoryBloc>(),
                child: BlocListener<CategoryBloc, CategoryState>(
                  listener: (context, state) {
                    if (state is CategoryLoaded) {
                      final newCatName = _categoryController.text.trim();
                      if (newCatName.isNotEmpty) {
                        final found = state.categories.where((c) => c.name == newCatName);
                        if (found.isNotEmpty) {
                          setState(() {
                            _selectedCategoryId = found.first.id;
                          });
                        }
                      }
                    }
                  },
                  child: Form(
                    key: _formKey,
                    child: isLandscape
                        ? _buildLandscapeLayout()
                        : _buildPortraitLayout(),
                  ),
                ),
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
        buildFormSectionHeader(Icons.image_outlined, 'Foto Produk'),
        const SizedBox(height: 12),
        InventoryFormImagePicker(
          imagePath: _imagePath,
          onPickImage: _pickImage,
        ),
        const SizedBox(height: 24),
        buildFormSectionHeader(
          Icons.inventory_2_outlined,
          'Informasi Produk',
        ),
        const SizedBox(height: 12),
        buildFormSectionCard([
          FormTextField(
            controller: _nameController,
            label: 'Nama Produk',
            icon: Icons.edit_note_rounded,
            hint: 'Contoh: Kopi Susu Aren',
          ),
          const SizedBox(height: 20),
          FormPickerField(
            label: 'Kategori',
            icon: Icons.grid_view_rounded,
            value: _categoryController.text.isEmpty
                ? 'Pilih Kategori'
                : _categoryController.text,
            onTap: _showCategoryPicker,
          ),
        ]),
        const SizedBox(height: 24),
        buildFormSectionHeader(Icons.payments_outlined, 'Harga & Stok'),
        const SizedBox(height: 12),
        buildFormSectionCard([
          FormTextField(
            controller: _sellingPriceController,
            label: 'Harga Jual',
            icon: Icons.upload_rounded,
            prefix: 'Rp',
            keyboardType: TextInputType.number,
            formatters: [CurrencyInputFormatter()],
          ),
          if (_showPurchasePrice) ...[
            const SizedBox(height: 20),
            FormTextField(
              controller: _purchasePriceController,
              label: 'Harga Beli (Opsional)',
              icon: Icons.download_rounded,
              prefix: 'Rp',
              keyboardType: TextInputType.number,
              formatters: [CurrencyInputFormatter()],
            ),
            const SizedBox(height: 20),
            FormTextField(
              controller: _stockController,
              label: 'Stok Saat Ini',
              icon: Icons.inventory_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            FormPickerField(
              label: 'Satuan',
              icon: Icons.straighten_rounded,
              value: _unitController.text,
              onTap: _showUnitPicker,
            ),
            const SizedBox(height: 20),
            FormTextField(
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
        buildFormSubmitButton(
          isSubmitting: _isSubmitting,
          isEditing: isEditing,
          onSubmit: _submit,
        ),
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFormSectionHeader(Icons.image_outlined, 'Foto Produk'),
              const SizedBox(height: 8),
              InventoryFormImagePicker(
                imagePath: _imagePath,
                isCompact: false,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: 16),
              buildFormSectionHeader(
                Icons.inventory_2_outlined,
                'Informasi Produk',
              ),
              const SizedBox(height: 8),
              buildFormSectionCard([
                FormTextField(
                  controller: _nameController,
                  label: 'Nama Produk',
                  icon: Icons.edit_note_rounded,
                  hint: 'Contoh: Kopi Susu Aren',
                ),
                const SizedBox(height: 16),
                FormPickerField(
                  label: 'Kategori',
                  icon: Icons.grid_view_rounded,
                  value: _categoryController.text.isEmpty
                      ? 'Pilih Kategori'
                      : _categoryController.text,
                  onTap: _showCategoryPicker,
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFormSectionHeader(
                Icons.payments_outlined,
                'Harga & Stok',
              ),
              const SizedBox(height: 8),
              buildFormSectionCard([
                FormTextField(
                  controller: _sellingPriceController,
                  label: 'Harga Jual',
                  icon: Icons.upload_rounded,
                  prefix: 'Rp',
                  keyboardType: TextInputType.number,
                  formatters: [CurrencyInputFormatter()],
                ),
                if (_showPurchasePrice) ...[
                  const SizedBox(height: 16),
                  FormTextField(
                    controller: _purchasePriceController,
                    label: 'Harga Beli (Opsional)',
                    icon: Icons.download_rounded,
                    prefix: 'Rp',
                    keyboardType: TextInputType.number,
                    formatters: [CurrencyInputFormatter()],
                  ),
                  const SizedBox(height: 16),
                  FormTextField(
                    controller: _stockController,
                    label: 'Stok Saat Ini',
                    icon: Icons.inventory_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  FormPickerField(
                    label: 'Satuan',
                    icon: Icons.straighten_rounded,
                    value: _unitController.text,
                    onTap: _showUnitPicker,
                  ),
                  const SizedBox(height: 16),
                  FormTextField(
                    controller: _barcodeController,
                    label: 'Barcode (Opsional)',
                    icon: Icons.qr_code_scanner_rounded,
                  ),
                ],
                const Divider(height: 24),
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
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
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
              const SizedBox(height: 16),
              buildFormSubmitButton(
                isSubmitting: _isSubmitting,
                isEditing: isEditing,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  void _showCategoryPicker() {
    FocusScope.of(context).unfocus(); // TUTUP KEYBOARD DULU BIAR GK OVERFLOW
    sl<CategoryBloc>().add(LoadCategoriesEvent());
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
          child: PickerModal(
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
        builder: (context) => PickerModal(
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
    // Refresh InventoryBloc's categories so the filter on InventoryScreen is updated
    context.read<InventoryBloc>().add(const LoadInventoryCategoriesEvent());
    setState(() {
      _categoryController.text = name;
      _selectedCategoryId = null;
    });
  }

  void _showUnitPicker() {
    FocusScope.of(context).unfocus(); // TUTUP KEYBOARD DULU BIAR GK OVERFLOW
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
          child: PickerModal(
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
        builder: (context) => PickerModal(
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    ImageSource? source;
    if (isLandscape) {
      source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          title: const Text('Pilih Foto',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    } else {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PILIH FOTO PRODUK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }

    if (!mounted) return;

    if (source != null) {
      final XFile? img = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (img != null) {
        final dir = await getApplicationDocumentsDirectory();
        final p = '${dir.path}/${path.basename(img.path)}';
        await File(img.path).copy(p);
        setState(() => _imagePath = p);
      }
    }
  }
}

