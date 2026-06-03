import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/core/models/petugas_model.dart';
import 'package:pamsimas_app/src/core/services/petugas_service.dart';
import 'package:pamsimas_app/src/pages/petugas/tambah_petugas_screen.dart';

// ─── Petugas Screen ───────────────────────────────────────────────────────────

class PetugasScreen extends StatefulWidget {
  const PetugasScreen({Key? key}) : super(key: key);

  @override
  State<PetugasScreen> createState() => _PetugasScreenState();
}

class _PetugasScreenState extends State<PetugasScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color bgGrey = Color(0xFFF2F4F7);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<PetugasModel> _petugas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPetugas();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadPetugas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await PetugasService.instance.list();
      final counts = await Future.wait(
        list.map((p) => PetugasService.instance.customerCount(p.id)),
      );
      final enriched = [
        for (int i = 0; i < list.length; i++)
          list[i].copyWith(customerCount: counts[i]),
      ];
      if (!mounted) return;
      setState(() {
        _petugas = enriched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─── Filtering ────────────────────────────────────────────────────────────

  List<PetugasModel> get _filtered {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return _petugas;
    return _petugas.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.phone ?? '').replaceAll('-', '').contains(q.replaceAll('-', ''));
    }).toList();
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Future<void> _openTambah() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TambahPetugasScreen()),
    );
    if (added == true) {
      _showSnack('Petugas berhasil ditambahkan');
      await _loadPetugas();
    }
  }

  Future<void> _openEdit(PetugasModel p) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TambahPetugasScreen(existing: p)),
    );
    if (updated == true) {
      _showSnack('Data petugas diperbarui');
      await _loadPetugas();
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  void _confirmDelete(PetugasModel p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Petugas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
          'Hapus data "${p.name}"? Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deletePetugas(p);
            },
            child: const Text('Hapus',
                style: TextStyle(
                    color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePetugas(PetugasModel p) async {
    try {
      await PetugasService.instance.delete(p.id);
      _showSnack('Petugas dihapus');
      await _loadPetugas();
    } catch (e) {
      _showSnack('Gagal menghapus: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: primaryBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          if (!_isLoading && _error == null)
            _buildResultCount(_filtered.length),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text('Petugas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: _loadPetugas,
        ),
      ],
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Cari nama atau nomor telepon...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: Color(0xFF6B7280), size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ─── Result Count ─────────────────────────────────────────────────────────

  Widget _buildResultCount(int count) {
    final totalCustomers = _petugas.fold(0, (s, p) => s + p.customerCount);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('$count petugas',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const Spacer(),
          Text('Total pelanggan: $totalCustomers',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text('Gagal memuat data petugas',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPetugas,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              ),
            ],
          ),
        ),
      );
    }
    return _buildList(_filtered);
  }

  // ─── List ─────────────────────────────────────────────────────────────────

  Widget _buildList(List<PetugasModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty ? 'Belum ada petugas' : 'Tidak ditemukan',
              style: const TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCard(items[i]),
    );
  }

  // ─── Petugas Card ─────────────────────────────────────────────────────────

  Widget _buildCard(PetugasModel p) {
    final initials = p.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openEdit(p),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      _infoRow(Icons.alternate_email, p.username),
                      if (p.phone != null && p.phone!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _infoRow(Icons.phone_outlined, p.phone!),
                      ],
                      if (p.address != null && p.address!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _infoRow(Icons.location_on_outlined, p.address!),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_alt_outlined,
                                    size: 13, color: Color(0xFF1565C0)),
                                const SizedBox(width: 5),
                                Text('${p.customerCount} pelanggan',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1565C0))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRoleBadge(p.role),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildPopupMenu(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    final isSuperadmin = role == UserRole.superadmin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSuperadmin
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuperadmin ? Icons.admin_panel_settings : Icons.badge_outlined,
            size: 13,
            color: isSuperadmin
                ? const Color(0xFFE65100)
                : const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 5),
          Text(
            role.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSuperadmin
                  ? const Color(0xFFE65100)
                  : const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(PetugasModel p) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: Color(0xFF9CA3AF), size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 18, color: Color(0xFF374151)),
            SizedBox(width: 10),
            Text('Edit', style: TextStyle(fontSize: 14)),
          ]),
        ),
        const PopupMenuItem(
          value: 'hapus',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded,
                size: 18, color: Color(0xFFC62828)),
            SizedBox(width: 10),
            Text('Hapus',
                style:
                    TextStyle(fontSize: 14, color: Color(0xFFC62828))),
          ]),
        ),
      ],
      onSelected: (v) {
        if (v == 'edit') _openEdit(p);
        if (v == 'hapus') _confirmDelete(p);
      },
    );
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _openTambah,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Tambah Petugas',
          style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
