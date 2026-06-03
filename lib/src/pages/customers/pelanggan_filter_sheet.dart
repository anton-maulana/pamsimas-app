import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';

// ─── Pelanggan Filter Sheet ───────────────────────────────────────────────────

void showPelangganFilterSheet({
  required BuildContext context,
  required String filterRt,
  required String filterRw,
  required String filterStatus,
  required List<String> rtOptions,
  required List<String> rwOptions,
  required List<String> statusOptions,
  required ValueChanged<String> onRtChanged,
  required ValueChanged<String> onRwChanged,
  required ValueChanged<String> onStatusChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppPalette.textHintLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // RT filter
                const Text(
                  'Filter RT',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rtOptions.map((opt) {
                    final active = filterRt == opt;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {});
                        onRtChanged(opt);
                      },
                      child: _FilterChip(label: opt, active: active),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // RW filter
                const Text(
                  'Filter RW',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rwOptions.map((opt) {
                    final active = filterRw == opt;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {});
                        onRwChanged(opt);
                      },
                      child: _FilterChip(label: opt, active: active),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Status filter
                const Text(
                  'Filter Status',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: statusOptions.map((opt) {
                    final active = filterStatus == opt;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {});
                        onStatusChanged(opt);
                      },
                      child: _FilterChip(label: opt, active: active),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ─── Internal chip widget ─────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;

  const _FilterChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppPalette.primaryBlue : AppPalette.bgGreyLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: active ? Colors.white : AppPalette.textLabel,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
