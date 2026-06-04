import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/core/models/customer_model.dart';
import 'package:pamsimas_app/src/core/services/customers_service.dart';
import 'package:pamsimas_app/src/pages/customers/tambah_pelanggan_screen.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';

// ─── Detail Screen ────────────────────────────────────────────────────────────

class PelangganDetailScreen extends StatefulWidget {
  final Customer customer;

  const PelangganDetailScreen({required this.customer, super.key});

  @override
  State<PelangganDetailScreen> createState() => _PelangganDetailScreenState();
}

class _PelangganDetailScreenState extends State<PelangganDetailScreen> {
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pelanggan?'),
        content: Text(
          'Data "${widget.customer.name}" akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await CustomersService.instance.delete(widget.customer.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menghapus. Periksa koneksi internet.'),
          backgroundColor: AppPalette.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool menunggak    = widget.customer.status.toLowerCase() == 'menunggak';
    final Color statusColor = menunggak ? AppPalette.errorRed   : AppPalette.successGreen;
    final Color statusBg    = menunggak ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);

    return Scaffold(
      backgroundColor: AppPalette.bgGrey,
      appBar: AppBar(
        backgroundColor: AppPalette.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detail Pelanggan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: _isDeleting
                ? null
                : () async {
                    final refresh = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TambahPelangganScreen(
                          customer: widget.customer,
                        ),
                      ),
                    );
                    if (refresh == true && mounted) Navigator.of(context).pop(true);
                  },
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: _isDeleting ? null : _confirmDelete,
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppPalette.bgBluePale,
                    child: Icon(Icons.person_rounded, size: 40, color: AppPalette.primaryBlue),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.customer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Meter ID: ${widget.customer.meterNumber}',
                    style: const TextStyle(fontSize: 13, color: AppPalette.textGreyLight),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      menunggak ? 'Menunggak' : 'Aktif',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Info rows
            _InfoCard(
              rows: [
                _InfoRow(icon: Icons.location_on_outlined, label: 'RT',     value: widget.customer.rt.toString()),
                _InfoRow(icon: Icons.location_city_outlined, label: 'RW',    value: widget.customer.rw.toString()),
                _InfoRow(icon: Icons.home_outlined,         label: 'Alamat',  value: widget.customer.address),
                if (widget.customer.phoneNumber.isNotEmpty)
                  _InfoRow(icon: Icons.phone_outlined,      label: 'No. HP',  value: widget.customer.phoneNumber),
                if (widget.customer.officerId != null)
                  _InfoRow(icon: Icons.badge_outlined,      label: 'Petugas', value: 'ID: ${widget.customer.officerId}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: rows
            .map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(r.icon, color: AppPalette.primaryBlue, size: 20),
                    const SizedBox(width: 14),
                    Text(r.label, style: const TextStyle(fontSize: 13, color: AppPalette.textGrey)),
                    const Spacer(),
                    Text(
                      r.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});
}
