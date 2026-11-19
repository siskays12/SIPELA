// lib/core/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const bool useMockData = false;
const String baseUrl = 'http://127.0.0.1:8000';

class ApiService {
  // ─── Auth Storage ─────────────────────────────
  static Future<void> saveAuth(String token, String role, String username, [String? fullName]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setString('username', username);
    if (fullName != null && fullName.isNotEmpty) {
      await prefs.setString('full_name', fullName);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('full_name');
  }

  static Future<dynamic> updateProfile({required String fullName, required String username}) async {
    // 1. Simpan ke database melalui endpoint PUT /me
    final res = await put('/me', {
      'nama': fullName,
      'username': username,
    });

    // 2. Perbarui local preferences & token baru jika username berubah
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('full_name', fullName);
    await prefs.setString('username', username);
    if (res is Map && res['access_token'] != null) {
      await prefs.setString('token', res['access_token'].toString());
    }
    return res;
  }

  static Future<dynamic> changePassword({required String oldPassword, required String newPassword}) async {
    return await put('/change-password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ─── In-Memory Mock Data (Dikosongkan) ──
  static final List<Map<String, dynamic>> _mockTools = [];
  static final List<Map<String, dynamic>> _mockCustomers = [];
  static final List<Map<String, dynamic>> _mockLoans = [];
  static final List<Map<String, dynamic>> _mockReturns = [];

  // ─── Login Method ─────────────────────────────
  static Future<dynamic> login(String username, String password) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        'success': true,
        'message': 'Login berhasil',
        'access_token': 'mock-access-token-petugas',
        'token_type': 'bearer',
        'role': 'admin',
      };
    }

    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: {'username': username, 'password': password},
    );
    return _handleResponse(res);
  }

  // ─── Generic Requests ─────────────────────────
  static Future<dynamic> get(String path) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (path == '/tools') return _mockTools;
      if (path == '/customer') return _mockCustomers;
      if (path == '/loans') return _mockLoans;
      if (path == '/returns') return _mockReturns;
      return [];
    }

    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));

      // 1. Tambah Alat
      if (path == '/tools') {
        final newTool = Map<String, dynamic>.from(body);
        final maxId = _mockTools.isEmpty ? 0 : _mockTools.map((e) => (e['id_tool'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b);
        newTool['id_tool'] = maxId + 1;
        _mockTools.add(newTool);
        return {'success': true, 'message': 'Alat berhasil ditambahkan'};
      }

      // 2. Tambah Mahasiswa
      if (path == '/customer') {
        final newMhs = Map<String, dynamic>.from(body);
        final existingIdx = _mockCustomers.indexWhere((c) => c['nim'] == newMhs['nim']);
        if (existingIdx != -1) {
          _mockCustomers[existingIdx]['nama'] = newMhs['nama'];
          _mockCustomers[existingIdx]['prodi'] = newMhs['prodi'];
          if (newMhs['no_hp'] != null && newMhs['no_hp'] != '-') {
            _mockCustomers[existingIdx]['no_hp'] = newMhs['no_hp'];
          }
          return {
            'success': true,
            'message': 'Data mahasiswa diperbarui',
            'id_customer': _mockCustomers[existingIdx]['id_customer'],
          };
        }
        final maxId = _mockCustomers.isEmpty ? 0 : _mockCustomers.map((e) => (e['id_customer'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b);
        newMhs['id_customer'] = maxId + 1;
        _mockCustomers.add(newMhs);
        return {'success': true, 'message': 'Data mahasiswa berhasil disimpan', 'id_customer': newMhs['id_customer']};
      }

      // 3. Catat Peminjaman (Langsung Kurangi Stok & Status 'dipinjam')
      if (path == '/loans') {
        final maxId = _mockLoans.isEmpty ? 0 : _mockLoans.map((e) => (e['id_loan'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b);
        final idCustomer = body['id_customer'] as int? ?? 0;

        // Ambil data mahasiswa: bisa dari mock customers atau langsung dari payload
        final mhs = _mockCustomers.firstWhere(
          (c) => c['id_customer'] == idCustomer,
          orElse: () => {},
        );

        final newLoan = {
          'id_loan': maxId + 1,
          'id_customer': idCustomer,
          'nama_mahasiswa': mhs['nama'] ?? body['nama_mahasiswa'] ?? 'Mahasiswa #$idCustomer',
          'nim_mahasiswa': mhs['nim'] ?? body['nim_mahasiswa'] ?? '-',
          'prodi_mahasiswa': mhs['prodi'] ?? body['prodi_mahasiswa'] ?? '-',
          'tanggal_pinjam': DateTime.now().toIso8601String(),
          'tanggal_rencana_kembali': body['tanggal_rencana_kembali'],
          'status': 'dipinjam',
          'keperluan': body['keperluan'],
          'daftar_alat': body['daftar_alat'],
        };

        // Jika daftar_alat menggunakan id_tool, kurangi stok
        for (var item in (body['daftar_alat'] as List)) {
          if (item['id_tool'] != null) {
            try {
              final tool = _mockTools.firstWhere((t) => t['id_tool'] == item['id_tool']);
              final jml = (item['jumlah'] as num?)?.toInt() ?? 1;
              tool['stok_tersedia'] = (((tool['stok_tersedia'] as num?)?.toInt() ?? 0) - jml).clamp(0, 9999);
            } catch (_) {
              // id_tool tidak ditemukan, abaikan
            }
          }
          // Jika menggunakan nama_alat (free-text), tidak ada stok yang dikurangi
        }

        _mockLoans.insert(0, newLoan);
        return {'success': true, 'message': 'Peminjaman berhasil dicatat & alat diserahkan'};
      }

      // 4. Catat Pengembalian (Pulihkan Stok & Ubah Status 'selesai')
      if (path.startsWith('/returns/')) {
        final idLoan = int.tryParse(path.split('/').last) ?? 0;
        final loanIdx = _mockLoans.indexWhere((l) => l['id_loan'] == idLoan);
        if (loanIdx != -1) {
          _mockLoans[loanIdx]['status'] = 'selesai';
        }

        final newReturn = {
          'id_return': _mockReturns.length + 1,
          'id_loan': idLoan,
          'id_admin': 1,
          'tanggal_pengembalian': DateTime.now().toIso8601String(),
          'catatan': body['catatan'],
          'detail_pengembalian': body['detail_pengembalian'],
        };
        _mockReturns.insert(0, newReturn);

        // Update stok alat berdasarkan kondisi yang dikembalikan
        for (var d in (body['detail_pengembalian'] as List)) {
          final idTool = d['id_tool'];
          if (idTool == null || idTool == 0) continue;
          final toolIdx = _mockTools.indexWhere((t) => t['id_tool'] == idTool);
          if (toolIdx == -1) continue;
          final tool = _mockTools[toolIdx];
          final jml = (d['jumlah'] as num?)?.toInt() ?? 1;
          final kondisi = d['kondisi']?.toString() ?? 'baik';

          if (kondisi == 'baik') {
            tool['stok_tersedia'] = ((tool['stok_tersedia'] as num?)?.toInt() ?? 0) + jml;
          } else if (kondisi == 'rusak') {
            tool['kondisi'] = 'rusak';
            // stok tidak dikembalikan ke stok tersedia
          } else if (kondisi == 'hilang') {
            tool['stok_total'] = (((tool['stok_total'] as num?)?.toInt() ?? 0) - jml).clamp(0, 9999);
          }
        }
        return {'success': true, 'message': 'Pengembalian alat berhasil dicatat & stok diperbarui'};
      }

      return {'success': true};
    }

    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (path.startsWith('/tools/')) {
        final id = int.tryParse(path.split('/').last) ?? 0;
        final idx = _mockTools.indexWhere((t) => t['id_tool'] == id);
        if (idx != -1) _mockTools[idx] = {'id_tool': id, ...body};
      }
      if (path.startsWith('/customer/')) {
        final id = int.tryParse(path.split('/').last) ?? 0;
        final idx = _mockCustomers.indexWhere((c) => c['id_customer'] == id);
        if (idx != -1) _mockCustomers[idx] = {'id_customer': id, ...body};
      }
      return {'success': true, 'message': 'Data berhasil diperbarui'};
    }

    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      return {'success': true, 'message': 'Data berhasil diperbarui'};
    }

    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<dynamic> delete(String path) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (path.startsWith('/tools/')) {
        final id = int.tryParse(path.split('/').last) ?? 0;
        _mockTools.removeWhere((t) => t['id_tool'] == id);
      }
      if (path.startsWith('/customer/')) {
        final id = int.tryParse(path.split('/').last) ?? 0;
        _mockCustomers.removeWhere((c) => c['id_customer'] == id);
      }
      return {'success': true, 'message': 'Data berhasil dihapus'};
    }

    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
    );
    return _handleResponse(res);
  }

  // ─── Headers & Error Handler ──────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> _handleResponse(http.Response res) async {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiException(
        'Server mengembalikan HTML/Error (Status ${res.statusCode}). Pastikan port :8000 dan URL benar.',
        res.statusCode,
      );
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body is Map ? (body['detail'] ?? 'Terjadi kesalahan') : 'Terjadi kesalahan';
    throw ApiException(msg.toString(), res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
