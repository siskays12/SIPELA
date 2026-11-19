// lib/screens/shared/login_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../shared/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController(text: 'admin123');
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );
      await ApiService.saveAuth(
        data['access_token'] ?? 'token',
        'admin',
        _usernameCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F265C), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x331E3A8A),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.science_outlined, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Text(
                      'POLITEKNIK NEGERI',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: kBrandAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'SIPELA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: kTextMain,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sistem Peminjaman Alat Laboratorium',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: kTextMuted),
                  ),
                  const SizedBox(height: 20),

                  CleanCard(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _loginFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Masuk Petugas Laboratorium',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kTextMain),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Username Petugas',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: _inputDec('Masukkan username petugas'),
                            validator: (v) => v!.trim().isEmpty ? 'Username wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Password',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: _inputDec('Masukkan password').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                  color: kTextMuted,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Password wajib diisi' : null,
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            label: 'Masuk ke Sistem',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            fullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Portal Khusus Petugas / Admin Laboratorium',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: kTextSubtle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: kTextSubtle),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBrandAccent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      isDense: true,
    );
  }
}
