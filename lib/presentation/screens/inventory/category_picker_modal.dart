import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/category_bloc.dart';
import 'package:bradpos/presentation/blocs/category_state.dart';
import 'package:bradpos/injection_container.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_form_add_metadata_screen.dart';

class PickerModal extends StatefulWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelect;
  final Function(String) onAddNew;

  const PickerModal({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  State<PickerModal> createState() => _PickerModalState();
}

class _PickerModalState extends State<PickerModal> {
  late List<String> currentItems;

  @override
  void initState() {
    super.initState();
    currentItems = List.from(widget.items);
  }

  Widget _buildList(List<String> items, bool isLandscape) {
    if (isLandscape) {
      return GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 2.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildPickerItem(items[index], true),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildPickerItem(items[index], false),
    );
  }

  void _handleAddNew() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => InventoryFormAddMetadataScreen(
            type: widget.title.contains('Kategori') ? 'Kategori' : 'Satuan',
          ),
        ),
      ).then((newName) {
        if (mounted) {
          Navigator.pop(context);
          if (newName != null && newName.isNotEmpty) {
            widget.onAddNew(newName);
          }
        }
      });
      return;
    }

    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(widget.title.replaceFirst('Pilih', 'Tambah')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama baru...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                final val = ctrl.text.trim();
                widget.onAddNew(val);
                setState(() {
                  currentItems.insert(currentItems.length - 1, val);
                  final addButton = currentItems.removeLast();
                  currentItems.sort(
                    (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                  );
                  currentItems.add(addButton);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, isLandscape ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * (isLandscape ? 0.85 : 0.6),
        maxWidth: isLandscape ? MediaQuery.of(context).size.width * 0.75 : double.infinity,
        minWidth: isLandscape ? MediaQuery.of(context).size.width * 0.75 : 0.0,
      ),
      child: SafeArea(
        bottom: !isLandscape,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: isLandscape ? 12 : 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isLandscape)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(50),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            SizedBox(height: isLandscape ? 12 : 24),
            Flexible(
              child: widget.title.contains('Kategori')
                  ? BlocBuilder<CategoryBloc, CategoryState>(
                      bloc: sl<CategoryBloc>(),
                      builder: (context, state) {
                        if (state is CategoryLoaded) {
                          currentItems = (state.categories.map((c) => c.name).toList()
                                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())))
                              ..add('+ Tambah Baru');
                        }
                        return _buildList(currentItems, isLandscape);
                      },
                    )
                  : _buildList(widget.items, isLandscape),
            ),
            if (!isLandscape) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'TUTUP',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickerItem(String label, bool isCompact) {
    final isAdd = label == '+ Tambah Baru';
    return InkWell(
      onTap: () {
        if (isAdd) {
          _handleAddNew();
        } else {
          Navigator.pop(context);
          widget.onSelect(label);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isCompact ? 6 : 16,
        ),
        decoration: BoxDecoration(
          gradient: isAdd
              ? const LinearGradient(
                  colors: [
                    AppColors.primaryGradientStart,
                    AppColors.primaryGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isAdd ? null : const Color(0xFFF8FAFC),
          border: Border.all(
            color: isAdd ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isAdd
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (isAdd)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: isCompact ? 14 : 20,
                  color: Colors.white,
                ),
              ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isAdd ? FontWeight.w800 : FontWeight.w600,
                  fontSize: isCompact ? 10 : 14,
                  color: isAdd ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isAdd)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: isCompact ? 8 : 12,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
