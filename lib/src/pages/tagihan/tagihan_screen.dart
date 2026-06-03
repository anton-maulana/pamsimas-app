import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/pages/tagihan/tagihan_detail_screen.dart';
import 'package:pamsimas_app/src/core/models/tagihan_model.dart';
import 'package:pamsimas_app/src/core/services/bill_service.dart';
import 'package:pamsimas_app/src/core/services/customers_service.dart';
import 'package:pamsimas_app/src/core/models/bill_model.dart';
import 'package:pamsimas_app/src/core/models/customer_model.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class TagihanScreen extends StatefulWidget {
  const TagihanScreen({Key? key}) : super(key: key);

  @override
  State<TagihanScreen> createState() => _TagihanScreenState();
}

class _TagihanScreenState extends State<TagihanScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color bgGrey      = Color(0xFFF2F4F7);

  late DateTime _selectedMonth;
  String _filterStatus = 'Semua';
  String _filterRt     = 'Semua';

  final List<String> _statusOptions = ['Semua', 'Lunas', 'Belum Bayar'];
  final List<String> _rtOptions     = ['Semua', 'RT 01', 'RT 02', 'RT 03', 'RT 04'];

  final List<DateTime> _monthOptions = List.generate(12, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - i);
  });

  List<BillRead> _bills = [];
  Map<int, Customer> _customerCache = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _fetchBills();
  }

  Future<void> _fetchBills() async {
     setState(() {
        _loading = true;
        _error = null;
     });
     try {
        final statusFilter = _filterStatus == 'Lunas' ? 'paid' : (_filterStatus == 'Belum Bayar' ? 'unpaid' : null);
        final fetchedBills = await BillService.instance.list(
           billingMonth: _selectedMonth.month,
           billingYear: _selectedMonth.year,
           status: statusFilter,
        );

        // Fetch missing customer details to populate fields
        final missingCustomerIds = fetchedBills.map((b) => b.customerId).toSet().difference(_customerCache.keys.toSet());
        for (final cid in missingCustomerIds) {
           try {
              final cust = await CustomersService.instance.get(cid.toString());
              _customerCache[cid] = cust;
           } catch (_) {}
        }

        if (mounted) {
           setState(() {
              _bills = fetchedBills;
              _loading = false;
           });
        }
     } catch (e) {
        if (mounted) {
           setState(() {
              _error = e.toString();
              _loading = false;
           });
        }
     }
  }

  List<BillRead> get _filtered {
    return _bills.where((b) {
      final cust = _customerCache[b.customerId];
      if (cust == null) return false;
      
      final matchRt = _filterRt == 'Semua' || cust.rt == _filterRt.replaceFirst('RT ', '');
      return matchRt;
    }).toList();
  }

  double get _totalTagihan => _filtered.fold(0.0, (s, t) => s + t.amount);
  int get _jumlahLunas  => _filtered.where((t) => t.status == 'paid').length;
  int get _jumlahBelum  => _filtered.where((t) => t.status == 'unpaid' || t.status == 'partially_paid').length;

  String _formatRp(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  String _formatMonth(DateTime d) {
    const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${months[d.month]} ${d.year}';
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchBills,
        child: Column(
          children: [
            _buildTopSection(),
            _buildSummaryRow(),
            _buildFilterRow(),
            _buildResultCount(filtered.length),
            Expanded(
               child: _loading 
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                     ? Center(
                          child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                                Text('Terjadi kesalahan: $_error', style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 8),
                                ElevatedButton(onPressed: _fetchBills, child: const Text('Coba Lagi')),
                             ],
                          ),
                       )
                     : _buildList(filtered)
            ),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text('Tagihan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          onPressed: () => _showFilterSheet(),
        ),
      ],
    );
  }

  // ─── Month Selector ───────────────────────────────────────────────────────
  Widget _buildTopSection() {
    return Container(
      color: primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
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
            items: _monthOptions.map((m) => DropdownMenuItem(
              value: m,
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 18, color: Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  Text(_formatMonth(m),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                ],
              ),
            )).toList(),
            onChanged: (v) {
               setState(() => _selectedMonth = v!);
               _fetchBills();
            },
          ),
        ),
      ),
    );
  }

  // ─── Summary Row ─────────────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildSummaryChip(
              icon: Icons.check_circle_rounded,
              label: 'Lunas',
              value: '$_jumlahLunas',
              color: const Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          _buildSummaryChip(
              icon: Icons.cancel_rounded,
              label: 'Belum Bayar',
              value: '$_jumlahBelum',
              color: const Color(0xFFC62828)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              Text(_formatRp(_totalTagihan.toInt()),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text('$label: ',
              style: TextStyle(fontSize: 12, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ─── Filter Chips ─────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _buildChip(
            label: _filterStatus == 'Semua' ? 'Status' : _filterStatus,
            active: _filterStatus != 'Semua',
            onTap: () => _showFilterSheet(),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: _filterRt == 'Semua' ? 'RT' : _filterRt,
            active: _filterRt != 'Semua',
            onTap: () => _showFilterSheet(),
          ),
          const Spacer(),
          if (_filterStatus != 'Semua' || _filterRt != 'Semua')
            GestureDetector(
              onTap: () => setState(() {
                _filterStatus = 'Semua';
                _filterRt     = 'Semua';
                _fetchBills();
              }),
              child: const Text('Reset',
                  style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildChip({
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
          color: active ? const Color(0xFFE3F2FD) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? const Color(0xFF1565C0)
                  : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: active
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF6B7280),
                    fontWeight: active
                        ? FontWeight.w600
                        : FontWeight.w400)),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: active
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  // ─── Result Count ─────────────────────────────────────────────────────────
  Widget _buildResultCount(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        '$count tagihan · ${_formatMonth(_selectedMonth)}',
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      ),
    );
  }

  // ─── List ─────────────────────────────────────────────────────────────────
  Widget _buildList(List<BillRead> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 16),
            Text('Tidak ada tagihan\nyang sesuai filter',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(BillRead t) {
    final Customer? cust = _customerCache[t.customerId];
    if (cust == null) return const SizedBox();

    final bool lunas      = t.status == 'paid';
    final bool partial    = t.status == 'partially_paid';
    final Color statusColor = lunas 
        ? const Color(0xFF2E7D32) 
        : (partial ? const Color(0xFFE65100) : const Color(0xFFC62828));
    final Color statusBg    = lunas 
        ? const Color(0xFFDCFCE7) 
        : (partial ? const Color(0xFFFFF3E0) : const Color(0xFFFEE2E2));
    final String statusLabel = lunas ? 'Lunas' : (partial ? 'Sebagian' : 'Belum Bayar');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openDetail(t, cust),
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
          child: Column(
            children: [
              // ── Main row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Color(0xFF1565C0), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(cust.name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A2E)),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(statusLabel,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 3),
                              Text('RT ${cust.rt}/RW ${cust.rw}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280))),
                              const SizedBox(width: 10),
                              const Icon(Icons.calendar_today_outlined,
                                  size: 12, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 3),
                              Text(_formatDate(t.createdAt),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Bottom detail row ──
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    _detailChip(Icons.water_drop_outlined,
                        '${t.usage} m³', const Color(0xFF00897B)),
                    const SizedBox(width: 10),
                    _detailChip(Icons.receipt_outlined,
                        _formatRp(t.amount.toInt()), const Color(0xFF1565C0)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }

  // ─── Filter Bottom Sheet ──────────────────────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Status Pembayaran',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _statusOptions.map((opt) {
                      final active = _filterStatus == opt;
                      return GestureDetector(
                        onTap: () {
                          setSheet(() {});
                          setState(() {
                             _filterStatus = opt;
                          });
                        },
                        child: _filterPill(opt, active),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('RT',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _rtOptions.map((opt) {
                      final active = _filterRt == opt;
                      return GestureDetector(
                        onTap: () {
                          setSheet(() {});
                          setState(() {
                             _filterRt = opt;
                          });
                        },
                        child: _filterPill(opt, active),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                         Navigator.pop(context);
                         _fetchBills();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terapkan',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _filterPill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? primaryBlue : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              color: active ? Colors.white : const Color(0xFF374151),
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.w400)),
    );
  }

  // ─── Detail Navigation ────────────────────────────────────────────────────
  void _openDetail(BillRead bill, Customer customer) {
    final tagihanItem = TagihanItem(
       id: bill.id.toString(),
       nama: customer.name,
       rt: customer.rt,
       rw: customer.rw,
       alamat: customer.address,
       meterSebelumnya: bill.meterStart,
       meterSaatIni: bill.meterEnd,
       pemakaian: bill.usage,
       totalTagihan: bill.amount.toInt(),
       status: bill.status == 'paid' ? StatusTagihan.lunas : StatusTagihan.belumBayar,
       tanggalCatat: bill.createdAt,
       petugas: 'Petugas Pamsimas',
    );

    Navigator.push(
       context,
       MaterialPageRoute(builder: (_) => TagihanDetailScreen(tagihan: tagihanItem, billId: bill.id)),
    ).then((_) => _fetchBills());
  }
}

