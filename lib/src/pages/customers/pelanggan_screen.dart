import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/core/models/customer_model.dart';
import 'package:pamsimas_app/src/core/services/customers_service.dart';
import 'package:pamsimas_app/src/pages/customers/filter_button.dart';
import 'package:pamsimas_app/src/pages/customers/pelanggan_card.dart';
import 'package:pamsimas_app/src/pages/customers/pelanggan_detail_screen.dart';
import 'package:pamsimas_app/src/pages/customers/pelanggan_filter_sheet.dart';
import 'package:pamsimas_app/src/pages/customers/tambah_pelanggan_screen.dart';
import 'package:pamsimas_app/src/pages/meter/catat_meter_screen.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';


class PelangganScreen extends StatefulWidget {
  final bool filterUnbilledOnly;
  const PelangganScreen({super.key, this.filterUnbilledOnly = false});

  @override
  State<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery  = '';
  String _filterRt     = 'Semua';
  String _filterRw     = 'Semua';
  String _filterStatus = 'Semua';
  late bool _showUnbilledOnly;

  List<Customer> _pelangganList = [];
  bool            _isLoading     = false;
  String?         _errorMessage;

  final List<String> _rtOptions = [
    'Semua', 'RT 01', 'RT 02', 'RT 03', 'RT 04',
  ];
  final List<String> _rwOptions = [
    'Semua', 'RW 01', 'RW 02', 'RW 03',
  ];
  final List<String> _statusOptions = ['Semua', 'Aktif', 'Menunggak'];

  @override
  void initState() {
    super.initState();
    _showUnbilledOnly = widget.filterUnbilledOnly;
    _loadPelanggan();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  Future<void> _loadPelanggan() async {
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });
    try {
      final now = DateTime.now();
      final data = await CustomersService.instance.list(
        unbilledMonth: _showUnbilledOnly ? now.month : null,
        unbilledYear: _showUnbilledOnly ? now.year : null,
        itemsPerPage: 500,
      );
      if (!mounted) return;
      setState(() {
        _pelangganList = data;
        _isLoading     = false;
      });
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading    = false;
        _errorMessage = 'Gagal memuat data.\nPeriksa koneksi internet.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading    = false;
        _errorMessage = 'Terjadi kesalahan.\nSilakan coba lagi.';
      });
    }
  }

  List<Customer> get _filtered {
    return _pelangganList.where((p) {
      final q           = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.meterNumber.toLowerCase().contains(q) ||
          p.rt.toLowerCase().contains(q) ||
          p.rw.toLowerCase().contains(q);
      final matchRt     = _filterRt == 'Semua'    || 'RT ${p.rt}' == _filterRt;
      final matchRw     = _filterRw == 'Semua'    || 'RW ${p.rw}' == _filterRw;
      final matchStatus = _filterStatus == 'Semua'  ||
          (_filterStatus == 'Aktif'     && p.status.toLowerCase() == 'aktif') ||
          (_filterStatus == 'Menunggak' && p.status.toLowerCase() == 'menunggak');
      return matchSearch && matchRt && matchRw && matchStatus;
    }).toList();
  }


  Future<void> _openDetail(Customer p) async {
    if (_showUnbilledOnly) {
       // Navigate directly to Catat Meter page with pre-selected customer
       final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => CatatMeterScreen(preselectedCustomer: p)),
       );
       if (refresh == true) _loadPelanggan();
    } else {
       final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => PelangganDetailScreen(customer: p)),
       );
       if (refresh == true) _loadPelanggan();
    }
  }

  void _openFilter() {
    showPelangganFilterSheet(
      context: context,
      filterRt: _filterRt,
      filterRw: _filterRw,
      filterStatus: _filterStatus,
      rtOptions: _rtOptions,
      rwOptions: _rwOptions,
      statusOptions: _statusOptions,
      onRtChanged: (v) => setState(() => _filterRt = v),
      onRwChanged: (v) => setState(() => _filterRw = v),
      onStatusChanged: (v) => setState(() => _filterStatus = v),
    );
  }


  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppPalette.bgGrey,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          _buildResultCount(filtered.length),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppPalette.primaryBlue))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildList(filtered),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppPalette.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Pelanggan',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: 'Filter',
          onPressed: _openFilter,
        ),
      ],
    );
  }


  Widget _buildSearchBar() {
    return Container(
      color: AppPalette.primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Cari nama, ID, atau RT/RW...',
          hintStyle: const TextStyle(color: AppPalette.textGreyLight),
          prefixIcon: const Icon(Icons.search, color: AppPalette.textGrey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppPalette.textGrey, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }


  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          FilterButton(
            label: _filterRt == 'Semua' ? 'RT' : _filterRt,
            icon: Icons.location_on_outlined,
            active: _filterRt != 'Semua',
            onTap: _openFilter,
          ),
          const SizedBox(width: 8),
          FilterButton(
            label: _filterRw == 'Semua' ? 'RW' : _filterRw,
            icon: Icons.location_city_outlined,
            active: _filterRw != 'Semua',
            onTap: _openFilter,
          ),
          const SizedBox(width: 8),
          FilterButton(
            label: _showUnbilledOnly ? 'Belum Dicatat' : 'Semua',
            icon: Icons.pending_actions_outlined,
            active: _showUnbilledOnly,
            onTap: () {
               setState(() {
                  _showUnbilledOnly = !_showUnbilledOnly;
               });
               _loadPelanggan();
            },
          ),
          const Spacer(),
          if (_filterRt != 'Semua' || _filterRw != 'Semua' || _filterStatus != 'Semua' || _showUnbilledOnly)
            GestureDetector(
              onTap: () => setState(() {
                _filterRt     = 'Semua';
                _filterRw     = 'Semua';
                _filterStatus = 'Semua';
                _showUnbilledOnly = false;
                _loadPelanggan();
              }),
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: AppPalette.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildResultCount(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count pelanggan ditemukan',
          style: const TextStyle(fontSize: 13, color: AppPalette.textGrey),
        ),
      ),
    );
  }


  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: AppPalette.textHintLight),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppPalette.textGreyLight, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadPelanggan,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildList(List<Customer> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppPalette.textHintLight),
            SizedBox(height: 16),
            Text(
              'Tidak ada pelanggan\nyang sesuai pencarian',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.textGreyLight, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => PelangganCard(
        customer: items[i],
        onTap: () => _openDetail(items[i]),
      ),
    );
  }


  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () async {
        final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const TambahPelangganScreen()),
        );
        if (refresh == true) _loadPelanggan();
      },
      backgroundColor: AppPalette.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.person_add_rounded, size: 28),
    );
  }
}
