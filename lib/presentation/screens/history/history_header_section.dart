import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/settings_modal.dart';

class HistoryHeaderSection extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final bool isLandscape;
  final VoidCallback onFilterTap;
  final VoidCallback onSyncTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const HistoryHeaderSection({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.isLandscape,
    required this.onFilterTap,
    required this.onSyncTap,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => BradHeader(
            title: 'Riwayat Transaksi',
            subtitle: state.displayShopName,
            leadingIcon: Icons.history_rounded,
            showBottomBorder: true,
            showSettings: !isLandscape,
            onSettingsTap: () => SettingsModal.show(context),
            onSyncTap: () {
              context.read<AuthBloc>().syncService.syncAll();
              onSyncTap();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menyingkronkan data...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            actions: isLandscape
                ? [
                    IconButton(
                      icon: const Icon(
                        Icons.sync_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      onPressed: onSyncTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ]
                : null,
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: isLandscape
                    ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
                    : const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: isLandscape ? 48 : 56,
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          controller: searchController,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari nomor transaksi...',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                            prefixIconConstraints: isLandscape
                                ? const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 48,
                                  )
                                : null,
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    onPressed: onClearSearch,
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isLandscape ? 12 : 16,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isLandscape ? 12 : 16,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isLandscape ? 12 : 16,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            isDense: isLandscape,
                            contentPadding: isLandscape
                                ? const EdgeInsets.symmetric(horizontal: 12)
                                : const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onChanged: onSearchChanged,
                        ),
                      ),
                    ),
                    SizedBox(width: isLandscape ? 6 : 8),
                    if (isLandscape)
                      SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: onFilterTap,
                          icon: const Icon(Icons.tune, size: 18),
                          label: const Text('Filter',
                              style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.white,
                            visualDensity: VisualDensity.comfortable,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 56,
                        child: Material(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: onFilterTap,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune,
                                    color: Color(0xFF64748B),
                                    size: 24,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Filter',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
