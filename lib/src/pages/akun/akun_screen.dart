import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pamsimas_app/src/pages/login/login_screen.dart';
import 'package:pamsimas_app/src/pages/petugas/petugas_screen.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

enum UserRole { petugas, admin }

class UserProfile {
  final String   id;
  final String   nama;
  final String   telepon;
  final String   alamat;
  final String   wilayah;
  final UserRole role;

  const UserProfile({
    required this.id,
    required this.nama,
    required this.telepon,
    required this.alamat,
    required this.wilayah,
    required this.role,
  });

  UserProfile copyWith({
    String?   nama,
    String?   telepon,
    String?   alamat,
    String?   wilayah,
    UserRole? role,
  }) {
    return UserProfile(
      id:       id,
      nama:     nama     ?? this.nama,
      telepon:  telepon  ?? this.telepon,
      alamat:   alamat   ?? this.alamat,
      wilayah:  wilayah  ?? this.wilayah,
      role:     role     ?? this.role,
    );
  }

  String get roleLabel    => role == UserRole.admin ? 'Admin' : 'Petugas';
  String get initials     => nama.trim().split(' ').where((w) => w.isNotEmpty)
                                 .take(2).map((w) => w[0].toUpperCase()).join();
}

// ─── Demo Data ────────────────────────────────────────────────────────────────

const _demoUser = UserProfile(
  id:      'USR-001',
  nama:    'Ahmad Fauzi',
  telepon: '0812-3456-7890',
  alamat:  'Jl. Melati No. 7, Desa Sumber Makmur',
  wilayah: 'RT 02 / RW 01',
  role:    UserRole.admin,
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class AkunScreen extends StatefulWidget {
  const AkunScreen({Key? key}) : super(key: key);

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color bgGrey      = Color(0xFFF2F4F7);

  UserProfile _user = _demoUser;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildMenuCard(),
          if (_user.role == UserRole.admin) ...[
            const SizedBox(height: 20),
            _buildAdminCard(),
          ],
          const SizedBox(height: 32),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────────

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
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifikasi',
          onPressed: () => _showSnackBar('Tidak ada notifikasi baru'),
        ),
      ],
    );
  }

  // ─── Profile Card ──────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    final isAdmin = _user.role == UserRole.admin;
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
          // Avatar
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
                _user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Name
          Text(
            _user.nama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Role badge
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
                  _user.roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Wilayah
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.80), size: 14),
              const SizedBox(width: 4),
              Text(
                _user.wilayah,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Info Card ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Informasi Kontak', Icons.contact_page_outlined),
          const SizedBox(height: 14),
          _infoRow(
            icon: Icons.phone_outlined,
            label: 'Nomor Telepon',
            value: _user.telepon,
          ),
          const _Divider(),
          _infoRow(
            icon: Icons.location_on_outlined,
            label: 'Alamat',
            value: _user.alamat,
          ),
          const _Divider(),
          _infoRow(
            icon: Icons.map_outlined,
            label: 'Wilayah',
            value: _user.wilayah,
          ),
        ],
      ),
    );
  }

  // ─── Menu Card ─────────────────────────────────────────────────────────────

  Widget _buildMenuCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Pengaturan Akun', Icons.settings_outlined),
          const SizedBox(height: 8),
          _menuItem(
            icon: Icons.edit_outlined,
            iconColor: const Color(0xFF1565C0),
            label: 'Edit Profil',
            subtitle: 'Ubah nama, telepon, dan alamat',
            onTap: _showEditProfilSheet,
          ),
          const _Divider(),
          _menuItem(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF2E7D32),
            label: 'Ganti Password',
            subtitle: 'Perbarui kata sandi akun',
            onTap: _showGantiPasswordSheet,
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

  // ─── Admin Card ────────────────────────────────────────────────────────────

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
          const _Divider(),
          _menuItem(
            icon: Icons.manage_accounts_outlined,
            iconColor: const Color(0xFF6A1B9A),
            label: 'Manajemen Pengguna',
            subtitle: 'Kelola hak akses pengguna',
            onTap: () => _showSnackBar('Fitur segera hadir'),
          ),
        ],
      ),
    );
  }

  // ─── Logout Button ─────────────────────────────────────────────────────────

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

  // ─── Shared Widgets ────────────────────────────────────────────────────────

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
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB), size: 22),
          ],
        ),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

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
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, anim, __) => const LoginScreen(),
                  transitionsBuilder: (_, anim, __, child) => FadeTransition(
                    opacity: anim,
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
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

  // ─── Edit Profil Sheet ─────────────────────────────────────────────────────

  void _showEditProfilSheet() {
    final namaCtrl    = TextEditingController(text: _user.nama);
    final telCtrl     = TextEditingController(text: _user.telepon);
    final alamatCtrl  = TextEditingController(text: _user.alamat);
    final wilayahCtrl = TextEditingController(text: _user.wilayah);
    final formKey     = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _SheetScaffold(
          title: 'Edit Profil',
          child: Form(
            key: formKey,
            child: Column(
              children: [
                _SheetField(
                  ctrl: namaCtrl,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                  textCap: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                _SheetField(
                  ctrl: telCtrl,
                  label: 'Nomor Telepon',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\-+]')),
                    LengthLimitingTextInputFormatter(16),
                  ],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Telepon wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                _SheetField(
                  ctrl: alamatCtrl,
                  label: 'Alamat',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                  textCap: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                _SheetField(
                  ctrl: wilayahCtrl,
                  label: 'Wilayah (RT/RW)',
                  icon: Icons.map_outlined,
                ),
                const SizedBox(height: 24),
                _SheetSaveButton(
                  label: 'Simpan Perubahan',
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    setState(() {
                      _user = _user.copyWith(
                        nama:    namaCtrl.text.trim(),
                        telepon: telCtrl.text.trim(),
                        alamat:  alamatCtrl.text.trim(),
                        wilayah: wilayahCtrl.text.trim(),
                      );
                    });
                    Navigator.pop(ctx);
                    _showSnackBar('Profil berhasil diperbarui');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      namaCtrl.dispose();
      telCtrl.dispose();
      alamatCtrl.dispose();
      wilayahCtrl.dispose();
    });
  }

  // ─── Ganti Password Sheet ──────────────────────────────────────────────────

  void _showGantiPasswordSheet() {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    final formKey  = GlobalKey<FormState>();
    bool showOld  = false;
    bool showNew  = false;
    bool showConf = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _SheetScaffold(
          title: 'Ganti Password',
          child: Form(
            key: formKey,
            child: Column(
              children: [
                _SheetField(
                  ctrl: oldCtrl,
                  label: 'Password Lama',
                  icon: Icons.lock_outline,
                  obscureText: !showOld,
                  suffixIcon: IconButton(
                    icon: Icon(showOld ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setSheetState(() => showOld = !showOld),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password lama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                _SheetField(
                  ctrl: newCtrl,
                  label: 'Password Baru',
                  icon: Icons.lock_reset_outlined,
                  obscureText: !showNew,
                  suffixIcon: IconButton(
                    icon: Icon(showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setSheetState(() => showNew = !showNew),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password baru wajib diisi';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _SheetField(
                  ctrl: confCtrl,
                  label: 'Konfirmasi Password',
                  icon: Icons.lock_reset_outlined,
                  obscureText: !showConf,
                  suffixIcon: IconButton(
                    icon: Icon(showConf ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setSheetState(() => showConf = !showConf),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi wajib diisi';
                    if (v != newCtrl.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _SheetSaveButton(
                  label: 'Simpan Password',
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    _showSnackBar('Password berhasil diubah');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      oldCtrl.dispose();
      newCtrl.dispose();
      confCtrl.dispose();
    });
  }

  // ─── Sinkronisasi ──────────────────────────────────────────────────────────

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

// ─── Private Helpers ──────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFF3F4F6));
  }
}

// ─── Bottom Sheet Scaffold ────────────────────────────────────────────────────

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet Text Field ─────────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.textCap = TextCapitalization.none,
    this.maxLines = 1,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController        ctrl;
  final String                       label;
  final IconData                     icon;
  final TextInputType?               keyboardType;
  final List<TextInputFormatter>?    inputFormatters;
  final TextCapitalization           textCap;
  final int                          maxLines;
  final bool                         obscureText;
  final Widget?                      suffixIcon;
  final FormFieldValidator<String>?  validator;

  static const Color _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:          ctrl,
      keyboardType:        keyboardType,
      inputFormatters:     inputFormatters,
      textCapitalization:  textCap,
      maxLines:            obscureText ? 1 : maxLines,
      obscureText:         obscureText,
      validator:           validator,
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: _blue, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled:     true,
        fillColor:  const Color(0xFFF9FAFB),
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
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
        ),
      ),
    );
  }
}

// ─── Sheet Save Button ────────────────────────────────────────────────────────

class _SheetSaveButton extends StatelessWidget {
  const _SheetSaveButton({required this.label, required this.onPressed});

  final String        label;
  final VoidCallback  onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ─── Sinkronisasi Dialog ──────────────────────────────────────────────────────

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
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: _done
                  ? const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 36)
                  : const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: primaryBlue,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sinkronisasi Data',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E7EB),
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
