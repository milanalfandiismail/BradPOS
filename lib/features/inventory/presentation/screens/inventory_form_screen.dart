import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/app_colors.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/inventory_item.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../../injection_container.dart';

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
          ? widget.item!.purchasePrice.toStringAsFixed(0)
          : '',
    );
    _sellingPriceController = TextEditingController(
      text: widget.item != null
          ? widget.item!.sellingPrice.toStringAsFixed(0)
          : '',
    );
    _stockController = TextEditingController(
      text: widget.item != null ? widget.item!.stock.toString() : '',
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
    if (state is InventoryLoaded) return state.categories;
    return [];
  }

  Future<String?> _saveImagePermanently(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final name = path.basename(imagePath);
      // Buat folder 'inventory_images' di dalam dokumen aplikasi
      final imagesDir = Directory('${directory.path}/inventory_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final permanentPath = '${imagesDir.path}/$name';
      final imageFile = File(imagePath);
      await imageFile.copy(permanentPath);

      return permanentPath;
    } catch (e) {
      debugPrint("Gagal menyimpan gambar secara permanen: $e");
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Simpan file ke folder permanen aplikasi
        final permanentPath = await _saveImagePermanently(image.path);
        if (permanentPath != null) {
          setState(() {
            _imagePath = permanentPath;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
      }
    }
  }

  String _generateUuid() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10xx
    final hexStr = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    return '${hexStr.substring(0, 8)}-${hexStr.substring(8, 12)}-${hexStr.substring(12, 16)}-${hexStr.substring(16, 20)}-${hexStr.substring(20)}';
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final repository = sl<InventoryRepository>();

      // Validasi nama produk tidak boleh duplikat (untuk owner yang sama)
      final isExists = await repository.isProductNameExists(
        name,
        excludeId: isEditing ? widget.item!.id : null,
      );

      if (isExists && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama produk sudah ada! Gunakan nama lain.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final isNewItem = widget.item == null || widget.item!.id.isEmpty;
      final newItem = InventoryItem(
        id: isNewItem ? _generateUuid() : widget.item!.id,
        ownerId:
            widget.item?.ownerId ??
            Supabase.instance.client.auth.currentUser?.id ??
            '',
        categoryId: _selectedCategoryId == 'other' ? null : _selectedCategoryId,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        sellingPrice: double.parse(_sellingPriceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        unit: _unitController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        imageUrl: _imagePath,
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (!mounted) return;

      if (isEditing) {
        context.read<InventoryBloc>().add(UpdateInventoryItemEvent(newItem));
      } else {
        context.read<InventoryBloc>().add(AddInventoryItemEvent(newItem));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getCategories();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light Slate Background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          isEditing ? 'Ubah Produk' : 'Tambah Produk Baru',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // --- SECTION 1: MEDIA ---
            _buildSectionHeader(Icons.image_outlined, 'Foto Produk'),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SizedBox.expand(
                          child: _imagePath != null
                              ? (_imagePath!.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: _imagePath!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : Image.file(
                                      File(_imagePath!),
                                      fit: BoxFit.cover,
                                    ))
                              : Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: AppColors.primary.withOpacity(0.05),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_rounded,
                                        size: 36,
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Upload Foto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      if (_imagePath != null)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- SECTION 2: BASIC INFO ---
            _buildSectionCard([
              _buildModernTextField(
                controller: _nameController,
                label: 'Nama Produk',
                icon: Icons.inventory_2_rounded,
                hint: 'Contoh: Es Teh Manis',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nama produk wajib diisi'
                    : null,
              ),
              const SizedBox(height: 20),
              _buildModernDropdown(
                label: 'Kategori',
                icon: Icons.category_rounded,
                value:
                    (categories.any((c) => c.id == _selectedCategoryId) ||
                        _selectedCategoryId == 'other')
                    ? _selectedCategoryId
                    : null,
                items: [
                  ...categories.map(
                    (cat) =>
                        DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                  ),
                  const DropdownMenuItem(
                    value: 'other',
                    child: Text(
                      '+ Tambah Kategori Baru',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                    if (val != null && val != 'other') {
                      final selectedCat = categories.firstWhere(
                        (cat) => cat.id == val,
                      );
                      _categoryController.text = selectedCat.name;
                    } else if (val == 'other') {
                      _categoryController.text = '';
                    }
                  });
                },
              ),
              if (_selectedCategoryId == 'other') ...[
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: _categoryController,
                  label: 'Nama Kategori Baru',
                  icon: Icons.edit_note_rounded,
                  hint: 'Masukkan kategori baru...',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Kategori baru wajib diisi'
                      : null,
                ),
              ],
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(Icons.payments_outlined, 'Harga & Stok'),
            const SizedBox(height: 12),

            // --- SECTION 3: PRICING & STOCK ---
            _buildSectionCard([
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _purchasePriceController,
                      label: 'Harga Beli',
                      icon: Icons.arrow_downward_rounded,
                      prefix: 'Rp',
                      keyboard: TextInputType.number,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _sellingPriceController,
                      label: 'Harga Jual',
                      icon: Icons.arrow_upward_rounded,
                      prefix: 'Rp',
                      keyboard: TextInputType.number,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _stockController,
                      label: 'Stok Saat Ini',
                      icon: Icons.layers_rounded,
                      keyboard: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Wajib';
                        if (int.tryParse(value.trim()) == null) return 'Angka!';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernDropdown(
                      label: 'Satuan',
                      icon: Icons.straighten_rounded,
                      value: _unitOptions.contains(_unitController.text)
                          ? _unitController.text
                          : (_unitController.text.isEmpty ? 'pcs' : 'other'),
                      items: [
                        ..._unitOptions.map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            )),
                        const DropdownMenuItem(
                          value: 'other',
                          child: Text(
                            '+ Lainnya',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          if (val != null && val != 'other') {
                            _unitController.text = val;
                          } else if (val == 'other') {
                            _unitController.text = ''; // Kosongkan agar bisa diisi kustom
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (!_unitOptions.contains(_unitController.text) || _unitController.text.isEmpty) ...[
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: _unitController,
                  label: 'Nama Satuan Kustom',
                  icon: Icons.edit_road_rounded,
                  hint: 'Misal: porsi, ikat, renteng...',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Satuan kustom wajib diisi'
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _barcodeController,
                label: 'Barcode (Opsional)',
                icon: Icons.qr_code_scanner_rounded,
                hint: 'Scan atau ketik kode barcode',
              ),
            ]),

            const SizedBox(height: 40),

            // --- SUBMIT BUTTON ---
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 8,
                shadowColor: AppColors.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_rounded,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Simpan Perubahan' : 'Tambah Produk Sekarang',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefix,
    Widget? suffix,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix != null ? '$prefix ' : null,
            prefixStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: suffix,
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
