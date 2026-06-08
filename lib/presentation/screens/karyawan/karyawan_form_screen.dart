import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/domain/entities/karyawan.dart';
import 'package:bradpos/presentation/blocs/karyawan_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_event.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/avatar_picker_widget.dart';
import 'package:bradpos/presentation/widgets/full_screen_image_viewer.dart';
import 'package:bradpos/presentation/widgets/image_source_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isActive = true;
  String? _localImagePath;
  String? _remoteImageUrl;

  bool get isEditing => widget.karyawan != null;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan nilai yang sudah ada (jika mode edit)
    _nameController = TextEditingController(text: widget.karyawan?.name ?? '');
    _passwordController = TextEditingController();
    _isActive = widget.karyawan?.isActive ?? true;
    _localImagePath = widget.karyawan?.localImage;
    _remoteImageUrl = widget.karyawan?.remoteImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        password: password,
        isActive: _isActive,
        createdAt: widget.karyawan?.createdAt ?? DateTime.now(),
        localImage: _localImagePath,
        remoteImage: _remoteImageUrl,
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

  void _showFullScreenImage() {
    FullScreenImageViewer.show(
      context: context,
      localImagePath: _localImagePath,
      remoteImageUrl: _remoteImageUrl,
      heroTag: 'karyawan_avatar_${widget.karyawan?.id ?? 'new'}',
      title: _nameController.text,
      onEdit: _pickImage,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await ImageSourcePicker.show(context: context);

    if (!mounted) return;

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (image != null) {
        setState(() {
          _localImagePath = image.path;
          _remoteImageUrl = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => BradHeader(
                  title: isEditing ? 'Ubah Karyawan' : 'Tambah Karyawan',
                  subtitle: state.displayShopName,
                    showBackButton: true,
                    leadingIcon: Icons.person_add_rounded,
                    showSettings: false,
                  ),
                ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Avatar & Switch
                          Expanded(
                            flex: 2,
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                AvatarPickerWidget(
                                  localImagePath: _localImagePath,
                                  remoteImageUrl: _remoteImageUrl,
                                  heroTag: 'karyawan_avatar_${widget.karyawan?.id ?? 'new'}',
                                  isCompact: true,
                                  onTap: () {
                                    if ((_localImagePath != null &&
                                            File(_localImagePath!).existsSync()) ||
                                        (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty)) {
                                      _showFullScreenImage();
                                    } else {
                                      _pickImage();
                                    }
                                  },
                                  onCameraTap: _pickImage,
                                ),
                                const SizedBox(height: 16),
                                _buildStatusSwitch(isCompact: true),
                              ],
                            ),
                          ),
                          // Right Column: Inputs & Submit
                          Expanded(
                            flex: 3,
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                _buildNameInput(isCompact: true),
                                const SizedBox(height: 12),
                                _buildPasswordInput(isCompact: true),
                                const SizedBox(height: 20),
                                _buildSubmitButton(isCompact: true),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          AvatarPickerWidget(
                            localImagePath: _localImagePath,
                            remoteImageUrl: _remoteImageUrl,
                            heroTag: 'karyawan_avatar_${widget.karyawan?.id ?? 'new'}',
                            isCompact: false,
                            onTap: () {
                              if ((_localImagePath != null &&
                                      File(_localImagePath!).existsSync()) ||
                                  (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty)) {
                                _showFullScreenImage();
                              } else {
                                _pickImage();
                              }
                            },
                            onCameraTap: _pickImage,
                          ),
                          const SizedBox(height: 32),
                          _buildNameInput(isCompact: false),
                          const SizedBox(height: 16),
                          _buildPasswordInput(isCompact: false),
                          const SizedBox(height: 24),
                          _buildStatusSwitch(isCompact: false),
                          const SizedBox(height: 32),
                          _buildSubmitButton(isCompact: false),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInput({required bool isCompact}) {
    return TextFormField(
      controller: _nameController,
      style: TextStyle(fontSize: isCompact ? 12 : 14),
      decoration: InputDecoration(
        labelText: 'Nama',
        hintText: 'Masukkan nama karyawan',
        labelStyle: TextStyle(fontSize: isCompact ? 12 : 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: isCompact,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nama wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordInput({required bool isCompact}) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(fontSize: isCompact ? 12 : 14),
      decoration: InputDecoration(
        labelText: 'Password ( Kosongkan jika tidak mau diganti )',
        hintText: isEditing
            ? (isCompact ? 'Password Baru' : 'Kosongkan jika tidak diubah')
            : 'Masukkan password',
        labelStyle: TextStyle(fontSize: isCompact ? 12 : 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: isCompact,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            size: isCompact ? 18 : 24,
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
    );
  }

  Widget _buildStatusSwitch({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SwitchListTile(
        title: Text(
          'Karyawan Aktif',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
        subtitle: isCompact
            ? null
            : const Text(
                'Nonaktifkan jika karyawan sudah tidak bekerja',
                style: TextStyle(fontSize: 12),
              ),
        value: _isActive,
        onChanged: (val) => setState(() => _isActive = val),
        activeTrackColor: AppColors.primary,
        dense: isCompact,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSubmitButton({required bool isCompact}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isEditing ? 'Simpan Perubahan' : 'Tambah Karyawan',
          style: TextStyle(
            fontSize: isCompact ? 13 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
