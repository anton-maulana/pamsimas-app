import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/pages/customers/pelanggan_screen.dart';
import 'package:pamsimas_app/src/pages/laporan/laporan_screen.dart';
import 'package:pamsimas_app/src/pages/meter/catat_meter_screen.dart';
import 'package:pamsimas_app/src/pages/petugas/petugas_screen.dart';
import 'package:pamsimas_app/src/pages/tagihan/tagihan_screen.dart';
import 'package:pamsimas_app/src/core/services/bill_service.dart';
import 'package:pamsimas_app/src/core/services/payment_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color bgGrey = Color(0xFFF2F4F7);
  static const Color cardWhite = Colors.white;

  int _totalCustomers = 0;
  int _unbilledCount = 0;
  int _unpaidCount = 0;
  int _paidCount = 0;
  double _totalIncome = 0.0;
  double _totalAmountBilled = 0.0;
  double _totalAmountCollected = 0.0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final now = DateTime.now();
      final stats = await BillService.instance.getStatsSummary(month: now.month, year: now.year);
      final income = await PaymentService.instance.getTotalIncome(month: now.month, year: now.year);
      if (mounted) {
        setState(() {
          _totalCustomers = stats['total_customers'] as int? ?? 0;
          _unbilledCount = stats['unbilled_count'] as int? ?? 0;
          _unpaidCount = stats['unpaid_count'] as int? ?? 0;
          _paidCount = stats['paid_count'] as int? ?? 0;
          _totalAmountBilled = (stats['total_amount_billed'] as num?)?.toDouble() ?? 0.0;
          _totalAmountCollected = (stats['total_amount_collected'] as num?)?.toDouble() ?? 0.0;
          _totalIncome = income;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  String _formatRp(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSummaryCard(),
                const SizedBox(height: 28),
                _buildMenuGrid(context),
                const SizedBox(height: 28),
                _buildInfoSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Halo, Petugas 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Selamat datang di PAMSIMAS',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: primaryBlue,
          child: const Icon(Icons.person, color: Colors.white, size: 26),
        ),
      ],
    );
  }

  // ─── Summary Card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    double lunasPercent = 0.0;
    if (_totalAmountBilled > 0) {
       lunasPercent = (_totalAmountCollected / _totalAmountBilled) * 100;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildSummaryItem(Icons.payments_outlined, 'Penagihan', _loadingStats ? '...' : '${lunasPercent.toStringAsFixed(0)}% Masuk')),
          Container(width: 1, height: 60, color: Colors.white.withOpacity(0.4)),
          Expanded(child: _buildSummaryItem(Icons.account_balance_wallet_outlined, 'Uang Masuk', _loadingStats ? '...' : _formatRp(_totalIncome.toInt()))),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ─── Menu Grid ─────────────────────────────────────────────────────────────
  Widget _buildMenuGrid(BuildContext context) {
    final List<_MenuItem> items = [
      _MenuItem(icon: Icons.people_alt_outlined,   label: 'Pelanggan',  color: const Color(0xFF1565C0)),
      _MenuItem(icon: Icons.speed_outlined,         label: 'Catat Meter', color: const Color(0xFF00897B)),
      _MenuItem(icon: Icons.receipt_long_outlined,  label: 'Tagihan',    color: const Color(0xFFE65100)),
      _MenuItem(icon: Icons.bar_chart_outlined,     label: 'Laporan',    color: const Color(0xFF6A1B9A)),
      _MenuItem(icon: Icons.badge_outlined,         label: 'Petugas',    color: const Color(0xFF283593)),
      _MenuItem(icon: Icons.warning_amber_rounded,  label: 'Anomali',    color: const Color(0xFFC62828)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Utama',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, i) => _buildMenuCard(context, items[i]),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuItem item) {
    return Material(
      color: cardWhite,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: () => _handleMenuTap(context, item.label),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuTap(BuildContext context, String label) {
    if (label == 'Pelanggan') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PelangganScreen()),
      ).then((_) => _fetchStats());
    } else if (label == 'Catat Meter') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CatatMeterScreen()),
      ).then((_) => _fetchStats());
    } else if (label == 'Tagihan') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TagihanScreen()),
      ).then((_) => _fetchStats());
    } else if (label == 'Laporan') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LaporanScreen()),
      ).then((_) => _fetchStats());
    } else if (label == 'Petugas') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PetugasScreen()),
      ).then((_) => _fetchStats());
    }
  }

  // ─── Info Section ──────────────────────────────────────────────────────────
  Widget _buildInfoSection() {
    final now = DateTime.now();
    const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progres Pencatatan (${months[now.month]} ${now.year})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.pending_actions_outlined, 
            'Belum Dicatat Meter', 
            _loadingStats ? '...' : '$_unbilledCount pelanggan', 
            const Color(0xFFE65100),
            onTap: () {
               Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PelangganScreen(filterUnbilledOnly: true)),
               ).then((_) => _fetchStats());
            }
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.cancel_outlined, 'Belum Lunas / Bayar Sebagian', _loadingStats ? '...' : '$_unpaidCount pelanggan', const Color(0xFFC62828)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.check_circle_outline, 'Lunas Bulan Ini', _loadingStats ? '...' : '$_paidCount pelanggan', const Color(0xFF2E7D32)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _totalCustomers > 0 ? (_totalCustomers - _unbilledCount) / _totalCustomers : 0,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00897B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (onTap != null) ...[
               const SizedBox(width: 4),
               Icon(Icons.chevron_right, size: 16, color: color),
            ]
          ],
        ),
      ),
    );
  }
}

// ─── Data Model ──────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItem({required this.icon, required this.label, required this.color});
}
