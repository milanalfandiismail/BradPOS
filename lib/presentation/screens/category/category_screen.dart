import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/domain/entities/category.dart';
import 'package:bradpos/presentation/blocs/category_bloc.dart';
import 'package:bradpos/presentation/blocs/category_event.dart';
import 'package:bradpos/presentation/blocs/category_state.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/settings_modal.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/screens/category/category_form_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    sl<CategoryBloc>().add(LoadCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<CategoryBloc>(),
      child: BlocListener<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.primary,
              ),
            );
          } else if (state is CategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => BradHeader(
                    title: 'Kelola Kategori',
                    subtitle: state.displayShopName,
                      showBackButton: true,
                      leadingIcon: Icons.category_rounded,
                      showBottomBorder: true,
                      onSettingsTap: () => SettingsModal.show(context),
                      onSyncTap: () {
                        context.read<AuthBloc>().syncService.syncAll();
                        context.read<CategoryBloc>().add(LoadCategoriesEvent());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menyingkronkan data...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: BlocBuilder<CategoryBloc, CategoryState>(
                    bloc: sl<CategoryBloc>(),
                    builder: (context, state) {
                      if (state is CategoryLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<Category> categories = [];
                      if (state is CategoryLoaded) {
                        categories = state.categories;
                      }

                      bool isLandscape =
                          MediaQuery.of(context).orientation ==
                          Orientation.landscape;

                      if (categories.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.category_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Belum ada kategori',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return isLandscape
                          ? GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return _buildCategoryItem(
                                  category,
                                  isCompact: true,
                                );
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: categories.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return _buildCategoryItem(
                                  category,
                                  isCompact: false,
                                );
                              },
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToForm(),
            label: const Text(
              'Tambah Kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.add),
            backgroundColor: const Color(0xFF065F46),
            foregroundColor: Colors.white,
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category category, {required bool isCompact}) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.blue,
                    size: 18,
                  ),
                  onPressed: () => _navigateToForm(category: category),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                  onPressed: () => _confirmDelete(category),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.category, color: AppColors.primary, size: 20),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.blue,
                size: 22,
              ),
              onPressed: () => _navigateToForm(category: category),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 22,
              ),
              onPressed: () => _confirmDelete(category),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToForm({Category? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: sl<CategoryBloc>(),
          child: CategoryFormScreen(category: category),
        ),
      ),
    );
  }

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kategori'),
        content: Text(
          'Hapus kategori "${category.name}"?\nProduk di dalamnya akan menjadi "Tanpa Kategori".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              sl<CategoryBloc>().add(
                DeleteCategoryEvent(category.id, category.name),
              );
              Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('HAPUS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

