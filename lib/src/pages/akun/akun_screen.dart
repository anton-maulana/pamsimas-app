import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pamsimas_app/src/core/services/auth_service.dart';
import 'package:pamsimas_app/src/pages/login/login_screen.dart';
import 'package:pamsimas_app/src/pages/petugas/petugas_screen.dart';

class UserProfile {
  final int id;
  final String nama;
  final String username;
  final String email;
  final String telepon;
  final String alamat;
  final String wilayah;
  final String role;

  const UserProfile({
    required this.id,
    required this.nama,
    required this.username,
    required this.email,
    required this.telepon,
    required this.alamat,
    required this.wilayah,
    required this.role,
  });

  String get roleLabel => role.toLowerCase() == 'superadmin' ? 'Superadmin' : 'Petugas';
  String get initials => nama.trim().split(' ').where((w) => w.isNotEmpty)
                                 .take(2).map((w) => w[0].toUpperCase()).join();
}

class AkunScreen extends StatefulWidget {
  const AkunScreen({Key? key}) : super(key: key);

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color bgGrey      = Color(0xFFF2F4F7);

  UserProfile? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await AuthService.instance.getCurrentUserFromServer();
    if (data != null) {
      if (mounted) {
        setState(() {
          _user = UserProfile(
            id: data['id'] as int,
            nama: data['name'] ?? '',
            username: data['username'] ?? '',
            email: data['email'] ?? '',
            telepon: data['phone'] ?? '-',
            alamat: data['address'] ?? '-',
            wilayah: '-', 
            role: data['role'] ?? 'officer',
          );
          _isLoading = false;
        });
      }
    } else {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const Scaffold(body: Center(child: Text('Gagal memuat profil')));
    }

    final user = _user!;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            _buildProfileCard(user),
            const SizedBox(height: 20),
            _buildInfoCard(user),
            const SizedBox(height: 20),
            _buildMenuCard(),
            if (user.role.toLowerCase() == 'superadmin') ...[
              const SizedBox(height: 20),
              _buildAdminCard(),
            ],
            const SizedBox(height: 32),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Akun',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile user) {
    final isAdmin = user.role.toLowerCase() == 'superadmin';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
              border: Border.all(color: Colors.white.withOpacity(0.7), width: 2.5),
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.nama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isAdmin
                  ? const Color(0xFFFF8F00).withOpacity(0.25)
                  : Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAdmin
                    ? const Color(0xFFFFE082)
                    : Colors.white.withOpacity(0.60),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings_outlined : Icons.badge_outlined,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  user.roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserProfile user) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Informasi Akun', Icons.contact_page_outlined),
          const SizedBox(height: 14),
          _infoRow(
            icon: Icons.alternate_email,
            label: 'Username',
            value: user.username,
          ),
          const _Divider(),
          _infoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          const _Divider(),
          _infoRow(
            icon: Icons.phone_outlined,
            label: 'Nomor Telepon',
            value: user.telepon,
          ),
          const _Divider(),
          _infoRow(
            icon: Icons.location_on_outlined,
            label: 'Alamat',
            value: user.alamat,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Pengaturan Akun', Icons.settings_outlined),
          const SizedBox(height: 8),
          _menuItem(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF2E7D32),
            label: 'Ganti Password',
            subtitle: 'Perbarui kata sandi akun',
            onTap: () => _showSnackBar('Fitur segera hadir'),
          ),
          const _Divider(),
          _menuItem(
            icon: Icons.sync_rounded,
            iconColor: const Color(0xFF00838F),
            label: 'Sinkronisasi Data',
            subtitle: 'Sinkronkan data ke server',
            onTap: _doSinkronisasi,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Administrasi', Icons.admin_panel_settings_outlined,
              color: const Color(0xFFE65100)),
          const SizedBox(height: 8),
          _menuItem(
            icon: Icons.badge_outlined,
            iconColor: const Color(0xFF283593),
            label: 'Kelola Petugas',
            subtitle: 'Tambah, edit, atau hapus petugas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PetugasScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Keluar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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

  Widget _sectionHeader(String title, IconData icon, {Color? color}) {
    final c = color ?? primaryBlue;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String   label,
    required String   value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color    iconColor,
    required String   label,
    required String   subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF1565C0), size: 22),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.instance.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _doSinkronisasi() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SinkronisasiDialog(
        onComplete: () {
          Navigator.pop(ctx);
          _showSnackBar('Data berhasil disinkronkan');
        },
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFF3F4F6));
  }
}

class _SinkronisasiDialog extends StatefulWidget {
  const _SinkronisasiDialog({required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<_SinkronisasiDialog> createState() => _SinkronisasiDialogState();
}

class _SinkronisasiDialogState extends State<_SinkronisasiDialog> {
  static const Color primaryBlue = Color(0xFF1565C0);
  String _status = 'Menyambungkan ke server...';
  double _progress = 0;
  bool   _done     = false;

  @override
  void initState() {
    super.initState();
    _runSync();
  }

  Future<void> _runSync() async {
    final steps = [
      (0.25, 'Mengambil data pelanggan...'),
      (0.50, 'Sinkronisasi tagihan...'),
      (0.75, 'Memperbarui data meter...'),
      (1.00, 'Selesai!'),
    ];
    for (final step in steps) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _progress = step.$1;
        _status   = step.$2;
        if (_progress >= 1.0) _done = true;
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryBlue.withOpacity(0.10), shape: BoxShape.circle),
              child: _done
                  ? const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 36)
                  : const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3, color: primaryBlue)),
            ),
            const SizedBox(height: 20),
            const Text('Sinkronisasi Data', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_status, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: _progress, minHeight: 8, backgroundColor: const Color(0xFFE5E7EB), color: primaryBlue),
            ),
            const SizedBox(height: 10),
            Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryBlue)),
          ],
        ),
      ),
    );
  }
}
