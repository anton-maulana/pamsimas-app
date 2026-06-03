import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/pages/laporan/laporan_detail_screen.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class _ReportCategory {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String type;

  const _ReportCategory({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({Key? key}) : super(key: key);

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color bgGrey      = Color(0xFFF2F4F7);

  late DateTime _selectedMonth;
  String _filterWilayah = 'Semua';
  String _filterPetugas = 'Semua';

  final List<String> _wilayahOptions = [
    'Semua',
    'RT 01/RW 01',
    'RT 01/RW 02',
    'RT 01/RW 03',
    'RT 02/RW 01',
    'RT 02/RW 03',
    'RT 03/RW 01',
    'RT 03/RW 02',
    'RT 04/RW 01',
  ];

  final List<String> _petugasOptions = [
    'Semua',
    'Budi Santoso',
    'Dewi Lestari',
    'Eko Prasetyo',
    'Fitri Handayani',
  ];

  static const List<_ReportCategory> _categories = [
    _ReportCategory(
      icon: Icons.water_drop_outlined,
      color: Color(0xFF1565C0),
      title: 'Penggunaan Air',
      subtitle: 'Pemakaian per pelanggan & wilayah',
      type: 'penggunaan_air',
    ),
    _ReportCategory(
      icon: Icons.account_balance_outlined,
      color: Color(0xFF2E7D32),
      title: 'Keuangan',
      subtitle: 'Pendapatan & tren bulanan',
      type: 'keuangan',
    ),
    _ReportCategory(
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFE65100),
      title: 'Tagihan',
      subtitle: 'Status pembayaran & tunggakan',
      type: 'tagihan',
    ),
    _ReportCategory(
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFC62828),
      title: 'Anomali',
      subtitle: 'Pemakaian tidak wajar',
      type: 'anomali',
    ),
    _ReportCategory(
      icon: Icons.badge_outlined,
      color: Color(0xFF283593),
      title: 'Petugas',
      subtitle: 'Kinerja penagihan',
      type: 'petugas',
    ),
    _ReportCategory(
      icon: Icons.map_outlined,
      color: Color(0xFF00695C),
      title: 'Wilayah',
      subtitle: 'Statistik per RT/RW',
      type: 'wilayah',
    ),
  ];

  final List<DateTime> _monthOptions = List.generate(12, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - i);
  });

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  String _formatMonth(DateTime d) {
    const months = [
      '',
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${months[d.month]} ${d.year}';
  }

  bool get _hasActiveFilters =>
      _filterWilayah != 'Semua' || _filterPetugas != 'Semua';

  void _resetFilters() {
    setState(() {
      _filterWilayah = 'Semua';
      _filterPetugas = 'Semua';
    });
  }

  void _openCategory(_ReportCategory cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LaporanDetailScreen(
          title: cat.title,
          subtitle: cat.subtitle,
          icon: cat.icon,
          color: cat.color,
          type: cat.type,
          period: _formatMonth(_selectedMonth),
          wilayah: _filterWilayah,
          petugas: _filterPetugas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTopSection(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                _buildSectionLabel('Kategori Laporan'),
                const SizedBox(height: 14),
                ..._categories.map(_buildCategoryCard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Laporan',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      actions: [
        if (_hasActiveFilters)
          IconButton(
            icon: const Icon(Icons.filter_list_off_rounded),
            tooltip: 'Reset Filter',
            onPressed: _resetFilters,
          ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Filter',
          onPressed: () => _showFilterSheet(),
        ),
      ],
    );
  }

  // ─── Top Section (Period + Filters) ───────────────────────────────────────

  Widget _buildTopSection() {
    return Container(
      color: primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period label
          const Text(
            'Pilih Periode',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          // Month dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateTime>(
                value: _selectedMonth,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6B7280)),
                items: _monthOptions
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                size: 18, color: Color(0xFF1565C0)),
                            const SizedBox(width: 10),
                            Text(
                              _formatMonth(m),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          Row(
            children: [
              _buildFilterChip(
                icon: Icons.location_on_outlined,
                label: _filterWilayah == 'Semua' ? 'RT / Wilayah' : _filterWilayah,
                active: _filterWilayah != 'Semua',
                onTap: () => _showFilterSheet(initialTab: 0),
              ),
              const SizedBox(width: 10),
              _buildFilterChip(
                icon: Icons.badge_outlined,
                label: _filterPetugas == 'Semua' ? 'Petugas' : _filterPetugas,
                active: _filterPetugas != 'Semua',
                onTap: () => _showFilterSheet(initialTab: 1),
              ),
              if (_hasActiveFilters) ...[
                const Spacer(),
                GestureDetector(
                  onTap: _resetFilters,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.white : Colors.white.withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? primaryBlue : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? primaryBlue : Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: active ? primaryBlue : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        letterSpacing: 1,
      ),
    );
  }

  // ─── Category Card ────────────────────────────────────────────────────────

  Widget _buildCategoryCard(_ReportCategory cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openCategory(cat),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cat.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: cat.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Filter Bottom Sheet ─────────────────────────────────────────────────

  void _showFilterSheet({int initialTab = 0}) {
    String tempWilayah = _filterWilayah;
    String tempPetugas = _filterPetugas;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Filter Laporan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // RT / Wilayah
                  _sheetSectionLabel('RT / Wilayah', padding: const EdgeInsets.symmetric(horizontal: 20)),
                  const SizedBox(height: 10),
                  _buildOptionGroup(
                    options: _wilayahOptions,
                    selected: tempWilayah,
                    onChanged: (v) => setModal(() => tempWilayah = v),
                    color: primaryBlue,
                  ),
                  const SizedBox(height: 20),
                  // Petugas
                  _sheetSectionLabel('Petugas', padding: const EdgeInsets.symmetric(horizontal: 20)),
                  const SizedBox(height: 10),
                  _buildOptionGroup(
                    options: _petugasOptions,
                    selected: tempPetugas,
                    onChanged: (v) => setModal(() => tempPetugas = v),
                    color: const Color(0xFF283593),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModal(() {
                                tempWilayah = 'Semua';
                                tempPetugas = 'Semua';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filterWilayah = tempWilayah;
                                _filterPetugas = tempPetugas;
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Terapkan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  Widget _sheetSectionLabel(String text, {EdgeInsets? padding}) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildOptionGroup({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
    required Color color,
  }) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final opt = options[i];
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
