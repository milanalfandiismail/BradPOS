import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';

class FilterSectionTitle extends StatelessWidget {
  final String title;
  final bool isCompact;

  const FilterSectionTitle({
    super.key,
    required this.title,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: isCompact ? 12 : 15,
        color: const Color(0xFF475569),
      ),
    );
  }
}

class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCompact;
  final Function(bool) onSelected;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: isCompact ? 11 : 13,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF065F46),
      backgroundColor: Colors.white,
      showCheckmark: false,
      elevation: 0,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8),
      visualDensity: isCompact
          ? const VisualDensity(horizontal: -4, vertical: -4)
          : const VisualDensity(horizontal: -2, vertical: -2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF065F46) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class InventoryFilterContent extends StatelessWidget {
  final String selectedCategory;
  final String stockFilter;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onStockFilterChanged;
  final VoidCallback onApply;
  final List<String> categories;
  final bool isCompact;

  const InventoryFilterContent({
    super.key,
    required this.selectedCategory,
    required this.stockFilter,
    required this.onCategoryChanged,
    required this.onStockFilterChanged,
    required this.onApply,
    this.categories = const ['All', 'Tanpa Kategori', 'Makanan', 'Minuman'],
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cats = categories;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Produk',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  if (isCompact)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    ),
                  TextButton(
                    onPressed: () {
                      onCategoryChanged('All');
                      onStockFilterChanged('All');
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 24),
          FilterSectionTitle(
            title: 'Kategori Produk',
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 8 : 12),
          Wrap(
            spacing: isCompact ? 6 : 8,
            runSpacing: isCompact ? 6 : 8,
            children: cats.map((c) {
              final isSel = selectedCategory == c;
              return CustomFilterChip(
                label: c,
                isSelected: isSel,
                isCompact: isCompact,
                onSelected: (val) => onCategoryChanged(c),
              );
            }).toList(),
          ),
          SizedBox(height: isCompact ? 12 : 24),
          FilterSectionTitle(
            title: 'Status Stok',
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 8 : 12),
          Wrap(
            spacing: isCompact ? 6 : 8,
            runSpacing: isCompact ? 6 : 8,
            children: ['All', 'Low Stock', 'Out of Stock', 'Unlimited'].map((
              s,
            ) {
              final isSel = stockFilter == s;
              return CustomFilterChip(
                label: s,
                isSelected: isSel,
                isCompact: isCompact,
                onSelected: (val) => onStockFilterChanged(s),
              );
            }).toList(),
          ),
          SizedBox(height: isCompact ? 16 : 32),
          SizedBox(
            width: double.infinity,
            height: isCompact ? 40 : 56,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 10 : 16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Terapkan Filter',
                style: TextStyle(
                  fontSize: isCompact ? 13 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
