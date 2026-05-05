import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PersonalProfileScreen extends StatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _fullNameController.text = authState.user.name ?? '';
      _emailController.text = authState.user.email;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (image == null) return;
      if (!mounted) return;

      final dir = await getApplicationDocumentsDirectory();
      final localPath =
          '${dir.path}/profile_personal_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      await File(image.path).copy(localPath);
      if (!mounted) return;

      final authBloc = context.read<AuthBloc>();
      final oldRemoteImage = authBloc.state is AuthAuthenticated
          ? (authBloc.state as AuthAuthenticated).user.remoteImage
          : null;

      setState(() => _isUploadingImage = true);
      authBloc.add(UpdateProfileEvent(
        localImage: localPath,
        fullName: _fullNameController.text,
      ));

      authBloc.stream
          .firstWhere((s) =>
              s is AuthAuthenticated &&
              s.user.remoteImage != oldRemoteImage)
          .timeout(const Duration(seconds: 15))
          .then((_) {
            if (mounted) setState(() => _isUploadingImage = false);
          })
          .catchError((_) {
            if (mounted) setState(() => _isUploadingImage = false);
          });
    } catch (e) {
      debugPrint("PersonalProfileScreen: Error: $e");
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final bool isOwner = authState is AuthAuthenticated && authState.user.isOwner;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const BradHeader(
                title: 'Profil Saya',
                subtitle: 'Kelola informasi pribadi Anda',
                showBackButton: true,
                leadingIcon: Icons.person_rounded,
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
                      if (!isOwner) ...[
                        Center(
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              String? remoteUrl;
                              String? localPath;
                              if (state is AuthAuthenticated) {
                                remoteUrl = state.user.remoteImage;
                                localPath = state.user.localImage;
                              }

                              return InkWell(
                                onTap: _isUploadingImage
                                    ? null
                                    : _pickAndUploadImage,
                                borderRadius: BorderRadius.circular(50),
                                child: Stack(
                                  children: [
                                    ClipOval(
                                      child: SizedBox(
                                        width: 100,
                                        height: 100,
                                        child: (localPath != null &&
                                                File(localPath).existsSync())
                                            ? Image.file(File(localPath),
                                                fit: BoxFit.cover)
                                            : remoteUrl != null &&
                                                    remoteUrl.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: remoteUrl,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, _) =>
                                                        _buildAvatarPlaceholder(),
                                                    errorWidget: (_, _, _) =>
                                                        _buildAvatarFallback(),
                                                  )
                                                : _buildAvatarFallback(),
                                      ),
                                    ),
                                    if (_isUploadingImage)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black26,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                              strokeWidth: 3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF006D44),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Foto Profil',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      const Text(
                        'Personal Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 24),
                      _buildFieldLabel('Full Name'),
                      _buildTextField(_fullNameController, 'Alexander Sterling', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 20),
                      _buildFieldLabel('Email Address'),
                      _buildTextField(_emailController, 'alexander@sterlinggourmet.com', icon: Icons.mail_outline_rounded, readOnly: true),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthBloc>().add(
                                UpdateProfileEvent(
                                  fullName: _fullNameController.text,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Color(0xFF006D44)),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006D44),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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

  Widget _buildAvatarPlaceholder() {
    return Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.grey.shade200,
      child: Image.network(
        'https://ui-avatars.com/api/?name=${_fullNameController.text}&background=random',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.person, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF475569))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, IconData? icon, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF006D44), width: 2)),
      ),
    );
  }
}
