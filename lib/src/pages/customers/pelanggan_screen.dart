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
  final ScrollController _scrollCtrl = ScrollController();

  String _searchQuery  = '';
  List<String> _selectedRts = [];
  List<String> _selectedRws = [];
  String _filterStatus = 'Semua';
  late bool _showUnbilledOnly;

  List<Customer> _pelangganList = [];
  bool            _isLoading     = false;
  bool            _isLoadingMore = false;
  bool            _hasMore       = true;
  int             _currentPage   = 1;
  static const int _pageSize     = 20;
  String?         _errorMessage;

  final List<String> _rtOptions = [
    'Semua',
    ...List.generate(12, (i) => 'RT ${(i + 1).toString().padLeft(2, '0')}')
  ];
  final List<String> _rwOptions = [
    'Semua',
    ...List.generate(12, (i) => 'RW ${(i + 1).toString().padLeft(2, '0')}')
  ];
  final List<String> _statusOptions = ['Semua', 'Aktif', 'Menunggak'];

  @override
  void initState() {
    super.initState();
    _showUnbilledOnly = widget.filterUnbilledOnly;
    _loadPelanggan(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading && !_isLoadingMore) {
        _loadPelanggan(reset: false);
      }
    }
  }

  Future<void> _loadPelanggan({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _pelangganList = [];
        _hasMore = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final now = DateTime.now();
      
      final rtList = _selectedRts.map((s) => int.parse(s.replaceFirst('RT ', ''))).join(',');
      final rwList = _selectedRws.map((s) => int.parse(s.replaceFirst('RW ', ''))).join(',');

      final data = await CustomersService.instance.list(
        page: _currentPage,
        itemsPerPage: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        rt: rtList.isEmpty ? null : rtList,
        rw: rwList.isEmpty ? null : rwList,
        status: _filterStatus == 'Semua' ? null : _filterStatus.toUpperCase(),
        unbilledMonth: _showUnbilledOnly ? now.month : null,
        unbilledYear: _showUnbilledOnly ? now.year : null,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _pelangganList = data;
        } else {
          _pelangganList.addAll(data);
        }
        _isLoading = false;
        _isLoadingMore = false;
        _currentPage++;
        _hasMore = data.length == _pageSize;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Gagal memuat data: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  void _openFilter() {
    showPelangganFilterSheet(
      context: context,
      selectedRts: _selectedRts,
      selectedRws: _selectedRws,
      filterStatus: _filterStatus,
      rtOptions: _rtOptions,
      rwOptions: _rwOptions,
      statusOptions: _statusOptions,
      onRtsChanged: (v) => setState(() => _selectedRts = v),
      onRwsChanged: (v) => setState(() => _selectedRws = v),
      onStatusChanged: (v) => setState(() => _filterStatus = v),
    ).then((_) {
      _loadPelanggan(reset: true);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bgGrey,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          _buildResultCount(_pelangganList.length),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppPalette.primaryBlue))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildList(_pelangganList),
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
        onSubmitted: (v) {
          setState(() => _searchQuery = v);
          _loadPelanggan(reset: true);
        },
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
                    _loadPelanggan(reset: true);
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
            label: _selectedRts.isEmpty ? 'RT' : '${_selectedRts.length} RT',
            icon: Icons.location_on_outlined,
            active: _selectedRts.isNotEmpty,
            onTap: _openFilter,
          ),
          const SizedBox(width: 8),
          FilterButton(
            label: _selectedRws.isEmpty ? 'RW' : '${_selectedRws.length} RW',
            icon: Icons.location_city_outlined,
            active: _selectedRws.isNotEmpty,
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
               _loadPelanggan(reset: true);
            },
          ),
          const Spacer(),
          if (_selectedRts.isNotEmpty || _selectedRws.isNotEmpty || _filterStatus != 'Semua' || _showUnbilledOnly)
            GestureDetector(
              onTap: () => setState(() {
                _selectedRts  = [];
                _selectedRws  = [];
                _filterStatus = 'Semua';
                _showUnbilledOnly = false;
                _loadPelanggan(reset: true);
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
            onPressed: () => _loadPelanggan(reset: true),
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
    if (items.isEmpty && !_isLoading) {
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
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return PelangganCard(
          customer: items[i],
          onTap: () => _openDetail(items[i]),
        );
      },
    );
  }


  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () async {
        final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const TambahPelangganScreen()),
        );
        if (refresh == true) _loadPelanggan(reset: true);
      },
      backgroundColor: AppPalette.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.person_add_rounded, size: 28),
    );
  }

  Future<void> _openDetail(Customer p) async {
    if (_showUnbilledOnly) {
       final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => CatatMeterScreen(preselectedCustomer: p)),
       );
       if (refresh == true) _loadPelanggan(reset: true);
    } else {
       final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => PelangganDetailScreen(customer: p)),
       );
       if (refresh == true) _loadPelanggan(reset: true);
    }
  }
}
