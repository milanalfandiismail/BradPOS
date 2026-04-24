import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/app_colors.dart';
import '../../domain/entities/karyawan.dart';
import '../bloc/karyawan_bloc.dart';
import '../bloc/karyawan_event.dart';

class KaryawanFormScreen extends StatefulWidget {
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
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
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(isEditing ? 'Ubah Karyawan' : 'Tambah Karyawan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
    );
  }
}
