import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/karyawan_bloc.dart';
import '../bloc/karyawan_event.dart';
import '../bloc/karyawan_state.dart';
import '../widgets/karyawan_card.dart';
import '../../domain/entities/karyawan.dart';
import 'karyawan_form_screen.dart';

/// Halaman Daftar Karyawan.
/// Menampilkan semua karyawan yang terdaftar dan menyediakan akses ke Tambah/Edit/Hapus.
class KaryawanListScreen extends StatefulWidget {
  const KaryawanListScreen({super.key});

  @override
  State<KaryawanListScreen> createState() => _KaryawanListScreenState();
}

class _KaryawanListScreenState extends State<KaryawanListScreen> {
  @override
  void initState() {
    super.initState();
    // Meminta BLoC untuk memuat daftar karyawan saat halaman dibuka
    context.read<KaryawanBloc>().add(LoadKaryawanList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocListener<KaryawanBloc, KaryawanState>(
          listener: (context, state) {
            // Tampilkan feedback snackbar jika operasi Berhasil
            if (state is KaryawanOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: BlocBuilder<KaryawanBloc, KaryawanState>(
                  builder: (context, state) {
                    if (state is KaryawanLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is KaryawanListLoaded) {
                      return _buildKaryawanList(state.karyawanList);
                    } else if (state is KaryawanError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bagian Header Halaman yang berisi Judul, Pencarian, dan Tombol Tambah.
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                'Manajemen Karyawan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Filter Pencarian
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari karyawan berdasarkan nama atau ID...',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Baris tombol Filter dan Tambah Karyawan (RBAC)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final bool isOwner =
                  authState is AuthAuthenticated && authState.user.isOwner;

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Tombol Tambah hanya muncul untuk Owner
                  if (isOwner) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<KaryawanBloc>(),
                                child: const KaryawanFormScreen(),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Karyawan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Membuat daftar list karyawan menggunakan ListView.
  Widget _buildKaryawanList(List<Karyawan> karyawanList) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: karyawanList.length,
      itemBuilder: (context, index) {
        return KaryawanCard(
          karyawan: karyawanList[index],
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<KaryawanBloc>(),
                  child: KaryawanFormScreen(karyawan: karyawanList[index]),
                ),
              ),
            );
          },
          onDelete: () {
            _showDeleteConfirmation(context, karyawanList[index]);
          },
        );
      },
    );
  }

  /// Menampilkan dialog konfirmasi sebelum menghapus data.
  void _showDeleteConfirmation(BuildContext context, Karyawan karyawan) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Karyawan'),
        content: Text('Apakah Anda yakin ingin menghapus ${karyawan.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Kirim event hapus ke Bloc
              context.read<KaryawanBloc>().add(RemoveKaryawan(karyawan.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
