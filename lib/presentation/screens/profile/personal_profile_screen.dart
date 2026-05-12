import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/profile_text_field.dart';
import 'package:bradpos/presentation/widgets/full_screen_image_viewer.dart';
import 'package:bradpos/presentation/widgets/image_source_picker.dart';
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
  late TextEditingController _shopIdController;
  late TextEditingController _passwordController;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _shopIdController = TextEditingController();
    _passwordController = TextEditingController();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _fullNameController.text = authState.user.name ?? '';
      _emailController.text = authState.user.email;
      _shopIdController.text = authState.user.shopId ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _shopIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showFullScreenImage(
    String? remoteUrl,
    String? localPath,
    bool isOwner,
    bool isEditable,
  ) {
    return FullScreenImageViewer.show(
      context: context,
      localImagePath: localPath,
      remoteImageUrl: remoteUrl,
      heroTag: 'profile_avatar',
      onEdit: (!isOwner && isEditable) ? _showPickerPopup : null,
    );
  }

  Future<void> _showPickerPopup() async {
    final source = await ImageSourcePicker.show(
      context: context,
      title: 'Ganti Foto Profil',
    );
    if (source != null && mounted) {
      _pickAndUploadImage(source);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
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
      authBloc.add(
        UpdateProfileEvent(
          localImage: localPath,
          fullName: _fullNameController.text,
        ),
      );

      authBloc.stream
          .firstWhere(
            (s) =>
                s is AuthAuthenticated && s.user.remoteImage != oldRemoteImage,
          )
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final bool isOwner =
        authState is AuthAuthenticated && authState.user.isOwner;
    final bool isGuest =
        authState is AuthAuthenticated && authState.user.isGuest;

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
                showSettings: false,
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

                              return Stack(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showFullScreenImage(
                                        remoteUrl,
                                        localPath,
                                        isOwner,
                                        false,
                                      ),
                                      borderRadius: BorderRadius.circular(60),
                                      child: Hero(
                                        tag: 'profile_avatar',
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: SizedBox(
                                              width: 120,
                                              height: 120,
                                              child:
                                                  (localPath != null &&
                                                      File(
                                                        localPath,
                                                      ).existsSync())
                                                  ? Image.file(
                                                      File(localPath),
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) =>
                                                              _buildAvatarFallback(),
                                                    )
                                                  : remoteUrl != null &&
                                                        remoteUrl.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: remoteUrl,
                                                      fit: BoxFit.cover,
                                                      placeholder: (_, _) =>
                                                          _buildAvatarPlaceholder(),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) =>
                                                              _buildAvatarFallback(),
                                                    )
                                                  : _buildAvatarFallback(),
                                            ),
                                          ),
                                        ),
                                      ),
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
                                                  Colors.white,
                                                ),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Foto Profil',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      Text(
                        'Informasi Akun',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 24),
                      if (!isGuest) ...[
                        if (!isOwner) ...[
                          _buildFieldLabel('Shop ID'),
                          _buildTextField(
                            _shopIdController,
                            'SHOP123',
                            icon: Icons.store_outlined,
                            readOnly: true,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildFieldLabel('Full Name'),
                        _buildTextField(
                          _fullNameController,
                          'Alexander Sterling',
                          icon: Icons.person_outline_rounded,
                          readOnly: !isOwner,
                        ),
                        const SizedBox(height: 20),
                        if (isOwner) ...[
                          _buildFieldLabel('Email Address'),
                          _buildTextField(
                            _emailController,
                            'email@example.com',
                            icon: Icons.mail_outline_rounded,
                            readOnly: true,
                          ),
                        ],
                      ] else ...[
                        // Logika untuk Guest
                        _buildFieldLabel('Nama Anda (Offline Mode)'),
                        _buildTextField(
                          _fullNameController,
                          'Guest User',
                          icon: Icons.person_outline_rounded,
                          readOnly: true,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nama ini akan digunakan pada struk transaksi Anda.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (isOwner) ...[
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthBloc>().add(
                                  UpdateProfileEvent(
                                    fullName: _fullNameController.text,
                                    newPassword:
                                        _passwordController.text.isNotEmpty
                                        ? _passwordController.text
                                        : null,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profil berhasil diperbarui!',
                                    ),
                                    backgroundColor: Color(0xFF006D44),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006D44),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
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
    return Container(
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.grey.shade200,
      child: Image.network(
        'https://ui-avatars.com/api/?name=${_fullNameController.text}&background=random',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.person, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    IconData? icon,
    bool readOnly = false,
    bool obscureText = false,
  }) {
    return ProfileTextField(
      controller: controller,
      hint: hint,
      maxLines: maxLines,
      icon: icon,
      readOnly: readOnly,
      obscureText: obscureText,
      borderRadius: 16,
    );
  }
}
