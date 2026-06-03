import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pamsimas_app/src/core/models/petugas_model.dart';
import 'package:pamsimas_app/src/core/services/petugas_service.dart';

// ─── Tambah / Edit Petugas Screen ─────────────────────────────────────────────

class TambahPetugasScreen extends StatefulWidget {
  const TambahPetugasScreen({Key? key, this.existing}) : super(key: key);

  /// When non-null, the form is in edit mode.
  final PetugasModel? existing;

  @override
  State<TambahPetugasScreen> createState() => _TambahPetugasScreenState();
}

class _TambahPetugasScreenState extends State<TambahPetugasScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color bgGrey = Color(0xFFF2F4F7);

  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.officer;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existing!;
      _namaCtrl.text = p.name;
      _usernameCtrl.text = p.username;
      _emailCtrl.text = p.email;
      _phoneCtrl.text = p.phone ?? '';
      _addressCtrl.text = p.address ?? '';
      _selectedRole = p.role;
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  String? _validateNama(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
    if (v.trim().length < 2) return 'Nama minimal 2 karakter';
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(v.trim())) {
      return 'Username hanya huruf kecil dan angka';
    }
    if (v.trim().length < 2 || v.trim().length > 20) {
      return 'Username 2–20 karakter';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[\w\-.]+@[\w\-.]+\.[a-z]{2,}$').hasMatch(v.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 9 || digits.length > 15) return 'Nomor telepon tidak valid';
    if (!digits.startsWith('0') && !digits.startsWith('62')) {
      return 'Nomor harus diawali 0 atau 62';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (_isEdit && (v == null || v.isEmpty)) return null; // optional on edit
    if (v == null || v.isEmpty) return 'Password wajib diisi';
    if (v.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _onSimpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isEdit) {
        await PetugasService.instance.update(
          widget.existing!.id,
          PetugasUpdateRequest(
            name: _namaCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
            role: _selectedRole,
          ),
        );
      } else {
        await PetugasService.instance.create(
          PetugasCreateRequest(
            name: _namaCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
            role: _selectedRole,
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  void _onBatal() => Navigator.pop(context);

  Future<void> _showResetPasswordDialog() async {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;

    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reset Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Masukkan password baru untuk petugas ini.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    hintText: 'Minimal 8 karakter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                          size: 18),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    hintText: 'Ulangi password baru',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            TextButton(
              onPressed: () async {
                final pwd = passwordCtrl.text.trim();
                final confirm = confirmCtrl.text.trim();

                if (pwd.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Password harus diisi')),
                  );
                  return;
                }
                if (pwd.length < 8) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Password minimal 8 karakter')),
                  );
                  return;
                }
                if (pwd != confirm) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Password tidak cocok')),
                  );
                  return;
                }

                try {
                  await PetugasService.instance
                      .resetPassword(widget.existing!.id, pwd);
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password berhasil direset'),
                      backgroundColor: Color(0xFF1565C0),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal reset password: $e'),
                      backgroundColor: const Color(0xFFC62828),
                    ),
                  );
                }
              },
              child: const Text('Reset',
                  style: TextStyle(
                      color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            children: [
              _buildAvatarPreview(),
              const SizedBox(height: 28),
              _sectionLabel('Informasi Akun'),
              const SizedBox(height: 12),
              _buildNamaField(),
              const SizedBox(height: 16),
              _buildUsernameField(),
              const SizedBox(height: 16),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildRoleDropdown(),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                _buildPasswordField(),
              ],
              const SizedBox(height: 24),
              _sectionLabel('Informasi Kontak'),
              const SizedBox(height: 12),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildAddressField(),
              if (_isEdit) ...[const SizedBox(height: 24), _buildResetPasswordButton()],
              const SizedBox(height: 36),
              _buildSimpanButton(),
              const SizedBox(height: 12),
              _buildBatalButton(),
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
        _isEdit ? 'Edit Petugas' : 'Tambah Petugas',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  // ─── Avatar Preview ───────────────────────────────────────────────────────

  Widget _buildAvatarPreview() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _namaCtrl,
      builder: (_, val, __) {
        final words =
            val.text.trim().split(' ').where((w) => w.isNotEmpty).toList();
        final initials =
            words.take(2).map((w) => w[0].toUpperCase()).join();
        return Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: initials.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 36)
                  : Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  // ─── Fields ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildNamaField() {
    return _fieldCard(
      child: TextFormField(
        controller: _namaCtrl,
        textCapitalization: TextCapitalization.words,
        validator: _validateNama,
        decoration: _inputDecoration(
          label: 'Nama Lengkap',
          hint: 'Contoh: Budi Santoso',
          icon: Icons.person_outline_rounded,
          required: true,
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return _fieldCard(
      child: TextFormField(
        controller: _usernameCtrl,
        validator: _validateUsername,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
          LengthLimitingTextInputFormatter(20),
        ],
        decoration: _inputDecoration(
          label: 'Username',
          hint: 'Contoh: budisantoso',
          icon: Icons.alternate_email,
          required: true,
        ).copyWith(
          helperText: 'Hanya gunakan huruf kecil dan angka (tanpa spasi)',
          helperMaxLines: 2,
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return _fieldCard(
      child: TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        validator: _validateEmail,
        decoration: _inputDecoration(
          label: 'Email',
          hint: 'Contoh: budi@email.com',
          icon: Icons.email_outlined,
          required: true,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return _fieldCard(
      child: TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        validator: _validatePassword,
        decoration: _inputDecoration(
          label: 'Password',
          hint: 'Minimal 8 karakter',
          icon: Icons.lock_outline,
          required: true,
        ).copyWith(
          helperText: 'Password harus terdiri dari minimal 8 karakter.',
          helperMaxLines: 2,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return _fieldCard(
      child: TextFormField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d\-+]')),
          LengthLimitingTextInputFormatter(16),
        ],
        validator: _validatePhone,
        decoration: _inputDecoration(
          label: 'Nomor Telepon',
          hint: 'Contoh: 0812-3456-7890',
          icon: Icons.phone_outlined,
          required: false,
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return _fieldCard(
      child: TextFormField(
        controller: _addressCtrl,
        maxLines: 3,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDecoration(
          label: 'Alamat',
          hint: 'Jl. Mawar No. 5, RT 01/RW 02',
          icon: Icons.location_on_outlined,
          required: false,
        ),
      ),
    );
  }

  Widget _fieldCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required bool required,
  }) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: primaryBlue, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // ─── Buttons ──────────────────────────────────────────────────────────────

  Widget _buildSimpanButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _onSimpan,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryBlue.withOpacity(0.6),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                _isEdit ? 'Simpan Perubahan' : 'Simpan',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return _fieldCard(
      child: DropdownButtonFormField<UserRole>(
        value: _selectedRole,
        decoration: _inputDecoration(
          label: 'Role',
          hint: 'Pilih role',
          icon: Icons.shield_outlined,
          required: true,
        ),
        items: UserRole.values
            .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedRole = v);
        },
      ),
    );
  }

  Widget _buildResetPasswordButton() {    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isSubmitting ? null : _showResetPasswordDialog,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC62828),
          side: const BorderSide(color: Color(0xFFC62828)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.vpn_key_rounded, size: 18),
        label: const Text('Reset Password',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBatalButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isSubmitting ? null : _onBatal,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6B7280),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('Batal',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
