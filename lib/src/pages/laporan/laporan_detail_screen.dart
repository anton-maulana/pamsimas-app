import 'dart:math' as math;
import 'package:flutter/material.dart';

class LaporanDetailScreen extends StatelessWidget {
  const LaporanDetailScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.type,
    required this.period,
    required this.wilayah,
    required this.petugas,
  }) : super(key: key);

  final String   title;
  final String   subtitle;
  final IconData icon;
  final Color    color;
  final String   type;
  final String   period;
  final String   wilayah;
  final String   petugas;

  static const Color _bgGrey = Color(0xFFF2F4F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          _PeriodHeader(
            color: color,
            period: period,
            wilayah: wilayah,
            petugas: petugas,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (type) {
      case 'penggunaan_air':
        return _PenggunaanAirContent(accentColor: color);
      case 'keuangan':
        return _KeuanganContent(accentColor: color);
      case 'tagihan':
        return _TagihanContent(accentColor: color);
      case 'anomali':
        return _AnomalyContent(accentColor: color);
      case 'petugas':
        return _PetugasContent(accentColor: color);
      case 'wilayah':
        return _WilayahContent(accentColor: color);
      default:
        return const Center(child: Text('Konten tidak tersedia'));
    }
  }
}

// ─── Period Header ─────────────────────────────────────────────────────────────

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({
    required this.color,
    required this.period,
    required this.wilayah,
    required this.petugas,
  });

  final Color  color;
  final String period;
  final String wilayah;
  final String petugas;

  @override
  Widget build(BuildContext context) {
    final badges = <_BadgeData>[
      _BadgeData(Icons.calendar_month_outlined, period),
      if (wilayah != 'Semua') _BadgeData(Icons.location_on_outlined, wilayah),
      if (petugas != 'Semua') _BadgeData(Icons.badge_outlined, petugas),
    ];

    return Container(
      color: color,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: badges.map((b) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(b.icon, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(b.label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BadgeData {
  final IconData icon;
  final String   label;
  const _BadgeData(this.icon, this.label);
}

// ─── Shared Helpers ────────────────────────────────────────────────────────────

String _formatRp(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp ${buf.toString()}';
}

Widget _card({required Widget child, EdgeInsets? padding}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: padding ?? const EdgeInsets.all(16),
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
    child: child,
  );
}

Widget _sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: Color(0xFF6B7280),
      ),
    ),
  );
}

Widget _statCard({
  required String   label,
  required String   value,
  required IconData icon,
  required Color    color,
  String?           sub,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub,
                style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
          ],
        ],
      ),
    ),
  );
}

// ─── 1. Penggunaan Air ─────────────────────────────────────────────────────────

class _PenggunaanAirContent extends StatelessWidget {
  const _PenggunaanAirContent({required this.accentColor});
  final Color accentColor;

  static const _usageData = [
    _UsageEntry('Ahmad Suryadi',   '01', '02', 15),
    _UsageEntry('Siti Rahayu',     '02', '01', 22),
    _UsageEntry('Budi Santoso',    '03', '02', 10),
    _UsageEntry('Dewi Lestari',    '01', '03', 30),
    _UsageEntry('Eko Prasetyo',    '04', '01', 18),
    _UsageEntry('Fitri Handayani', '02', '03',  8),
    _UsageEntry('Hendra Gunawan',  '03', '01', 25),
    _UsageEntry('Ika Widiastuti',  '01', '01', 12),
  ];

  static const List<double> _chartValues = [85, 102, 78, 140, 110, 95, 128, 120, 135, 98, 115, 140];
  static const List<String> _chartLabels = ['Jun','Jul','Agu','Sep','Okt','Nov','Des','Jan','Feb','Mar','Apr','Mei'];

  int get _total   => _usageData.fold(0, (s, e) => s + e.usage);
  double get _avg  => _total / _usageData.length;
  _UsageEntry get _highest => _usageData.reduce((a, b) => a.usage > b.usage ? a : b);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            _statCard(
              label: 'Total Pemakaian',
              value: '$_total m³',
              icon: Icons.water_drop_outlined,
              color: accentColor,
            ),
            const SizedBox(width: 10),
            _statCard(
              label: 'Rata-rata',
              value: '${_avg.toStringAsFixed(1)} m³',
              icon: Icons.analytics_outlined,
              color: const Color(0xFF00897B),
            ),
            const SizedBox(width: 10),
            _statCard(
              label: 'Tertinggi',
              value: '${_highest.usage} m³',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFE65100),
              sub: _highest.nama.split(' ').first,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionLabel('Tren Pemakaian (12 Bulan)'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pemakaian Air (m³)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              const Text('12 bulan terakhir',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: _LineChart(values: _chartValues, labels: _chartLabels, color: accentColor),
              ),
            ],
          ),
        ),
        _sectionLabel('Pemakaian per Pelanggan'),
        ..._usageData.map((e) => _buildUsageRow(e)),
      ],
    );
  }

  Widget _buildUsageRow(_UsageEntry e) {
    final ratio = e.usage / _highest.usage;
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.nama,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text('RT ${e.rt}/RW ${e.rw}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Text('${e.usage} m³',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageEntry {
  final String nama;
  final String rt;
  final String rw;
  final int    usage;
  const _UsageEntry(this.nama, this.rt, this.rw, this.usage);
}

// ─── 2. Keuangan ──────────────────────────────────────────────────────────────

class _KeuanganContent extends StatelessWidget {
  const _KeuanganContent({required this.accentColor});
  final Color accentColor;

  static const List<double> _barValues = [3200000, 4100000, 3800000, 4500000, 4200000, 5000000, 4700000, 5100000, 4800000, 5300000, 4900000, 5000000];
  static const List<String> _barLabels = ['Jun','Jul','Agu','Sep','Okt','Nov','Des','Jan','Feb','Mar','Apr','Mei'];

  static const int _totalPendapatan = 5000000;
  static const int _totalBulanLalu  = 4900000;
  static const int _totalTunggakan  = 1820000;

  double get _growth => ((_totalPendapatan - _totalBulanLalu) / _totalBulanLalu) * 100;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            _statCard(
              label: 'Total Pendapatan',
              value: _formatRp(_totalPendapatan),
              icon: Icons.account_balance_outlined,
              color: accentColor,
            ),
            const SizedBox(width: 10),
            _statCard(
              label: 'Pertumbuhan',
              value: '${_growth >= 0 ? '+' : ''}${_growth.toStringAsFixed(1)}%',
              icon: _growth >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: _growth >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              sub: 'vs bulan lalu',
            ),
            const SizedBox(width: 10),
            _statCard(
              label: 'Tunggakan',
              value: _formatRp(_totalTunggakan),
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFE65100),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionLabel('Pendapatan Bulanan'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tren Pendapatan (Rp)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              const Text('12 bulan terakhir',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: _BarChart(values: _barValues, labels: _barLabels, color: accentColor),
              ),
            ],
          ),
        ),
        _sectionLabel('Rincian Keuangan'),
        _buildFinanceDetail(),
      ],
    );
  }

  Widget _buildFinanceDetail() {
    final rows = [
      _FinRow('Tagihan Terbit',    5000000, true),
      _FinRow('Sudah Dibayar',     3180000, true),
      _FinRow('Belum Dibayar',     1820000, false),
      _FinRow('Biaya Operasional',  650000, false),
    ];
    return _card(
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final r = e.value;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.label, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                  Text(
                    _formatRp(r.amount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: r.isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 10),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _FinRow {
  final String label;
  final int    amount;
  final bool   isPositive;
  const _FinRow(this.label, this.amount, this.isPositive);
}

// ─── 3. Tagihan ───────────────────────────────────────────────────────────────

class _TagihanContent extends StatelessWidget {
  const _TagihanContent({required this.accentColor});
  final Color accentColor;

  static const _daftarTagihan = [
    _TagihanEntry('Siti Rahayu',     '02', '01', 77000,  false),
    _TagihanEntry('Dewi Lestari',    '01', '03', 105000, false),
    _TagihanEntry('Fitri Handayani', '02', '03', 28000,  false),
    _TagihanEntry('Ika Widiastuti',  '01', '01', 42000,  false),
    _TagihanEntry('Ahmad Suryadi',   '01', '02', 52500,  true),
    _TagihanEntry('Budi Santoso',    '03', '02', 35000,  true),
    _TagihanEntry('Eko Prasetyo',    '04', '01', 63000,  true),
    _TagihanEntry('Hendra Gunawan',  '03', '01', 87500,  true),
  ];

  int get _total  => _daftarTagihan.fold(0, (s, e) => s + e.tagihan);
  int get _lunas  => _daftarTagihan.where((e) => e.lunas).fold(0, (s, e) => s + e.tagihan);
  int get _belum  => _daftarTagihan.where((e) => !e.lunas).fold(0, (s, e) => s + e.tagihan);
  int get _cLunas => _daftarTagihan.where((e) => e.lunas).length;
  int get _cBelum => _daftarTagihan.where((e) => !e.lunas).length;
  double get _lunasRatio => _total == 0 ? 0 : _lunas / _total;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(children: [
          _statCard(
            label: 'Total Tagihan',
            value: _formatRp(_total),
            icon: Icons.receipt_long_outlined,
            color: accentColor,
          ),
        ]),
        const SizedBox(height: 10),
        Row(
          children: [
            _statCard(
              label: 'Lunas',
              value: _formatRp(_lunas),
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF2E7D32),
              sub: '$_cLunas pelanggan',
            ),
            const SizedBox(width: 10),
            _statCard(
              label: 'Belum Bayar',
              value: _formatRp(_belum),
              icon: Icons.cancel_rounded,
              color: const Color(0xFFC62828),
              sub: '$_cBelum pelanggan',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tingkat Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
                  Text('${(_lunasRatio * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: accentColor)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _lunasRatio,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFFEE2E2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _dot(const Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  const Text('Lunas', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(width: 16),
                  _dot(const Color(0xFFFEE2E2)),
                  const SizedBox(width: 6),
                  const Text('Belum Bayar', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ],
          ),
        ),
        _sectionLabel('Pelanggan Belum Bayar'),
        ..._daftarTagihan.where((e) => !e.lunas).map((e) => _buildTagihanRow(e, false)),
        _sectionLabel('Pelanggan Sudah Lunas'),
        ..._daftarTagihan.where((e) => e.lunas).map((e) => _buildTagihanRow(e, true)),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _buildTagihanRow(_TagihanEntry e, bool isLunas) {
    const green = Color(0xFF2E7D32);
    const red   = Color(0xFFC62828);
    final statusColor = isLunas ? green : red;
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isLunas ? Icons.check_circle_rounded : Icons.cancel_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text('RT ${e.rt}/RW ${e.rw}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatRp(e.tagihan),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: statusColor)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(isLunas ? 'Lunas' : 'Belum Bayar',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagihanEntry {
  final String nama;
  final String rt;
  final String rw;
  final int    tagihan;
  final bool   lunas;
  const _TagihanEntry(this.nama, this.rt, this.rw, this.tagihan, this.lunas);
}

// ─── 4. Anomali ───────────────────────────────────────────────────────────────

class _AnomalyContent extends StatelessWidget {
  const _AnomalyContent({required this.accentColor});
  final Color accentColor;

  static const _anomalies = [
    _AnomalyEntry('Siti Rahayu',     '02', '01', 22, _AnomalyType.lonjakan,    'Naik 120% dari bulan lalu'),
    _AnomalyEntry('Budi Santoso',    '03', '02',  0, _AnomalyType.nolM3,       'Tidak ada pemakaian terdeteksi'),
    _AnomalyEntry('Dewi Lestari',    '01', '03', 30, _AnomalyType.lonjakan,    'Melebihi batas wajar 25 m³'),
    _AnomalyEntry('Hendra Gunawan',  '03', '01',  0, _AnomalyType.nolM3,       'Pemakaian nol selama 2 bulan'),
    _AnomalyEntry('Fitri Handayani', '02', '03',  8, _AnomalyType.sangatRendah,'Pemakaian sangat rendah'),
  ];

  @override
  Widget build(BuildContext context) {
    final nol      = _anomalies.where((e) => e.type == _AnomalyType.nolM3).toList();
    final lonjakan = _anomalies.where((e) => e.type == _AnomalyType.lonjakan).toList();
    final rendah   = _anomalies.where((e) => e.type == _AnomalyType.sangatRendah).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            _statCard(label: 'Total Anomali', value: '${_anomalies.length}', icon: Icons.warning_amber_rounded, color: accentColor),
            const SizedBox(width: 10),
            _statCard(label: 'Pemakaian Nol', value: '${nol.length}',        icon: Icons.block_rounded,         color: const Color(0xFF6B7280)),
            const SizedBox(width: 10),
            _statCard(label: 'Lonjakan',       value: '${lonjakan.length}',  icon: Icons.trending_up_rounded,   color: const Color(0xFFC62828)),
          ],
        ),
        const SizedBox(height: 16),
        if (nol.isNotEmpty) ...[
          _sectionLabel('Pemakaian Nol (${nol.length})'),
          ...nol.map(_buildAnomalyCard),
        ],
        if (lonjakan.isNotEmpty) ...[
          _sectionLabel('Lonjakan Tinggi (${lonjakan.length})'),
          ...lonjakan.map(_buildAnomalyCard),
        ],
        if (rendah.isNotEmpty) ...[
          _sectionLabel('Pemakaian Sangat Rendah (${rendah.length})'),
          ...rendah.map(_buildAnomalyCard),
        ],
      ],
    );
  }

  Widget _buildAnomalyCard(_AnomalyEntry e) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    switch (e.type) {
      case _AnomalyType.nolM3:
        typeColor = const Color(0xFF6B7280); typeIcon = Icons.block_rounded;         typeLabel = 'Pemakaian Nol';   break;
      case _AnomalyType.lonjakan:
        typeColor = const Color(0xFFC62828); typeIcon = Icons.trending_up_rounded;   typeLabel = 'Lonjakan';        break;
      case _AnomalyType.sangatRendah:
        typeColor = const Color(0xFFE65100); typeIcon = Icons.trending_down_rounded; typeLabel = 'Sangat Rendah';   break;
    }
    return _card(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(e.nama,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
                    ),
                    Text('${e.usage} m³',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: typeColor)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('RT ${e.rt}/RW ${e.rw}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 12, color: typeColor),
                      const SizedBox(width: 5),
                      Flexible(child: Text(e.note, style: TextStyle(fontSize: 11, color: typeColor))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(typeLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _AnomalyType { nolM3, lonjakan, sangatRendah }

class _AnomalyEntry {
  final String       nama;
  final String       rt;
  final String       rw;
  final int          usage;
  final _AnomalyType type;
  final String       note;
  const _AnomalyEntry(this.nama, this.rt, this.rw, this.usage, this.type, this.note);
}

// ─── 5. Petugas ───────────────────────────────────────────────────────────────

class _PetugasContent extends StatelessWidget {
  const _PetugasContent({required this.accentColor});
  final Color accentColor;

  static const _staff = [
    _StaffEntry('Budi Santoso',    3, 115500, 2),
    _StaffEntry('Dewi Lestari',    2, 140000, 1),
    _StaffEntry('Eko Prasetyo',    2, 150500, 0),
    _StaffEntry('Fitri Handayani', 1,  42000, 1),
  ];

  int get _totalPelanggan => _staff.fold(0, (s, e) => s + e.jumlahPelanggan);
  int get _totalTagihan   => _staff.fold(0, (s, e) => s + e.totalTagihan);
  int get _maxTagihan     => _staff.map((e) => e.totalTagihan).reduce(math.max);

  @override
  Widget build(BuildContext context) {
    final ranked = [..._staff]..sort((a, b) => b.totalTagihan.compareTo(a.totalTagihan));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            _statCard(label: 'Total Petugas',    value: '${_staff.length}',      icon: Icons.badge_outlined,       color: accentColor),
            const SizedBox(width: 10),
            _statCard(label: 'Total Pelanggan',  value: '$_totalPelanggan',       icon: Icons.people_alt_outlined,  color: const Color(0xFF00897B)),
            const SizedBox(width: 10),
            _statCard(label: 'Total Tagihan',    value: _formatRp(_totalTagihan), icon: Icons.receipt_long_outlined, color: const Color(0xFF2E7D32)),
          ],
        ),
        const SizedBox(height: 16),
        _sectionLabel('Ranking Kinerja'),
        ...ranked.asMap().entries.map((entry) => _buildStaffCard(entry.value, entry.key + 1)),
      ],
    );
  }

  Widget _buildStaffCard(_StaffEntry e, int rank) {
    final ratio = e.totalTagihan / _maxTagihan;
    Color rankColor;
    if (rank == 1)      rankColor = const Color(0xFFCA8A04);
    else if (rank == 2) rankColor = const Color(0xFF6B7280);
    else if (rank == 3) rankColor = const Color(0xFF92400E);
    else                rankColor = accentColor.withOpacity(0.6);

    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: rankColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Center(
                  child: Text('#$rank',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rankColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.nama,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text('${e.jumlahPelanggan} pelanggan ditagih',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatRp(e.totalTagihan),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: accentColor)),
                  const SizedBox(height: 2),
                  Text('${e.belumBayar} belum bayar',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFC62828))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(rankColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffEntry {
  final String nama;
  final int    jumlahPelanggan;
  final int    totalTagihan;
  final int    belumBayar;
  const _StaffEntry(this.nama, this.jumlahPelanggan, this.totalTagihan, this.belumBayar);
}

// ─── 6. Wilayah ───────────────────────────────────────────────────────────────

class _WilayahContent extends StatelessWidget {
  const _WilayahContent({required this.accentColor});
  final Color accentColor;

  static const _areas = [
    _AreaEntry('RT 01/RW 01', 2, 27,  94500),
    _AreaEntry('RT 01/RW 02', 2, 37, 130000),
    _AreaEntry('RT 01/RW 03', 2, 40, 140000),
    _AreaEntry('RT 02/RW 01', 2, 30, 105000),
    _AreaEntry('RT 02/RW 03', 2, 16,  56000),
    _AreaEntry('RT 03/RW 01', 2, 35, 122500),
    _AreaEntry('RT 03/RW 02', 2, 25,  87500),
    _AreaEntry('RT 04/RW 01', 2, 30, 105000),
  ];

  int get _totalPelanggan  => _areas.fold(0, (s, e) => s + e.jumlahPelanggan);
  int get _totalPemakaian  => _areas.fold(0, (s, e) => s + e.pemakaian);
  int get _totalPendapatan => _areas.fold(0, (s, e) => s + e.pendapatan);
  int get _maxPemakaian    => _areas.map((e) => e.pemakaian).reduce(math.max);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            _statCard(label: 'Total Wilayah',   value: '${_areas.length} RT',   icon: Icons.map_outlined,           color: accentColor),
            const SizedBox(width: 10),
            _statCard(label: 'Total Pemakaian', value: '$_totalPemakaian m³',   icon: Icons.water_drop_outlined,    color: const Color(0xFF1565C0)),
            const SizedBox(width: 10),
            _statCard(label: 'Pendapatan',       value: _formatRp(_totalPendapatan), icon: Icons.account_balance_outlined, color: const Color(0xFF2E7D32)),
          ],
        ),
        const SizedBox(height: 16),
        _sectionLabel('Statistik per RT/RW'),
        ..._areas.map(_buildAreaCard),
      ],
    );
  }

  Widget _buildAreaCard(_AreaEntry e) {
    final ratio = e.pemakaian / _maxPemakaian;
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(e.wilayah,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor)),
              ),
              const Spacer(),
              Text(_formatRp(e.pendapatan),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(Icons.people_alt_outlined, '${e.jumlahPelanggan} pelanggan', const Color(0xFF374151)),
              const SizedBox(width: 16),
              _miniStat(Icons.water_drop_outlined, '${e.pemakaian} m³', const Color(0xFF1565C0)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _AreaEntry {
  final String wilayah;
  final int    jumlahPelanggan;
  final int    pemakaian;
  final int    pendapatan;
  const _AreaEntry(this.wilayah, this.jumlahPelanggan, this.pemakaian, this.pendapatan);
}

// ─── Charts ───────────────────────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  const _LineChart({required this.values, required this.labels, required this.color});
  final List<double> values;
  final List<String> labels;
  final Color        color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _LineChartPainter(values: values, labels: labels, color: color));
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.values, required this.labels, required this.color});
  final List<double> values;
  final List<String> labels;
  final Color        color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const double labelH = 24;
    const double topPad = 8;
    final double chartH = size.height - labelH - topPad;
    final double chartW = size.width;
    final double minV   = values.reduce(math.min);
    final double maxV   = values.reduce(math.max);
    final double range  = (maxV - minV) == 0 ? 1 : maxV - minV;

    double xOf(int i) => i * chartW / (values.length - 1);
    double yOf(double v) => topPad + chartH - ((v - minV) / range) * chartH * 0.85;

    // Gradient fill
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, topPad, chartW, chartH));

    final fillPath = Path()
      ..moveTo(xOf(0), chartH + topPad)
      ..lineTo(xOf(0), yOf(values[0]));
    for (var i = 1; i < values.length; i++) {
      final cpX = (xOf(i - 1) + xOf(i)) / 2;
      fillPath.cubicTo(cpX, yOf(values[i - 1]), cpX, yOf(values[i]), xOf(i), yOf(values[i]));
    }
    fillPath
      ..lineTo(xOf(values.length - 1), chartH + topPad)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final linePath = Path()..moveTo(xOf(0), yOf(values[0]));
    for (var i = 1; i < values.length; i++) {
      final cpX = (xOf(i - 1) + xOf(i)) / 2;
      linePath.cubicTo(cpX, yOf(values[i - 1]), cpX, yOf(values[i]), xOf(i), yOf(values[i]));
    }
    canvas.drawPath(linePath, linePaint);

    // Dots + x-axis labels
    final dotFill   = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final dotStroke = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final lblStyle  = TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w500);

    for (var i = 0; i < values.length; i++) {
      final cx = xOf(i);
      final cy = yOf(values[i]);
      if (i == 0 || i == values.length - 1 || values[i] == maxV) {
        canvas.drawCircle(Offset(cx, cy), 4, dotFill);
        canvas.drawCircle(Offset(cx, cy), 4, dotStroke);
      }
      final tp = TextPainter(text: TextSpan(text: labels[i], style: lblStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.labels, required this.color});
  final List<double> values;
  final List<String> labels;
  final Color        color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _BarChartPainter(values: values, labels: labels, color: color));
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.values, required this.labels, required this.color});
  final List<double> values;
  final List<String> labels;
  final Color        color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const double labelH = 24;
    const double topPad = 8;
    const double gap    = 4;
    final double chartH = size.height - labelH - topPad;
    final double slotW  = size.width / values.length;
    final double barW   = slotW - gap * 2;
    final double maxV   = values.reduce(math.max);
    final lastIdx       = values.length - 1;
    final lblStyle      = TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w500);

    for (var i = 0; i < values.length; i++) {
      final barH   = (values[i] / maxV) * chartH * 0.85;
      final left   = i * slotW + gap;
      final top    = topPad + chartH - barH;
      final isLast = i == lastIdx;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, top, barW, barH),
          topLeft: const Radius.circular(4), topRight: const Radius.circular(4),
        ),
        Paint()..color = isLast ? color : color.withOpacity(0.45)..style = PaintingStyle.fill,
      );

      final tp = TextPainter(text: TextSpan(text: labels[i], style: lblStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(left + barW / 2 - tp.width / 2, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
