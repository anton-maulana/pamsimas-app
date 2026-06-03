import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pamsimas_app/src/core/models/customer_model.dart';
import 'package:pamsimas_app/src/core/models/petugas_model.dart';
import 'package:pamsimas_app/src/core/services/auth_service.dart';
import 'package:pamsimas_app/src/core/services/customers_service.dart';
import 'package:pamsimas_app/src/core/services/petugas_service.dart';

class TambahPelangganScreen extends StatefulWidget {
  /// Pass an existing [customer] to switch to edit mode.
  final Customer? customer;

  const TambahPelangganScreen({Key? key, this.customer}) : super(key: key);

  @override
  State<TambahPelangganScreen> createState() => _TambahPelangganScreenState();
}

class _TambahPelangganScreenState extends State<TambahPelangganScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color bgGrey      = Color(0xFFF2F4F7);

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _namaCtrl    = TextEditingController();
  final _rtCtrl      = TextEditingController();
  final _rwCtrl      = TextEditingController();
  final _alamatCtrl  = TextEditingController();
  final _hpCtrl      = TextEditingController();

  // Dropdown values
  int? _selectedOfficerId;
  double? _lat;
  double? _lng;

  bool _isSaving = false;
  bool _isLoadingOfficers = true;

  bool get _isEditMode => widget.customer != null;

  Map<int, String> _officersMap = {};

  @override
  void initState() {
    super.initState();
    _loadOfficersAndSetup();
  }
  
  Future<void> _loadOfficersAndSetup() async {
    try {
      final officers = await PetugasService.instance.list(itemsPerPage: 100);
      final newMap = <int, String>{};
      for (final off in officers) {
        newMap[off.id] = off.name;
      }
      
      if (mounted) {
        setState(() {
          _officersMap = newMap;
          _isLoadingOfficers = false;
          _prefillData();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOfficers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat daftar petugas'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
        _prefillData(); // attempt prefill anyway
      }
    }
  }
  
  void _prefillData() {
    final p = widget.customer;
    if (p != null) {
      _namaCtrl.text   = p.name;
      _rtCtrl.text     = p.rt;
      _rwCtrl.text     = p.rw;
      _alamatCtrl.text = p.address;
      _hpCtrl.text     = p.phoneNumber;
      _selectedOfficerId = _officersMap.containsKey(p.officerId) ? p.officerId : null;
      _lat = p.latitude;
      _lng = p.longitude;
    } else {
      // Auto-select if logged in as an officer
      final currentUser = AuthService.instance.currentUser;
      if (currentUser != null) {
        final role = currentUser['role'];
        final id = currentUser['id'];
        
        if (role == 'officer' && id != null && _officersMap.containsKey(id)) {
          _selectedOfficerId = id;
        }
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _rtCtrl.dispose();
    _rwCtrl.dispose();
    _alamatCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  // ─── Simulate location pick ───────────────────────────────────────────────
  void _pickLocation() {
    // Placeholder: simulate a picked location
    // Replace with actual map navigator when google_maps_flutter is added.
    setState(() {
      _lat = -6.8912 + (DateTime.now().millisecond / 100000);
      _lng = 109.0448 + (DateTime.now().millisecond / 100000);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Lokasi berhasil dipilih'),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _onSimpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final request = CustomerRequest(
        name:    _namaCtrl.text.trim(),
        rt:      _rtCtrl.text.trim(),
        rw:      _rwCtrl.text.trim(),
        address: _alamatCtrl.text.trim(),
        phoneNumber: _hpCtrl.text.trim(),
        officerId: _selectedOfficerId,
        status:  'ACTIVE',
        meterNumber: widget.customer?.meterNumber ?? 'MTR-${DateTime.now().millisecondsSinceEpoch}',
        meterImageId: widget.customer?.meterImageId,
        latitude:     _lat,
        longitude:    _lng,
      );
      if (_isEditMode) {
        await CustomersService.instance.update(widget.customer!.id, request);
      } else {
        await CustomersService.instance.create(request);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final code = e.response?.statusCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            code == 422
                ? 'Data tidak valid. Periksa kembali.'
                : 'Gagal menyimpan. Periksa koneksi internet.',
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Terjadi kesalahan. Silakan coba lagi.'),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Data Pelanggan'),
              const SizedBox(height: 14),
              _buildNamaField(),
              const SizedBox(height: 14),
              _buildRtRwRow(),
              const SizedBox(height: 14),
              _buildAlamatField(),
              const SizedBox(height: 14),
              _buildHpField(),
              const SizedBox(height: 24),
              _sectionLabel('Petugas'),
              const SizedBox(height: 14),
              _buildPetugasDropdown(),
              const SizedBox(height: 24),
              _sectionLabel('Lokasi'),
              const SizedBox(height: 14),
              _buildLokasiSection(),
              const SizedBox(height: 32),
              _buildButtons(),
            ],
          ),
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
      title: Text(
        _isEditMode ? 'Edit Pelanggan' : 'Tambah Pelanggan',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        letterSpacing: 0.8,
      ),
    );
  }

  // ─── Input decorator helper ───────────────────────────────────────────────
  InputDecoration _inputDecor({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC62828)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
      ),
    );
  }

  Widget _fieldCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── Fields ───────────────────────────────────────────────────────────────
  Widget _buildNamaField() {
    return _fieldCard(
      child: TextFormField(
        controller: _namaCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: _inputDecor(
          hint: 'Masukkan nama pelanggan',
          icon: Icons.person_outline_rounded,
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
      ),
    );
  }

  Widget _buildRtRwRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildRtField()),
        const SizedBox(width: 12),
        Expanded(child: _buildRwField()),
      ],
    );
  }

  Widget _buildRtField() {
    return _fieldCard(
      child: TextFormField(
        controller: _rtCtrl,
        keyboardType: TextInputType.number,
        decoration: _inputDecor(hint: '01', icon: Icons.location_on_outlined).copyWith(
          prefixIcon: null,
          prefixText: 'RT  ',
          prefixStyle: const TextStyle(
            color: Color(0xFF1565C0),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'RT wajib diisi' : null,
      ),
    );
  }

  Widget _buildRwField() {
    return _fieldCard(
      child: TextFormField(
        controller: _rwCtrl,
        keyboardType: TextInputType.number,
        decoration: _inputDecor(hint: '01', icon: Icons.location_city_outlined).copyWith(
          prefixIcon: null,
          prefixText: 'RW  ',
          prefixStyle: const TextStyle(
            color: Color(0xFF1565C0),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'RW wajib diisi' : null,
      ),
    );
  }

  Widget _buildAlamatField() {
    return _fieldCard(
      child: TextFormField(
        controller: _alamatCtrl,
        minLines: 3,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDecor(
          hint: 'Masukkan alamat lengkap...',
          icon: Icons.home_outlined,
        ).copyWith(
          alignLabelWithHint: true,
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Alamat wajib diisi' : null,
      ),
    );
  }

  Widget _buildHpField() {
    return _fieldCard(
      child: TextFormField(
        controller: _hpCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _inputDecor(
          hint: 'Contoh: 08123456789',
          icon: Icons.phone_outlined,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Nomor HP wajib diisi';
          if (v.length < 9) return 'Nomor HP tidak valid';
          return null;
        },
      ),
    );
  }

  Widget _buildPetugasDropdown() {
    if (_isLoadingOfficers) {
      return _fieldCard(
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      );
    }
    
    // Disable dropdown if current user is an officer
    final currentUser = AuthService.instance.currentUser;
    final isOfficer = currentUser != null && currentUser['role'] == 'officer';
    
    return _fieldCard(
      child: DropdownButtonFormField<int>(
        value: _selectedOfficerId,
        isExpanded: true,
        decoration: _inputDecor(
          hint: 'Pilih petugas',
          icon: Icons.badge_outlined,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
        items: _officersMap.entries.map((e) => DropdownMenuItem<int>(
          value: e.key,
          child: Text(e.value, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E))),
        )).toList(),
        onChanged: isOfficer ? null : (v) => setState(() => _selectedOfficerId = v),
        validator: (v) => v == null ? 'Petugas wajib dipilih' : null,
        disabledHint: _selectedOfficerId != null && _officersMap.containsKey(_selectedOfficerId)
            ? Text(_officersMap[_selectedOfficerId]!, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)))
            : null,
      ),
    );
  }

  // ─── Lokasi Section ───────────────────────────────────────────────────────
  Widget _buildLokasiSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Map preview area
            _buildMapPreview(),
            // Koordinat info + pick button
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_lat != null && _lng != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.my_location_rounded, size: 14, color: Color(0xFF1565C0)),
                              const SizedBox(width: 6),
                              Text(
                                '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ] else
                          const Text(
                            'Lokasi belum dipilih',
                            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.place_rounded, size: 16),
                    label: const Text('Pilih Lokasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFE8F0FE),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid lines to simulate map
          CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _MapGridPainter(),
          ),
          // Center pin
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _lat != null ? Icons.place_rounded : Icons.map_outlined,
                size: 48,
                color: _lat != null ? primaryBlue : const Color(0xFFBDBDBD),
              ),
              const SizedBox(height: 4),
              Text(
                _lat != null ? 'Lokasi terpilih' : 'Tap "Pilih Lokasi"',
                style: TextStyle(
                  fontSize: 12,
                  color: _lat != null ? primaryBlue : const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Buttons ──────────────────────────────────────────────────────────────
  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _onSimpan,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryBlue.withOpacity(0.55),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Map Grid Painter ─────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBDEFB).withOpacity(0.6)
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Fake "roads"
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


