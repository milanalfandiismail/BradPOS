import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/domain/entities/karyawan.dart';
import 'package:bradpos/presentation/blocs/karyawan_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_event.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/widgets/brad_header.dart';

/// Halaman Formulir untuk Tambah/Ubah data Karyawan.
class KaryawanFormScreen extends StatefulWidget {
  // Jika karyawan diisi, berarti mode Edit. Jika null, berarti mode Tambah.
  final Karyawan? karyawan;

  const KaryawanFormScreen({super.key, this.karyawan});

  @override
  State<KaryawanFormScreen> createState() => _KaryawanFormScreenState();
}

class _KaryawanFormScreenState extends State<KaryawanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  bool get isEditing => widget.karyawan != null;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan nilai yang sudah ada (jika mode edit)
    _nameController = TextEditingController(text: widget.karyawan?.name ?? '');
    _emailController = TextEditingController(
      text: widget.karyawan?.email ?? '',
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Menjalankan proses simpan data jika validasi form berhasil.
  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Jika mode edit dan password kosong, gunakan password lama.
      final password = _passwordController.text.isEmpty && isEditing
          ? widget.karyawan!.password
          : _passwordController.text;

      final newKaryawan = Karyawan(
        id: widget.karyawan?.id ?? '',
        ownerId:
            widget.karyawan?.ownerId ??
            Supabase.instance.client.auth.currentUser?.id ??
            '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: password,
        isActive: true,
        createdAt: widget.karyawan?.createdAt ?? DateTime.now(),
      );

      // Trigger event BLoC sesuai mode (Add atau Edit)
      if (isEditing) {
        context.read<KaryawanBloc>().add(EditKaryawan(newKaryawan));
      } else {
        context.read<KaryawanBloc>().add(CreateKaryawan(newKaryawan));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    title: isEditing ? 'Ubah Karyawan' : 'Tambah Karyawan',
                    subtitle: shopName,
                    showBackButton: true,
                    leadingIcon: Icons.person_add_rounded,
                  );
                },
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Input Nama
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama',
                        hintText: 'Masukkan nama karyawan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Input Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Masukkan email karyawan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!value.contains('@')) {
                          return 'Masukkan email yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Input Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: isEditing
                            ? 'Kosongkan jika tidak ingin mengubah password'
                            : 'Masukkan password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (!isEditing && (value == null || value.isEmpty)) {
                          return 'Password wajib diisi';
                        }
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Tombol Submit
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Simpan Perubahan' : 'Tambah Karyawan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
