import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/core/models/customer_model.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';

// ─── Pelanggan Card ───────────────────────────────────────────────────────────

class PelangganCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const PelangganCard({
    required this.customer,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool menunggak     = customer.status.toLowerCase() == 'menunggak';
    final Color statusColor  = menunggak ? AppPalette.errorRed   : AppPalette.successGreen;
    final Color statusBg     = menunggak ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final String statusLabel = menunggak ? 'Menunggak' : 'Aktif';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppPalette.bgBluePale,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppPalette.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppPalette.textGreyLight),
                        const SizedBox(width: 3),
                        Text(
                          'RT ${customer.rt}/RW ${customer.rw}',
                          style: const TextStyle(fontSize: 12, color: AppPalette.textGrey),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.home_outlined, size: 13, color: AppPalette.textGreyLight),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            customer.address,
                            style: const TextStyle(fontSize: 12, color: AppPalette.textGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.meterNumber,
                      style: const TextStyle(fontSize: 11, color: AppPalette.textHint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppPalette.textHintLight, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
