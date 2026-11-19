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
      final me = await ApiService.get('/me');
      if (me is Map<String, dynamic>) {
        final nama = me['nama'] as String? ?? 'Administrator';
        final username = me['username'] as String? ?? 'admin';
        final nip = me['nip'] as String? ?? '-';
        if (mounted) {
          setState(() {
            _fullName = nama;
            _username = username;
            _nip = nip.isEmpty ? '-' : nip;
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
        showSuccess(context, 'Profil berhasil diperbarui!');
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
                            Text('Ubah Kata Sandi',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextMain)),
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
                    const Text('Kata Sandi Saat Ini *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
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
                          icon: Icon(
                              obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: kTextMuted),
                          onPressed: () => setS(() => obscureOld = !obscureOld),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Kata sandi saat ini wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Kata Sandi Baru *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
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
                          icon: Icon(
                              obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: kTextMuted),
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
                    const Text('Konfirmasi Kata Sandi Baru *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
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
                          icon: Icon(
                              obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: kTextMuted),
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
                              if (mounted) showSuccess(context, 'Kata sandi berhasil diperbarui!');
                            } catch (e) {
                              if (ctx.mounted) showError(ctx, e.toString());
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
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
        title: const Text('Profil',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextMain)),
        backgroundColor: kSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: kBrandAccent),
            tooltip: 'Segarkan',
            onPressed: _loadProfileData,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const LoadingWidget(message: 'Memuat profil...')
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── HERO SECTION: Avatar + Nama + Role ──────────────
                  Container(
                    width: double.infinity,
                    color: kSurface,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      children: [
                        // Avatar besar
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: kBrandPrimary,
                              child: Text(
                                getInitial(_fullName),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            // Tombol edit kecil di pojok avatar
                            if (!_isEditing)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _nameController.text = _fullName;
                                  _usernameController.text = _username;
                                  _nipController.text = _nip == '-' ? '' : _nip;
                                  _isEditing = true;
                                }),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: kBrandAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: kSurface, width: 2),
                                  ),
                                  child: const Icon(Icons.edit, size: 13, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Nama
                        Text(
                          _fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kTextMain,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: kBrandAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kBrandAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: kBorder),

                  // ── BODY SECTION ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: _isEditing ? _buildEditForm() : _buildViewMode(),
                  ),
                ],
              ),
            ),
    );
  }

  // ── VIEW MODE — field card bergaya gambar referensi ─────────────────────────
  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info fields
        _infoCard(label: 'Nama Lengkap', value: _fullName, icon: Icons.person_outline),
        const SizedBox(height: 10),
        _infoCard(label: 'Username', value: '@$_username', icon: Icons.alternate_email),
        const SizedBox(height: 10),
        _infoCard(label: 'NIP (Nomor Induk Pegawai)', value: _nip, icon: Icons.badge_outlined),
        const SizedBox(height: 10),
        _infoCard(label: 'Role', value: 'Admin', icon: Icons.shield_outlined),
        const SizedBox(height: 24),

        // Ubah Kata Sandi
        _actionCard(
          label: 'Ubah Kata Sandi',
          subtitle: 'Perbarui kata sandi akun Anda',
          icon: Icons.lock_outline,
          iconBg: const Color(0xFFEFF6FF),
          iconColor: kBrandAccent,
          onTap: _showChangePasswordDialog,
        ),
        const SizedBox(height: 10),

        // Keluar
        _actionCard(
          label: 'Keluar dari Akun',
          subtitle: 'Akhiri sesi aktif di sistem SIPELA',
          icon: Icons.logout,
          iconBg: const Color(0xFFFEF2F2),
          iconColor: kColorDanger,
          labelColor: kColorDanger,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  // ── EDIT MODE ───────────────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Nama Lengkap *'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration('Contoh: Bambang Sudarmono, S.T.', Icons.person_outline),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
          ),
          const SizedBox(height: 14),

          _fieldLabel('NIP (Nomor Induk Pegawai)'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _nipController,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration('Contoh: 19850412 201012 1 002', Icons.badge_outlined),
          ),
          const SizedBox(height: 14),

          _fieldLabel('Username *'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration('Contoh: admin', Icons.alternate_email),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
              if (v.trim().length < 3) return 'Minimal 3 karakter';
              if (v.trim().contains(' ')) return 'Tidak boleh ada spasi';
              return null;
            },
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _savingProfile
                    ? null
                    : () => setState(() {
                          _nameController.text = _fullName;
                          _usernameController.text = _username;
                          _nipController.text = _nip == '-' ? '' : _nip;
                          _isEditing = false;
                        }),
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
    );
  }

  // ── Widgets helper ──────────────────────────────────────────────────────────

  /// Card info bergaya referensi — label kecil di atas, value besar, ikon di kanan
  Widget _infoCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: kTextMuted),
          ),
        ],
      ),
    );
  }

  /// Action card — Ubah Kata Sandi & Keluar
  Widget _actionCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: labelColor ?? kTextMain)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11.5, color: kTextMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: labelColor ?? kTextMuted),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 17, color: kTextMuted),
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: kTextSubtle),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
    );
  }
}
