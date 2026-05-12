import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/blocs/category_bloc.dart';
import 'package:bradpos/presentation/blocs/category_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryFormAddMetadataScreen extends StatefulWidget {
  final String type; // 'Kategori' atau 'Satuan'
  
  const InventoryFormAddMetadataScreen({
    super.key, 
    required this.type,
  });

  @override
  State<InventoryFormAddMetadataScreen> createState() => _InventoryFormAddMetadataScreenState();
}

class _InventoryFormAddMetadataScreenState extends State<InventoryFormAddMetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();

      if (widget.type == 'Kategori') {
        final bloc = sl<CategoryBloc>();
        final state = bloc.state;
        if (state is CategoryLoaded) {
          final exists = state.categories.any(
            (c) => c.name.toLowerCase() == name.toLowerCase(),
          );
          if (exists) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kategori "$name" sudah ada!'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }

      Navigator.pop(context, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) => BradHeader(
                title: 'Tambah ${widget.type} Baru',
                subtitle: state.displayShopName,
                  showBackButton: true,
                  leadingIcon: widget.type == 'Kategori'
                      ? Icons.category_rounded
                      : Icons.straighten_rounded,
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
                      Text(
                        'NAMA ${widget.type.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama ${widget.type.toLowerCase()}...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(18),
                          prefixIcon: Icon(
                            widget.type == 'Kategori' 
                                ? Icons.category_outlined 
                                : Icons.straighten_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onFieldSubmitted: (_) => _save(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
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
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'SIMPAN & GUNAKAN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
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
    );
  }
}
