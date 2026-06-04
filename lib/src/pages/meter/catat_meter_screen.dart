import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pamsimas_app/src/core/models/customer_model.dart';
import 'package:pamsimas_app/src/core/models/meter_reading_model.dart';
import 'package:pamsimas_app/src/core/models/bill_model.dart';
import 'package:pamsimas_app/src/core/models/payment_model.dart';
import 'package:pamsimas_app/src/core/services/bill_service.dart';
import 'package:pamsimas_app/src/core/services/customers_service.dart';
import 'package:pamsimas_app/src/core/services/image_service.dart';
import 'package:pamsimas_app/src/core/services/auth_service.dart';
import 'package:pamsimas_app/src/core/services/meter_reading_service.dart';
import 'package:pamsimas_app/src/core/services/payment_service.dart';
import 'package:pamsimas_app/src/core/services/petugas_service.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';

// Tarif per m³ (example flat-rate)
const int _tarifPerM3 = 3500;

// ─── Screen ───────────────────────────────────────────────────────────────────

class CatatMeterScreen extends StatefulWidget {
  final Customer? preselectedCustomer;
  const CatatMeterScreen({Key? key, this.preselectedCustomer}) : super(key: key);

  @override
  State<CatatMeterScreen> createState() => _CatatMeterScreenState();
}

class _CatatMeterScreenState extends State<CatatMeterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _meterCtrl     = TextEditingController();
  final _searchCtrl    = TextEditingController();
  final _picker        = ImagePicker();

  Customer? _selected;
  double?    _meterSaatIni;
  File?   _buktiPhoto;
  double? _lat;
  double? _lng;
  int? _selectedPetugas;
  List<BillRead> _unpaidBills = [];
  double _totalTunggakan = 0.0;
  bool _isLoadingUnpaidBills = false;
  bool _isLoading = false;
  bool _isLoadingOfficers = true;
  // ─── Officers state ───────────────────────────────────────────────────────
  Map<int, String> _officersMap = {};
  String? _officersError;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCustomer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Refresh officers for this customer's area
      _fetchOfficers(rt: widget.preselectedCustomer!.rt.toString(), rw: widget.preselectedCustomer!.rw.toString());
      _selectCustomerDirectly(widget.preselectedCustomer!);
      });
    } else {
      _fetchOfficers();
    }
  }

  Future<void> _selectCustomerDirectly(Customer picked) async {
     setState(() {
       _selected = picked;
       _meterCtrl.clear();
       _meterSaatIni = null;
       _unpaidBills = [];
       _totalTunggakan = 0.0;
       _isLoadingUnpaidBills = true;
       _amountDirectCtrl.text = _estimasiTagihan.toString();
     });
 
     // Refresh officers for this customer's area
     _fetchOfficers(rt: picked.rt.toString(), rw: picked.rw.toString());


     try {
        final customerId = int.parse(picked.id);
        final bills = await BillService.instance.getBillsByCustomer(customerId);
        final unpaid = bills.where((b) => b.status == 'unpaid' || b.status == 'partially_paid').toList();
        
        final unpaidWithRemaining = <BillRead>[];
        double tunggakanAccumulator = 0.0;
        for (final bill in unpaid) {
           final payments = await PaymentService.instance.getPaymentsByBill(bill.id);
           final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
           final remaining = bill.amount - totalPaid;
           if (remaining > 0) {
              unpaidWithRemaining.add(bill);
              tunggakanAccumulator += remaining;
           }
        }

        if (mounted) {
           setState(() {
              _unpaidBills = unpaidWithRemaining;
              _totalTunggakan = tunggakanAccumulator;
              _isLoadingUnpaidBills = false;
              _amountDirectCtrl.text = (_estimasiTagihan + _totalTunggakan).toInt().toString();
           });
        }
     } catch (e) {
        if (mounted) {
           setState(() {
              _isLoadingUnpaidBills = false;
           });
        }
        _showSnack('Gagal memuat tunggakan pelanggan: $e');
     }
  }

  Future<void> _fetchOfficers({String? rt, String? rw}) async {
    setState(() {
      _isLoadingOfficers = true;
      _officersError = null;
    });
    try {
      final officers = await PetugasService.instance.list(page: 1, itemsPerPage: 100, rt: rt, rw: rw);
      final newMap = <int, String>{};
      for (final off in officers) {
        newMap[off.id] = off.name;
      }
      if (mounted) {
        setState(() {
          _officersMap = newMap;
          _isLoadingOfficers = false;
          // Auto select if only one officer
          if (newMap.length == 1) {
            _selectedPetugas = newMap.keys.first;
          } else {
            _selectedPetugas = null;
          }
        });
        _prefillData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOfficers = false;
          _officersError = e.toString();
        });
        _prefillData();
      }
    }
  }

  void _prefillData() {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser != null) {
      final role = currentUser['role'];
      final id = currentUser['id'];
      if (role == 'officer' && id != null && _officersMap.containsKey(id)) {
        setState(() => _selectedPetugas = id as int?);
      }
    }
  }




  // ─── Computed ──────────────────────────────────────────────────────────────
  double get _pemakaian {
    if (_selected == null || _meterSaatIni == null) return 0;
    final previous = _selected!.meterNumber;
    final diff = _meterSaatIni! - previous;
    return diff < 0 ? 0 : diff;
  }

  double get _estimasiTagihan => _pemakaian * _tarifPerM3;

  String _formatRp(num value) {
    final s = value.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  // ─── Actions ─────────────────────────────────────────────────────────────
  bool _isPaid = false;
  final _amountDirectCtrl = TextEditingController();

  void _onMeterChanged(String v) {
    setState(() => _meterSaatIni = double.tryParse(v));
    _amountDirectCtrl.text = (_estimasiTagihan + _totalTunggakan).toInt().toString();
  }

  void _ambilLokasi() {
    setState(() {
      _lat = -6.8912 + (DateTime.now().millisecond / 100000);
      _lng = 109.0448 + (DateTime.now().millisecond / 100000);
    });
    _showSnack('Lokasi berhasil diambil');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppPalette.primaryBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _pickImage(bool fromCamera) async {
    Navigator.pop(context); // close bottom sheet
    try {
      final XFile? photo = await _picker.pickImage(source: fromCamera ? ImageSource.camera : ImageSource.gallery);
      if (photo != null) {
        final compressed = await _compressImage(File(photo.path));
        if (compressed != null) {
           setState(() => _buktiPhoto = compressed);
        } else {
           setState(() => _buktiPhoto = File(photo.path)); 
        }
      }
    } catch (e) {
      _showSnack("Gagal mengambil foto: $e");
    }
  }

  Future<File?> _compressImage(File file) async {
    final dir = file.parent.path;
    final targetPath = "$dir/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // Compression quality like whatsapp
      minWidth: 800,
      minHeight: 800,
    );
    
    if (result != null) {
       return File(result.path);
    }
    return null;
  }

    Future<void> _onSimpan() async {
      if (_selected == null) {
        _showSnack('Pilih pelanggan terlebih dahulu');
        return;
      }
      
      if (_formKey.currentState!.validate()) {
        if (_buktiPhoto == null) {
           _showSnack('Tolong unggah bukti foto meteran terlebih dahulu');
           return;
        }

        setState(() => _isLoading = true);

        try {
           // Upload foto
           final uploadResp = await ImageService.instance.uploadImage(_buktiPhoto!);
           
           final today = DateTime.now();
           final readingDateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

           final previousMeter = _selected!.meterNumber;

           final req = MeterReadingRequest(
              customerId: int.parse(_selected!.id),
              readingDate: readingDateStr,
              currentMeter: _meterSaatIni!,
              previousMeter: previousMeter,
              imageId: uploadResp.id,
              latitude: _lat,
              longitude: _lng, 
           );

           await MeterReadingService.instance.create(req);

           // Buat tagihan otomatis dari hasil pembacaan meter
           final bill = await BillService.instance.create(BillCreate(
             customerId: int.parse(_selected!.id),
             billingMonth: today.month,
             billingYear: today.year,
             meterStart: previousMeter,
             meterEnd: _meterSaatIni!,
             usage: _pemakaian,
             amount: _estimasiTagihan,
             status: 'unpaid', 
           ));
           
           if (!mounted) return;

           if (_isPaid) {
              final amountText = _amountDirectCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
              final amountPaid = double.tryParse(amountText) ?? 0.0;
              
              if (amountPaid > 0) {
                 await PaymentService.instance.createCumulative(
                    customerId: int.parse(_selected!.id),
                    amountPaid: amountPaid,
                    paymentMethod: 'Tunai',
                 );
              }
              setState(() => _isLoading = false);
              _showSnack('Catat meter dan pembayaran berhasil disimpan');
              Navigator.pop(context, true);
           } else {
              setState(() => _isLoading = false);
              // Tawarkan pencatatan pembayaran langsung jika belum bayar
              await _showPaymentSheet(bill);
           }
        } catch (e) {
           _showSnack('Gagal menyimpan: $e');
           if (mounted) setState(() => _isLoading = false);
        }
      }
    }

    Future<void> _showPaymentSheet(BillRead bill) async {
      final paid = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PaymentSheet(bill: bill),
      );
      if (!mounted) return;
      if (paid != true) {
        Navigator.pop(context, false);
      } else {
        Navigator.pop(context, true);
        _showSnack('Pembayaran berhasil dicatat. Status tagihan lunas.');
      }
    }

  // ─── Status Pembayaran ───────────────────────────────────────────────────
  Widget _buildStatusPembayaran() {
    final hasTunggakan = _unpaidBills.isNotEmpty;
    final totalKumulatif = _estimasiTagihan + _totalTunggakan;

    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasTunggakan) ...[
               Container(
                 padding: const EdgeInsets.all(10),
                 margin: const EdgeInsets.only(bottom: 12),
                 decoration: BoxDecoration(
                   color: AppPalette.errorRed.withOpacity(0.07),
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: AppPalette.errorRed.withOpacity(0.15)),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.warning_amber_rounded, color: AppPalette.errorRed, size: 18),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text(
                             'Ada Tunggakan Sebelumnya!',
                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppPalette.errorRed),
                           ),
                           const SizedBox(height: 2),
                           Text(
                             'Bulan: ${_unpaidBills.map((b) => "${b.billingMonth}/${b.billingYear}").join(', ')}',
                             style: const TextStyle(fontSize: 12, color: AppPalette.errorRed),
                           ),
                           Text(
                             'Total Tunggakan: ${_formatRp(_totalTunggakan.toInt())}',
                             style: const TextStyle(fontSize: 12, color: AppPalette.errorRed, fontWeight: FontWeight.w600),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isPaid ? Icons.check_circle : Icons.pending,
                      color: _isPaid ? AppPalette.successGreen : AppPalette.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Pembayaran',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.textDark)),
                        const SizedBox(height: 2),
                        Text(
                            _isPaid
                                ? 'Bayar Langsung'
                                : 'Belum Bayar (Bisa nyusul)',
                            style: const TextStyle(
                                fontSize: 12, color: AppPalette.textGreyLight)),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _isPaid,
                  activeColor: AppPalette.successGreen,
                  onChanged: (val) {
                    setState(() {
                       _isPaid = val;
                       if (val) {
                          _amountDirectCtrl.text = totalKumulatif.toInt().toString();
                       }
                    });
                  },
                ),
              ],
            ),
            if (_isPaid) ...[
               const Divider(height: 20),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('Est. Tagihan Baru:', style: TextStyle(fontSize: 13, color: AppPalette.textGrey)),
                   Text(_formatRp(_estimasiTagihan), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                 ],
               ),
               if (hasTunggakan) ...[
                 const SizedBox(height: 4),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('Total Tunggakan:', style: TextStyle(fontSize: 13, color: AppPalette.textGrey)),
                     Text(_formatRp(_totalTunggakan.toInt()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                   ],
                 ),
               ],
               const SizedBox(height: 4),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('Total Kumulatif:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppPalette.primaryBlue)),
                   Text(_formatRp(totalKumulatif.toInt()), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppPalette.primaryBlue)),
                 ],
               ),
               const SizedBox(height: 12),
               TextField(
                controller: _amountDirectCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Jumlah yang dibayar (Rp)',
                  labelStyle: const TextStyle(fontSize: 13, color: AppPalette.textGrey),
                  filled: true,
                  fillColor: AppPalette.bgGrey,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppPalette.borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppPalette.primaryBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ]
          ],
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bgGrey,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Data Pelanggan'),
              const SizedBox(height: 12),
              _buildPelangganPicker(),
              if (_selected != null) ...[
                const SizedBox(height: 14),
                _buildMeterSebelumnya(),
              ],
              const SizedBox(height: 24),
              _sectionLabel('Pembacaan Meter'),
              const SizedBox(height: 12),
              _buildMeterSaatIniField(),
              const SizedBox(height: 14),
              _buildCalculatedRow(),
              const SizedBox(height: 24),
              _sectionLabel('Status Tagihan'),
              const SizedBox(height: 12),
              _buildStatusPembayaran(),
              const SizedBox(height: 24),
              _sectionLabel('Petugas'),
              const SizedBox(height: 12),
              _buildPetugasDropdown(),
              const SizedBox(height: 24),
              _sectionLabel('Bukti Foto'),
              const SizedBox(height: 12),
              _buildBuktiPicker(),
              const SizedBox(height: 24),
              _sectionLabel('Lokasi'),
              const SizedBox(height: 12),
              _buildLokasiSection(),
              const SizedBox(height: 32),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppPalette.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text('Catat Meter',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppPalette.textGrey,
        letterSpacing: 1,
      ),
    );
  }

  // ─── Pelanggan Picker ─────────────────────────────────────────────────────
  Widget _buildPelangganPicker() {
    return _card(
      child: InkWell(
        onTap: () => _showPelangganSheet(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.person_search_rounded, color: AppPalette.textGreyLight, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: _selected == null
                    ? const Text('Pilih Pelanggan',
                        style: TextStyle(color: AppPalette.textHint, fontSize: 15))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selected!.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppPalette.textDark)),
                          const SizedBox(height: 2),
                          Text('${_selected!.id} • RT ${_selected!.rt}/RW ${_selected!.rw}',
                              style: const TextStyle(
                                  color: AppPalette.textGreyLight, fontSize: 13)),
                        ],
                      ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppPalette.textGreyLight),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Meter Sebelumnya (readonly) ──────────────────────────────────────────
  Widget _buildMeterSebelumnya() {
    return _card(
      color: AppPalette.readonlyBlue,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppPalette.primaryBlue, size: 20),
                const SizedBox(width: 12),
                const Text('Meter Sebelumnya',
                    style: TextStyle(fontSize: 13, color: AppPalette.textGrey)),
                const Spacer(),
                Text(
                  '${_selected!.meterNumber} m³',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.primaryBlue),
                ),
              ],
            ),
            if (_isLoadingUnpaidBills) ...[
               const SizedBox(height: 10),
               const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
               ),
            ] else if (_unpaidBills.isNotEmpty) ...[
               const Divider(height: 20),
               ..._unpaidBills.map((b) => FutureBuilder<List<PaymentRead>>(
                  future: PaymentService.instance.getPaymentsByBill(b.id),
                  builder: (context, snapshot) {
                     final totalPaid = snapshot.data?.fold<double>(0, (sum, p) => sum + p.amountPaid) ?? 0;
                     final remaining = b.amount - totalPaid;
                     return Padding(
                       padding: const EdgeInsets.symmetric(vertical: 4.0),
                       child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Row(
                               children: [
                                 const Icon(Icons.warning_amber_rounded, color: AppPalette.errorRed, size: 16),
                                 const SizedBox(width: 6),
                                 Text(
                                    'Tunggakan Bulan ${b.billingMonth}/${b.billingYear}',
                                    style: const TextStyle(fontSize: 12, color: AppPalette.errorRed, fontWeight: FontWeight.w600),
                                 ),
                               ],
                             ),
                             Row(
                               children: [
                                 Text(
                                    _formatRp(remaining.toInt()),
                                    style: const TextStyle(fontSize: 12, color: AppPalette.errorRed, fontWeight: FontWeight.bold),
                                 ),
                                 const SizedBox(width: 8),
                                 ElevatedButton(
                                    onPressed: () => _showOutstandingPaymentSheet(b, remaining),
                                    style: ElevatedButton.styleFrom(
                                       backgroundColor: AppPalette.errorRed,
                                       foregroundColor: Colors.white,
                                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                       minimumSize: Size.zero,
                                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text('Bayar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                 ),
                               ],
                             ),
                          ],
                       ),
                     );
                  }
               )).toList()
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _showOutstandingPaymentSheet(BillRead bill, double remainingAmount) async {
     final paid = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PaymentSheet(bill: bill, customAmount: remainingAmount),
     );
     if (paid == true) {
        _showSnack('Pembayaran tunggakan berhasil dicatat');
        // Refresh unpaid bills list
        if (_selected != null) {
           setState(() => _isLoadingUnpaidBills = true);
           try {
              final bills = await BillService.instance.getBillsByCustomer(int.parse(_selected!.id));
              final unpaid = bills.where((b) => b.status == 'unpaid' || b.status == 'partially_paid').toList();
              final unpaidWithRemaining = <BillRead>[];
              for (final b in unpaid) {
                 final payments = await PaymentService.instance.getPaymentsByBill(b.id);
                 final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
                 final remaining = b.amount - totalPaid;
                 if (remaining > 0) {
                    unpaidWithRemaining.add(b);
                 }
              }
              setState(() {
                 _unpaidBills = unpaidWithRemaining;
                 _isLoadingUnpaidBills = false;
              });
           } catch (_) {
              setState(() => _isLoadingUnpaidBills = false);
           }
        }
     }
  }

  // ─── Meter Saat Ini ───────────────────────────────────────────────────────
  Widget _buildMeterSaatIniField() {
    return _card(
      child: TextFormField(
        controller: _meterCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: AppPalette.textDark),
        onChanged: _onMeterChanged,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: AppPalette.textHintLight, fontSize: 22),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.speed_rounded, color: AppPalette.primaryBlue, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixText: 'm³',
          suffixStyle: const TextStyle(
              fontSize: 16,
              color: AppPalette.textGrey,
              fontWeight: FontWeight.w600),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.borderGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppPalette.primaryBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.errorRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppPalette.errorRed, width: 1.5),
          ),
          labelText: 'Meter Saat Ini',
          labelStyle:
              const TextStyle(fontSize: 13, color: AppPalette.textGrey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Wajib diisi';
          final val = double.tryParse(v);
          if (val == null) return 'Angka tidak valid';
            if (_selected != null && val < _selected!.meterNumber) {
              return 'Tidak boleh kurang dari meter sebelumnya (${_selected!.meterNumber})';
            }
          return null;
        },
      ),
    );
  }

  // ─── Calculated Fields ────────────────────────────────────────────────────
  Widget _buildCalculatedRow() {
    return Row(
      children: [
        Expanded(
          child: _buildCalcCard(
            icon: Icons.water_drop_outlined,
            label: 'Pemakaian',
            value: '${_pemakaian.toStringAsFixed(2)} m³',
            color: AppPalette.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCalcCard(
            icon: Icons.receipt_outlined,
            label: 'Est. Tagihan',
            value: _formatRp(_estimasiTagihan),
            color: AppPalette.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildCalcCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  // ─── Petugas Dropdown ─────────────────────────────────────────────────────
  Widget _buildPetugasDropdown() {
    if (_isLoadingOfficers) {
      return _card(
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      );
    }

    if (_officersError != null && _officersMap.isEmpty) {
      return _card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppPalette.orange, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Gagal memuat petugas',
                    style: TextStyle(color: AppPalette.textGrey, fontSize: 14)),
              ),
              TextButton(
                onPressed: _fetchOfficers,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    final currentUser = AuthService.instance.currentUser;
    final isOfficer = currentUser != null && currentUser['role'] == 'officer';

    return _card(
      child: DropdownButtonFormField<int>(
        value: _selectedPetugas,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'Pilih petugas',
          hintStyle: const TextStyle(color: AppPalette.textHint, fontSize: 14),
          prefixIcon: const Icon(Icons.badge_outlined,
              color: AppPalette.textGreyLight, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.borderGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.primaryBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.errorRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.errorRed, width: 1.5),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppPalette.textGreyLight),
        items: _officersMap.entries
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value,
                      style: const TextStyle(
                          fontSize: 14, color: AppPalette.textDark)),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedPetugas = v),
        validator: (v) => v == null ? 'Petugas wajib dipilih' : null,
        disabledHint: _selectedPetugas != null && _officersMap.containsKey(_selectedPetugas)
            ? Text(_officersMap[_selectedPetugas]!, style: const TextStyle(fontSize: 14, color: AppPalette.textDark))
            : null,
      ),
    );
  }

  // ─── Bukti Foto ───────────────────────────────────────────────────────────
  Widget _buildBuktiPicker() {
    return _card(
      child: InkWell(
        onTap: () => _showImageSourceSheet(),
        borderRadius: BorderRadius.circular(12),
        child: _buktiPhoto != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(_buktiPhoto!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _buktiPhoto = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: const [
                    Icon(Icons.add_a_photo_outlined,
                        size: 40, color: AppPalette.textGreyLight),
                    SizedBox(height: 10),
                    Text('Foto Meter (Opsional)',
                        style:
                            TextStyle(fontSize: 14, color: AppPalette.textGreyLight)),
                    SizedBox(height: 4),
                    Text('Tap untuk ambil foto atau pilih galeri',
                        style: TextStyle(
                            fontSize: 12, color: AppPalette.textHint)),
                  ],
                ),
              ),
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
          border: Border.all(color: AppPalette.borderGrey),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            _buildMapPreview(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: _lat != null
                        ? Row(children: [
                            const Icon(Icons.my_location_rounded,
                                size: 14, color: AppPalette.primaryBlue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppPalette.textLabel,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ])
                        : const Text('Lokasi belum diambil',
                            style: TextStyle(
                                fontSize: 13, color: AppPalette.textGreyLight)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _ambilLokasi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.gps_fixed_rounded, size: 15),
                    label: const Text('Ambil Lokasi',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
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
      height: 140,
      width: double.infinity,
      color: AppPalette.bgBlueLight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(double.infinity, 140),
            painter: _MapGridPainter(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _lat != null ? Icons.place_rounded : Icons.map_outlined,
                size: 44,
                color:
                    _lat != null ? AppPalette.primaryBlue : AppPalette.textGreyMuted,
              ),
              const SizedBox(height: 4),
              Text(
                _lat != null ? 'Lokasi terpilih' : 'Belum ada lokasi',
                style: TextStyle(
                  fontSize: 12,
                  color: _lat != null
                      ? AppPalette.primaryBlue
                      : AppPalette.textGreyLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Buttons ─────────────────────────────────────────────────────────────
  Widget _buildButtons() {
    return Column(
      children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onSimpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.textGrey,
              side: const BorderSide(color: AppPalette.textHintLight),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Batal',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ─── Card helper ──────────────────────────────────────────────────────────
  Widget _card({required Widget child, Color color = Colors.white}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.borderGrey),
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

  // ─── Pelanggan Bottom Sheet ───────────────────────────────────────────────
  void _showPelangganSheet() {
    showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CustomerPickerSheet(),
    ).then((picked) async {
      if (picked != null) {
        setState(() {
          _selected = picked;
          _meterCtrl.clear();
          _meterSaatIni = null;
          _unpaidBills = [];
          _totalTunggakan = 0.0;
          _isLoadingUnpaidBills = true;
          _amountDirectCtrl.text = _estimasiTagihan.toString();
        });

        // Refresh officers for this customer's area
        _fetchOfficers(rt: picked.rt.toString(), rw: picked.rw.toString());

        try {
           final customerId = int.parse(picked.id);
           final bills = await BillService.instance.getBillsByCustomer(customerId);
           final unpaid = bills.where((b) => b.status == 'unpaid' || b.status == 'partially_paid').toList();
           
           final unpaidWithRemaining = <BillRead>[];
           double tunggakanAccumulator = 0.0;
           for (final bill in unpaid) {
              final payments = await PaymentService.instance.getPaymentsByBill(bill.id);
              final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
              final remaining = bill.amount - totalPaid;
              if (remaining > 0) {
                 unpaidWithRemaining.add(bill);
                 tunggakanAccumulator += remaining;
              }
           }

           if (mounted) {
              setState(() {
                 _unpaidBills = unpaidWithRemaining;
                 _totalTunggakan = tunggakanAccumulator;
                 _isLoadingUnpaidBills = false;
                 // Set direct payment to (current estimate + outstanding total)
                 _amountDirectCtrl.text = (_estimasiTagihan + _totalTunggakan).toInt().toString();
              });
           }
        } catch (e) {
           if (mounted) {
              setState(() {
                 _isLoadingUnpaidBills = false;
              });
           }
           _showSnack('Gagal memuat tunggakan pelanggan: $e');
        }
      }
    });
  }

  // ─── Image Source Sheet ───────────────────────────────────────────────────
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.textHintLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppPalette.bgBluePale,
                    child: Icon(Icons.camera_alt_rounded,
                        color: AppPalette.primaryBlue),
                  ),
                  title: const Text('Kamera',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ambil foto langsung'),
                  onTap: () => _pickImage(true),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppPalette.bgGreenPale,
                    child: Icon(Icons.photo_library_rounded,
                        color: AppPalette.successGreen),
                  ),
                  title: const Text('Galeri',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pilih dari galeri'),
                  onTap: () => _pickImage(false),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _meterCtrl.dispose();
    _searchCtrl.dispose();
    _amountDirectCtrl.dispose();
    super.dispose();
  }
}

// ─── Map Grid Painter ─────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppPalette.bgBluePale.withOpacity(0.6)
      ..strokeWidth = 1;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height * 0.45),
        Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0),
        Offset(size.width * 0.35, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0),
        Offset(size.width * 0.7, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Payment Sheet ────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final BillRead bill;
  final double? customAmount;
  const _PaymentSheet({required this.bill, this.customAmount});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  static const _methods = ['Tunai', 'Transfer Bank', 'QRIS', 'Lainnya'];

  String _method = 'Tunai';
  final _refCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _loading = false;
  bool _isPartialPayment = false;

  @override
  void initState() {
    super.initState();
    final initialAmount = widget.customAmount ?? widget.bill.amount;
    _amountCtrl.text = initialAmount.toInt().toString();
  }

  String _formatRp(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  Future<void> _bayar() async {
    final amountText = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amountPaid = double.tryParse(amountText) ?? 0.0;
    final maxAmount = widget.customAmount ?? widget.bill.amount;

    if (amountPaid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Jumlah pembayaran harus lebih dari 0'),
        backgroundColor: AppPalette.errorRed,
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      // Use cumulative payment API if paying from sheet (which could cover outstanding bills)
      await PaymentService.instance.createCumulative(
        customerId: widget.bill.customerId,
        amountPaid: amountPaid,
        paymentMethod: _method,
        referenceNumber: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mencatat pembayaran: $e'),
          backgroundColor: AppPalette.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppPalette.textHintLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPalette.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: AppPalette.successGreen, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Tagihan Berhasil Dibuat',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.textDark)),
            ),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text('Catat pembayaran sekarang?',
                style: TextStyle(fontSize: 13, color: AppPalette.textGrey)),
          ),
          const SizedBox(height: 20),
          // Total tagihan summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.bgBluePale,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.primaryBlue.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Tagihan',
                    style: TextStyle(fontSize: 14, color: AppPalette.textGrey)),
                Text(_formatRp(widget.customAmount ?? widget.bill.amount),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.primaryBlue)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Opsi Pembayaran Sebagian / Lunas
          Row(
            children: [
               Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Lunas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: false,
                    groupValue: _isPartialPayment,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppPalette.primaryBlue,
                    onChanged: (val) {
                       setState(() {
                         _isPartialPayment = val!;
                         _amountCtrl.text = (widget.customAmount ?? widget.bill.amount).toInt().toString();
                       });
                    },
                  ),
               ),
               Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Sebagian', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: true,
                    groupValue: _isPartialPayment,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppPalette.primaryBlue,
                    onChanged: (val) {
                       setState(() {
                         _isPartialPayment = val!;
                         _amountCtrl.text = ""; // clear for custom input
                       });
                    },
                  ),
               ),
            ],
          ),

          if (_isPartialPayment) ...[
             const SizedBox(height: 10),
             TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Jumlah Pembayaran (Rp)',
                labelStyle:
                    const TextStyle(fontSize: 13, color: AppPalette.textGrey),
                filled: true,
                fillColor: AppPalette.bgGrey,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppPalette.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppPalette.primaryBlue, width: 1.5),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          // Metode pembayaran
          const Text('METODE PEMBAYARAN',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textGrey,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _method,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppPalette.bgGrey,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.borderGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppPalette.primaryBlue, width: 1.5),
              ),
            ),
            items: _methods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _method = v!),
          ),
          const SizedBox(height: 14),
          // No. referensi (opsional)
          TextField(
            controller: _refCtrl,
            decoration: InputDecoration(
              labelText: 'No. Referensi (Opsional)',
              labelStyle:
                  const TextStyle(fontSize: 13, color: AppPalette.textGrey),
              filled: true,
              fillColor: AppPalette.bgGrey,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.borderGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppPalette.primaryBlue, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.textGrey,
                  side: const BorderSide(color: AppPalette.textHintLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Nanti',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _bayar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.payments_outlined, size: 18),
                label: Text(_loading ? 'Memproses...' : 'Bayar Sekarang',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }
}

// ─── Customer Picker Sheet ────────────────────────────────────────────────────

class _CustomerPickerSheet extends StatefulWidget {
  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Customer> _customers = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;

    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final page = reset ? 1 : _page;
      final search = _searchCtrl.text.trim();
      final list = await CustomersService.instance.list(
        page: page,
        itemsPerPage: _pageSize,
        search: search.isNotEmpty ? search : null,
        unbilledMonth: now.month,
        unbilledYear: now.year,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _customers = list;
          _page = 1;
        } else {
          _customers.addAll(list);
        }
        _hasMore = list.length == _pageSize;
        _page = page + 1;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.textHintLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Pelanggan',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.textDark),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => _load(reset: true),
                decoration: InputDecoration(
                  hintText: 'Cari nama, ID, atau RT/RW...',
                  prefixIcon: const Icon(Icons.person_search_rounded,
                      color: AppPalette.textGreyLight, size: 22),
                  filled: true,
                  fillColor: AppPalette.bgGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading && _customers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _customers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.people_outline,
                                    size: 48,
                                    color: AppPalette.textGreyLight),
                                SizedBox(height: 12),
                                Text('Pelanggan tidak ditemukan',
                                    style:
                                        TextStyle(color: AppPalette.textGrey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollCtrl,
                            itemCount:
                                _customers.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              if (i == _customers.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                );
                              }
                              final p = _customers[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppPalette.primaryBlue.withOpacity(0.1),
                                  child: const Icon(Icons.person,
                                      color: AppPalette.primaryBlue),
                                ),
                                title: Text(p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                subtitle: Text('${p.id} • RT ${p.rt}/RW ${p.rw}',
                                    style: const TextStyle(
                                        color: AppPalette.textGreyLight,
                                        fontSize: 13)),
                                trailing: Text('Meter: ${p.meterNumber}',
                                    style: const TextStyle(
                                        color: AppPalette.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                onTap: () => Navigator.pop(ctx, p),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
