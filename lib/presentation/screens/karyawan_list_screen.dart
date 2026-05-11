import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_event.dart';
import 'package:bradpos/presentation/blocs/karyawan_state.dart';
import 'package:bradpos/presentation/widgets/karyawan_card.dart';
import 'package:bradpos/domain/entities/karyawan.dart';
import 'package:bradpos/presentation/screens/karyawan_form_screen.dart';
import 'package:bradpos/core/widgets/brad_header.dart';

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

  Widget _buildAppBar() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      children: [
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            String shopName = 'BradPOS';
            if (state is AuthAuthenticated) {
              shopName = state.user.shopName ?? 'BradPOS';
            }
            return BradHeader(
              title: 'Karyawan',
              subtitle: shopName,
              showBackButton: true,
              leadingIcon: Icons.people_rounded,
              showBottomBorder: true,
              showSettings: false,
            );
          },
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
          child: Padding(
            padding: isLandscape
                ? const EdgeInsets.fromLTRB(12, 4, 12, 8)
                : const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLandscape)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildSearchBar(isCompact: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildActionButtons(isCompact: true),
                      ),
                    ],
                  )
                else ...[
                  _buildSearchBar(isCompact: false),
                  const SizedBox(height: 16),
                  _buildActionButtons(isCompact: false),
                ],
              ],
            ),
          ),
        ),
        if (!isLandscape) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSearchBar({required bool isCompact}) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Cari karyawan...',
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: isCompact ? 8 : 14,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: isCompact ? 12 : 20,
        ),
        prefixIconConstraints: isCompact
            ? const BoxConstraints(minWidth: 24, minHeight: 22)
            : null,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding:
            isCompact ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 16),
      ),
      style: TextStyle(fontSize: isCompact ? 8 : 14),
    );
  }

  Widget _buildActionButtons({required bool isCompact}) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final bool isOwner =
            authState is AuthAuthenticated && authState.user.isOwner;

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: isCompact ? 22 : 46,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.tune, size: isCompact ? 10 : 18),
                  label: Text('Filter',
                      style: TextStyle(fontSize: isCompact ? 8 : 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                  ),
                ),
              ),
            ),
            if (isOwner) ...[
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: isCompact ? 22 : 46,
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
                    icon: Icon(Icons.add, size: isCompact ? 10 : 18),
                    label: Text('Tambah',
                        style: TextStyle(fontSize: isCompact ? 8 : 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildKaryawanList(List<Karyawan> karyawanList) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
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
