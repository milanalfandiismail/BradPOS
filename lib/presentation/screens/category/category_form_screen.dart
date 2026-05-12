import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/domain/entities/category.dart';
import 'package:bradpos/presentation/blocs/category_bloc.dart';
import 'package:bradpos/presentation/blocs/category_event.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;
  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<CategoryBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => BradHeader(
                    title: isEditing ? 'Edit Kategori' : 'Kategori Baru',
                    subtitle: state.displayShopName,
                    showBackButton: true,
                    leadingIcon: Icons.category_rounded,
                    showBottomBorder: true,
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NAMA KATEGORI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Minuman, Makanan Ringan',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.category_outlined,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama kategori tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              isEditing
                                  ? 'PERBARUI KATEGORI'
                                  : 'SIMPAN KATEGORI',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      if (isEditing) {
        sl<CategoryBloc>().add(UpdateCategoryEvent(widget.category!.id, name));
      } else {
        sl<CategoryBloc>().add(AddCategoryEvent(name));
      }
      Navigator.pop(context);
    }
  }
}
