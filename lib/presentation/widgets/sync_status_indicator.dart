import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_state.dart';
import 'package:bradpos/presentation/blocs/history/history_bloc.dart';
import 'package:bradpos/presentation/blocs/history/history_state.dart';

class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  bool _showSuccess = false;
  Timer? _timer;

  void _triggerSuccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _showSuccess = true);
      _timer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSuccess = false);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, invState) {
        // Tidak perlu listener di sini jika kita pakai build logic
      },
      builder: (context, invState) {
        return BlocConsumer<HistoryBloc, HistoryState>(
          listener: (context, histState) {
            // Logika deteksi selesai sinkronisasi bisa di sini atau di builder
          },
          builder: (context, histState) {
            bool isInvSyncing = false;
            if (invState is InventoryLoaded) isInvSyncing = invState.isSyncing;

            bool isHistSyncing = false;
            if (histState is HistoryLoaded) isHistSyncing = histState.isSyncing;

            final isCurrentlySyncing = isInvSyncing || isHistSyncing;

            // Efek transisi dari syncing ke success
            return _SyncInnerContent(
              isSyncing: isCurrentlySyncing,
              onSyncFinished: _triggerSuccess,
              showSuccess: _showSuccess,
            );
          },
        );
      },
    );
  }
}

class _SyncInnerContent extends StatefulWidget {
  final bool isSyncing;
  final bool showSuccess;
  final VoidCallback onSyncFinished;

  const _SyncInnerContent({
    required this.isSyncing,
    required this.showSuccess,
    required this.onSyncFinished,
  });

  @override
  State<_SyncInnerContent> createState() => _SyncInnerContentState();
}

class _SyncInnerContentState extends State<_SyncInnerContent> {
  @override
  void didUpdateWidget(_SyncInnerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSyncing && !widget.isSyncing) {
      widget.onSyncFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.isSyncing || widget.showSuccess;

    return Positioned(
      bottom: 80,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: visible ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.showSuccess 
                ? Colors.green.withAlpha(200) 
                : Colors.black.withAlpha(150),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isSyncing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              Icon(
                widget.showSuccess ? Icons.cloud_done : Icons.cloud_queue,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
