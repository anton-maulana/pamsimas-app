import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/core/models/tagihan_model.dart';
import 'package:pamsimas_app/src/core/services/payment_service.dart';
import 'package:pamsimas_app/src/core/services/bill_service.dart';
import 'package:pamsimas_app/src/core/models/payment_model.dart';

// ─── Detail Screen ────────────────────────────────────────────────────────────

class TagihanDetailScreen extends StatefulWidget {
  final TagihanItem tagihan;
  final int billId;
  const TagihanDetailScreen({Key? key, required this.tagihan, required this.billId}) : super(key: key);

  @override
  State<TagihanDetailScreen> createState() => _TagihanDetailScreenState();
}

class _TagihanDetailScreenState extends State<TagihanDetailScreen> {

  static const Color _primary   = Color(0xFF1565C0);
  static const Color _bgGrey    = Color(0xFFF2F4F7);
  static const Color _green     = Color(0xFF2E7D32);
  static const Color _red       = Color(0xFFC62828);

  late StatusTagihan _status;
  DateTime? _tanggalBayar;
  bool _isMarking = false;

  @override
  void initState() {
    super.initState();
    _status       = widget.tagihan.status;
    _tanggalBayar = widget.tagihan.tanggalBayar;
    _checkBillStatus();
  }

  Future<void> _checkBillStatus() async {
     try {
        final payments = await PaymentService.instance.getPaymentsByBill(widget.billId);
        if (payments.isNotEmpty) {
           setState(() {
              _tanggalBayar = payments.last.paymentDate;
           });
        }
     } catch (_) {}
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _formatRp(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ─── Actions ──────────────────────────────────────────────────────────────
  Future<void> _tandaiLunas() async {
    setState(() => _isMarking = true);
    try {
      await PaymentService.instance.create(PaymentCreate(
         billId: widget.billId,
         amountPaid: widget.tagihan.totalTagihan.toDouble(),
         paymentMethod: 'Tunai',
         status: 'completed',
      ));
      
      setState(() {
        _status       = StatusTagihan.lunas;
        _tanggalBayar = DateTime.now();
        _isMarking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.tagihan.nama} ditandai lunas'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      setState(() => _isMarking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menandai lunas: $e'),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _batalkan() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Tagihan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Yakin ingin membatalkan tagihan ${widget.tagihan.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isMarking = true);
              try {
                 await BillService.instance.delete(widget.billId.toString());
                 if (mounted) {
                    Navigator.pop(context);
                 }
              } catch (e) {
                 setState(() => _isMarking = false);
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Gagal membatalkan tagihan: $e'),
                    backgroundColor: _red,
                 ));
              }
            },
            style: TextButton.styleFrom(foregroundColor: _red),
            child: const Text('Batalkan',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool lunas        = _status == StatusTagihan.lunas;
    final Color statusColor = lunas ? _green : _red;
    final Color statusBg    = lunas
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEE2E2);
    final t = widget.tagihan;

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: _buildAppBar(lunas),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            _buildCustomerCard(t),
            const SizedBox(height: 14),
            _buildTotalCard(t, lunas, statusBg, statusColor),
            const SizedBox(height: 14),
            _buildMeterCard(t),
            const SizedBox(height: 14),
            _buildBillingCard(t),
            const SizedBox(height: 14),
            _buildStatusCard(t, lunas, statusBg, statusColor),
            const SizedBox(height: 14),
            _buildFotoCard(),
            const SizedBox(height: 14),
            _buildLokasiCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(lunas),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool lunas) {
    return AppBar(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text('Detail Tagihan',
          style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'edit') {
              // TODO: navigate to edit form
            } else if (v == 'batal') {
              _batalkan();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 18, color: Color(0xFF374151)),
                SizedBox(width: 10),
                Text('Edit Tagihan'),
              ]),
            ),
            const PopupMenuItem(
              value: 'batal',
              child: Row(children: [
                Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFC62828)),
                SizedBox(width: 10),
                Text('Batalkan', style: TextStyle(color: Color(0xFFC62828))),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Customer Card ────────────────────────────────────────────────────────
  Widget _buildCustomerCard(TagihanItem t) {
    return _card(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE3F2FD),
            child: Icon(Icons.person_rounded,
                size: 32, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.nama,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                _infoText(Icons.location_on_outlined, 'RT ${t.rt}/RW ${t.rw}'),
                const SizedBox(height: 2),
                _infoText(Icons.home_outlined, t.alamat),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(t.id,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Total Tagihan Card ───────────────────────────────────────────────────
  Widget _buildTotalCard(
      TagihanItem t, bool lunas, Color statusBg, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
                color: lunas
                    ? Colors.white.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  lunas
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  lunas ? 'Lunas' : 'Belum Bayar',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Total Tagihan',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(_formatRp(t.totalTagihan),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('${t.pemakaian} m³  ×  ${_formatRp(t.tarif)}/m³',
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── Meter Card ───────────────────────────────────────────────────────────
  Widget _buildMeterCard(TagihanItem t) {
    return _sectionCard(
      title: 'Data Meter',
      icon: Icons.speed_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _meterBox(
                    label: 'Meter Sebelumnya',
                    value: '${t.meterSebelumnya}',
                    unit: 'm³',
                    color: const Color(0xFF6B7280)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _meterBox(
                    label: 'Meter Saat Ini',
                    value: '${t.meterSaatIni}',
                    unit: 'm³',
                    color: _primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.water_drop_rounded,
                    color: Color(0xFF00897B), size: 20),
                const SizedBox(width: 10),
                const Text('Pemakaian',
                    style: TextStyle(fontSize: 13, color: Color(0xFF374151))),
                const Spacer(),
                Text('${t.pemakaian} m³',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00897B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meterBox({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: TextStyle(
                        fontSize: 12, color: color.withOpacity(0.7))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Billing Card ─────────────────────────────────────────────────────────
  Widget _buildBillingCard(TagihanItem t) {
    return _sectionCard(
      title: 'Rincian Tagihan',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _billingRow('Pemakaian', '${t.pemakaian} m³'),
          _divider(),
          _billingRow('Tarif per m³', _formatRp(t.tarif)),
          _divider(),
          Row(
            children: [
              const Text('Total Tagihan',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_formatRp(t.totalTagihan),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billingRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
      ],
    );
  }

  // ─── Status Card ──────────────────────────────────────────────────────────
  Widget _buildStatusCard(
      TagihanItem t, bool lunas, Color statusBg, Color statusColor) {
    return _sectionCard(
      title: 'Status Pembayaran',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          Row(
            children: [
              const Text('Status',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      lunas
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 5),
                    Text(lunas ? 'Lunas' : 'Belum Bayar',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          _divider(),
          _billingRow('Tanggal Catat Meter', _formatDate(t.tanggalCatat)),
          if (lunas && _tanggalBayar != null) ...[
            _divider(),
            _billingRow('Tanggal Bayar', _formatDate(_tanggalBayar!)),
          ],
          _divider(),
          _billingRow('Petugas', t.petugas),
        ],
      ),
    );
  }

  // ─── Foto Meter Card ──────────────────────────────────────────────────────
  Widget _buildFotoCard() {
    return _sectionCard(
      title: 'Foto Meter',
      icon: Icons.photo_camera_outlined,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CustomPaint(
            painter: _PhotoGridPainter(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.photo_camera_rounded,
                    size: 40, color: Color(0xFFD1D5DB)),
                SizedBox(height: 8),
                Text('Belum ada foto meter',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Lokasi Card ──────────────────────────────────────────────────────────
  Widget _buildLokasiCard() {
    return _sectionCard(
      title: 'Lokasi Pengambilan',
      icon: Icons.map_outlined,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 130,
          child: CustomPaint(
            painter: _MapGridPainter(),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6)
                      ]),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_pin,
                          size: 14, color: Color(0xFF1565C0)),
                      SizedBox(width: 4),
                      Text('Lokasi tidak tersedia',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF374151))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Action Bar ────────────────────────────────────────────────────
  Widget _buildBottomBar(bool lunas) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: lunas
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: navigate to edit
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _batalkan,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Batalkan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: Color(0xFFC62828)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _tandaiLunas,
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text('Tandai Lunas',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: navigate to edit
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _batalkan,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Batalkan',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _red,
                          side: const BorderSide(color: Color(0xFFC62828)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // ─── Reusable Widgets ─────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: child,
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: const Color(0xFF1565C0)),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: Color(0xFFF3F4F6)),
      );
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8F5E9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final roadH = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 6;
    final roadV = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 6;
    final grid = Paint()
      ..color = const Color(0xFFCFDDD1)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += size.height / 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (double x = 0; x < size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    canvas.drawLine(Offset(0, size.height * .5),
        Offset(size.width, size.height * .5), roadH);
    canvas.drawLine(Offset(size.width * .4, 0),
        Offset(size.width * .4, size.height), roadV);

    final pin = Paint()..color = const Color(0xFF1565C0);
    canvas.drawCircle(
        Offset(size.width * .4, size.height * .5), 7, pin);
    canvas.drawCircle(Offset(size.width * .4, size.height * .5), 4,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PhotoGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFF3F4F6));
    final p = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
