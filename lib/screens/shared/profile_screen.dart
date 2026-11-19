// lib/screens/shared/profile_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../widgets/app_widgets.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'admin';
  String _fullName = 'Administrator';
  String _nip = '-';
  bool _loading = true;
  bool _isEditing = false;
  bool _savingProfile = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _nipController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _nipController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _nipController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _loading = true);
    try {
      // Ambil data profil riil langsung dari database melalui API /me
      final me = await ApiService.get('/me');
      if (me is Map<String, dynamic>) {
        final nama = me['nama'] as String? ?? 'Administrator';
        final username = me['username'] as String? ?? 'admin';
        final nip = me['nip'] as String? ?? '-';

        if (mounted) {
          setState(() {
            _fullName = nama;
            _username = username;
            _nip = (nip.isEmpty) ? '-' : nip;
            _nameController.text = _fullName;
            _usernameController.text = _username;
            _nipController.text = _nip == '-' ? '' : _nip;
            _loading = false;
          });
          return;
        }
      }
      throw Exception('Data profil tidak valid');
    } catch (_) {
      // Fallback ke penyimpanan lokal jika offline
      final username = await ApiService.getUsername();
      final fullName = await ApiService.getFullName();
      final nip = await ApiService.getNip();
      if (mounted) {
        setState(() {
          _username = username ?? 'admin';
          _fullName = fullName ?? 'Administrator';
          _nip = nip ?? '-';
          _nameController.text = _fullName;
          _usernameController.text = _username;
          _nipController.text = _nip == '-' ? '' : _nip;
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);

    try {
      final newName = _nameController.text.trim();
      final newUsername = _usernameController.text.trim().toLowerCase();
      final newNip = _nipController.text.trim();

      // Kirim pembaruan ke database
      await ApiService.updateProfile(
        fullName: newName,
        username: newUsername,
        nip: newNip.isEmpty ? '-' : newNip,
      );

      if (mounted) {
        setState(() {
          _fullName = newName;
          _username = newUsername;
          _nip = newNip.isEmpty ? '-' : newNip;
          _savingProfile = false;
          _isEditing = false;
        });
        showSuccess(context, 'Profil berhasil diperbarui dan tersimpan di database!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingProfile = false);
        showError(context, e.toString());
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: kSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_outline, size: 20, color: kBrandAccent),
                            SizedBox(width: 8),
                            Text(
                              'Ubah Kata Sandi',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextMain),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: kTextMuted),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: kBorder),
                    const SizedBox(height: 14),

                    // Password Lama
                    const Text('Kata Sandi Saat Ini *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: oldPassCtrl,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        hintText: 'Masukkan kata sandi lama',
                        hintStyle: const TextStyle(fontSize: 12, color: kTextSubtle),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: kTextMuted),
                          onPressed: () => setS(() => obscureOld = !obscureOld),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Kata sandi saat ini wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    // Password Baru
                    const Text('Kata Sandi Baru *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        hintText: 'Minimal 6 karakter',
                        hintStyle: const TextStyle(fontSize: 12, color: kTextSubtle),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: kTextMuted),
                          onPressed: () => setS(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Kata sandi baru wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Konfirmasi Password Baru
                    const Text('Konfirmasi Kata Sandi Baru *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Ketik ulang kata sandi baru',
                        hintStyle: const TextStyle(fontSize: 12, color: kTextSubtle),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: kTextMuted),
                          onPressed: () => setS(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Konfirmasi wajib diisi';
                        if (v != newPassCtrl.text) return 'Kata sandi baru tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: kTextMuted)),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Simpan Sandi',
                          icon: Icons.check,
                          isLoading: saving,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setS(() => saving = true);
                            try {
                              await ApiService.changePassword(
                                oldPassword: oldPassCtrl.text,
                                newPassword: newPassCtrl.text,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                showSuccess(context, 'Kata sandi berhasil diperbarui di database!');
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                showError(context, e.toString());
                              }
                            } finally {
                              setS(() => saving = false);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: kSurface,
        title: const Row(
          children: [
            Icon(Icons.logout, size: 20, color: kColorDanger),
            SizedBox(width: 8),
            Text('Keluar Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sistem SIPELA? Sesi aktif Anda akan diakhiri.',
          style: TextStyle(fontSize: 13, color: kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: kTextMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kColorDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
            child: const Text('Ya, Keluar Akun', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.clearAuth();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextMain),
        ),
        backgroundColor: kSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextMain, size: 20),
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: kBrandAccent),
            tooltip: 'Segarkan Data',
            onPressed: _loadProfileData,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const LoadingWidget(message: 'Memuat profil...')
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Kartu Utama Profil ──
                      CleanCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Avatar, Nama, @username, Badge Admin
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: kBrandPrimary,
                                  child: Text(
                                    getInitial(_fullName),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _fullName,
                                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: kTextMain),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            '@$_username',
                                            style: const TextStyle(fontSize: 12, color: kTextMuted, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: const Text(
                                              'Admin',
                                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kBrandAccent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isEditing)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _nameController.text = _fullName;
                                        _usernameController.text = _username;
                                        _nipController.text = _nip == '-' ? '' : _nip;
                                        _isEditing = true;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_outlined, size: 13, color: kBrandAccent),
                                          SizedBox(width: 4),
                                          Text(
                                            'Edit',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kBrandAccent),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: kBorder),
                            const SizedBox(height: 14),

                            if (!_isEditing) ...[
                              // VIEW MODE
                              _infoTile(icon: Icons.person_outline, label: 'Nama Lengkap', value: _fullName),
                              const Divider(height: 16, color: kBorder),
                              _infoTile(icon: Icons.badge_outlined, label: 'NIP (Nomor Induk Pegawai)', value: _nip),
                              const Divider(height: 16, color: kBorder),
                              _infoTile(icon: Icons.alternate_email, label: 'Username Akun', value: '@$_username'),
                              const Divider(height: 16, color: kBorder),
                              _infoTile(icon: Icons.shield_outlined, label: 'Role', value: 'Admin'),
                            ] else ...[
                              // EDIT MODE
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Nama Lengkap *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: _inputDecoration('Contoh: Bambang Sudarmono, S.T., M.Kom.', Icons.person_outline),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
                                    ),
                                    const SizedBox(height: 12),

                                    const Text('NIP (Nomor Induk Pegawai)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _nipController,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: _inputDecoration('Contoh: 19850412 201012 1 002', Icons.badge_outlined),
                                    ),
                                    const SizedBox(height: 12),

                                    const Text('Username *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _usernameController,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: _inputDecoration('Contoh: admin', Icons.alternate_email),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
                                        if (v.trim().length < 3) return 'Minimal 3 karakter';
                                        if (v.trim().contains(' ')) return 'Tidak boleh ada spasi';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: _savingProfile
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _nameController.text = _fullName;
                                                    _usernameController.text = _username;
                                                    _nipController.text = _nip == '-' ? '' : _nip;
                                                    _isEditing = false;
                                                  });
                                                },
                                          child: const Text('Batal', style: TextStyle(color: kTextMuted, fontSize: 13)),
                                        ),
                                        const SizedBox(width: 8),
                                        AppButton(
                                          label: 'Simpan',
                                          icon: Icons.check,
                                          isLoading: _savingProfile,
                                          onPressed: _saveProfileChanges,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Kartu Keamanan Akun ──
                      CleanCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.key_outlined, size: 18, color: kBrandAccent),
                              ),
                              title: const Text('Ubah Kata Sandi', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: kTextMain)),
                              subtitle: const Text('Perbarui kata sandi akun', style: TextStyle(fontSize: 11.5, color: kTextMuted)),
                              trailing: const Icon(Icons.chevron_right, size: 18, color: kTextMuted),
                              onTap: _showChangePasswordDialog,
                            ),
                            const Divider(height: 1, color: kBorder),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.logout, size: 18, color: kColorDanger),
                              ),
                              title: const Text('Keluar dari Akun', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: kColorDanger)),
                              subtitle: const Text('Akhiri sesi aktif di sistem SIPELA', style: TextStyle(fontSize: 11.5, color: kTextMuted)),
                              trailing: const Icon(Icons.chevron_right, size: 18, color: kColorDanger),
                              onTap: _handleLogout,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 17, color: kTextMuted),
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: kTextSubtle),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
    );
  }

  Widget _infoTile({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: kBrandAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextMain),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
