import 'package:flutter/material.dart';

class HistoryPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLandscape;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const HistoryPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isLandscape,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 4 : 8,
        horizontal: isLandscape ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
            iconSize: isLandscape ? 16 : 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            'Halaman ${currentPage + 1} dari $totalPages',
            style: TextStyle(fontSize: isLandscape ? 11 : 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            iconSize: isLandscape ? 16 : 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
