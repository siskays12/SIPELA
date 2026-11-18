// lib/core/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const bool useMockData = true;
const String baseUrl = 'http://127.0.0.1:8000';

class ApiService {
  // ─── Auth Storage ─────────────────────────────
  static Future<void> saveAuth(String token, String role, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setString('username', username);
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

  static Future<void> updateProfile({required String fullName, required String username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('full_name', fullName);
    await prefs.setString('username', username);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ─── In-Memory Mock Data (Tema Kampus Vokasi & Sarpras) ──
  static final List<Map<String, dynamic>> _mockTools = [
    // 1. Teknologi Rekayasa Perangkat Lunak (D4)
    {
      'id_tool': 1,
      'kode_alat': 'TRPL-DEV-01',
      'nama_alat': 'Laptop Developer Asus ROG i7 (32GB)',
      'kategori': 'Teknologi Rekayasa Perangkat Lunak',
      'deskripsi': 'Laptop spek tinggi untuk kompilasi mobile app, web backend, & container docker',
      'stok_total': 6,
      'stok_tersedia': 5,
      'kondisi': 'baik',
    },
    {
      'id_tool': 2,
      'kode_alat': 'TRPL-IOT-02',
      'nama_alat': 'Raspberry Pi 4 Cloud Server Kit',
      'kategori': 'Teknologi Rekayasa Perangkat Lunak',
      'deskripsi': 'Modul mini-server & sensor IoT untuk praktikum arsitektur sistem terdistribusi',
      'stok_total': 8,
      'stok_tersedia': 8,
      'kondisi': 'baik',
    },

    // 2. Teknologi Rekayasa Pemeliharaan Alat Berat (D4)
    {
      'id_tool': 3,
      'kode_alat': 'PAB-CAT-01',
      'nama_alat': 'Diagnostic Scanner CAT Comm Adapter III',
      'kategori': 'Teknologi Rekayasa Pemeliharaan Alat Berat',
      'deskripsi': 'Scanner diagnostik ECM engine & transmisi unit excavator Caterpillar/Komatsu',
      'stok_total': 3,
      'stok_tersedia': 2,
      'kondisi': 'baik',
    },
    {
      'id_tool': 4,
      'kode_alat': 'PAB-HYD-02',
      'nama_alat': 'Hydraulic Pressure Test Kit 600 Bar',
      'kategori': 'Teknologi Rekayasa Pemeliharaan Alat Berat',
      'deskripsi': 'Set pressure gauge & hose coupler untuk uji tekanan pompa hidrolik alat berat',
      'stok_total': 4,
      'stok_tersedia': 3,
      'kondisi': 'baik',
    },
    {
      'id_tool': 5,
      'kode_alat': 'PAB-TRQ-03',
      'nama_alat': 'Torque Wrench Digital 100-1000 Nm',
      'kategori': 'Teknologi Rekayasa Pemeliharaan Alat Berat',
      'deskripsi': 'Kunci momen torsi digital presisi untuk pengencangan baut final drive & track shoe',
      'stok_total': 5,
      'stok_tersedia': 5,
      'kondisi': 'baik',
    },

    // 3. Teknologi Rekayasa Logistik (D4)
    {
      'id_tool': 6,
      'kode_alat': 'LOG-ZBR-01',
      'nama_alat': 'Handheld Barcode & RFID Scanner Zebra TC21',
      'kategori': 'Teknologi Rekayasa Logistik',
      'deskripsi': 'Mobile computer scanner untuk simulasi WMS (Warehouse Management System) & inventory',
      'stok_total': 6,
      'stok_tersedia': 5,
      'kondisi': 'baik',
    },
    {
      'id_tool': 7,
      'kode_alat': 'LOG-PRT-02',
      'nama_alat': 'Thermal Barcode Label Printer Honeywell',
      'kategori': 'Teknologi Rekayasa Logistik',
      'deskripsi': 'Printer label resi shipping & barcode pallet untuk penataan gudang logistik',
      'stok_total': 4,
      'stok_tersedia': 3,
      'kondisi': 'baik',
    },

    // 4. Akuntansi Perpajakan (D4)
    {
      'id_tool': 8,
      'kode_alat': 'AKP-GLR-01',
      'nama_alat': 'Mesin Hitung Uang & Detektor UV Glory',
      'kategori': 'Akuntansi Perpajakan',
      'deskripsi': 'Mesin hitung lembar uang kecepatan tinggi & sensor deteksi keaslian uang kertas',
      'stok_total': 4,
      'stok_tersedia': 4,
      'kondisi': 'baik',
    },
    {
      'id_tool': 9,
      'kode_alat': 'AKP-CAL-02',
      'nama_alat': 'Kalkulator Finansial Texas Instruments BA II',
      'kategori': 'Akuntansi Perpajakan',
      'deskripsi': 'Kalkulator audit finansial untuk analisis kelayakan investasi, amortisasi, & pajak',
      'stok_total': 10,
      'stok_tersedia': 10,
      'kondisi': 'baik',
    },

    // 5. Teknik Listrik (D3)
    {
      'id_tool': 10,
      'kode_alat': 'LIS-MEG-01',
      'nama_alat': 'Insulation Tester Megger 1000V Fluke 1507',
      'kategori': 'Teknik Listrik',
      'deskripsi': 'Alat ukur tahanan isolasi kabel instalasi daya & gulungan motor listrik 3 fasa',
      'stok_total': 4,
      'stok_tersedia': 4,
      'kondisi': 'baik',
    },
    {
      'id_tool': 11,
      'kode_alat': 'LIS-CLM-02',
      'nama_alat': 'Clamp Meter Digital Tang Ampere Sanwa DCM600',
      'kategori': 'Teknik Listrik',
      'deskripsi': 'Pengukur arus bolak-balik (AC/DC) non-kontak untuk panel distribusi listrik gedung',
      'stok_total': 6,
      'stok_tersedia': 6,
      'kondisi': 'baik',
    },
    {
      'id_tool': 12,
      'kode_alat': 'LIS-PLC-03',
      'nama_alat': 'Trainer PLC Omron CP1E Modul Otomasi',
      'kategori': 'Teknik Listrik',
      'deskripsi': 'Trainer instalasi motor starter forward-reverse & kendali logika otomasi industri',
      'stok_total': 3,
      'stok_tersedia': 3,
      'kondisi': 'baik',
    },

    // 6. Bisnis Digital (D4)
    {
      'id_tool': 13,
      'kode_alat': 'BDG-CAM-01',
      'nama_alat': 'Kamera Mirrorless Sony Alpha A6700 4K',
      'kategori': 'Bisnis Digital',
      'deskripsi': 'Kamera video produksi konten live commerce, podcast bisnis, & branding digital',
      'stok_total': 4,
      'stok_tersedia': 3,
      'kondisi': 'baik',
    },
    {
      'id_tool': 14,
      'kode_alat': 'BDG-LGT-02',
      'nama_alat': 'Studio Lighting Softbox & Ring Light Godox',
      'kategori': 'Bisnis Digital',
      'deskripsi': 'Set pencahayaan studio profesional untuk fotografi katalog produk & livestreaming',
      'stok_total': 5,
      'stok_tersedia': 4,
      'kondisi': 'baik',
    },
    {
      'id_tool': 15,
      'kode_alat': 'BDG-MIC-03',
      'nama_alat': 'Wireless Microphone DJI Mic 2 (Dual TX)',
      'kategori': 'Bisnis Digital',
      'deskripsi': 'Mic nirkabel noise-cancelling untuk presentasi bisnis & liputan produk lapangan',
      'stok_total': 5,
      'stok_tersedia': 4,
      'kondisi': 'baik',
    },

    // 7. Teknik Elektronika (D3)
    {
      'id_tool': 16,
      'kode_alat': 'ELK-OSC-01',
      'nama_alat': 'Digital Storage Oscilloscope Rigol 100MHz',
      'kategori': 'Teknik Elektronika',
      'deskripsi': 'Alat uji bentuk gelombang, frekuensi, & sinyal mikroprosesor/mikrokontroler',
      'stok_total': 5,
      'stok_tersedia': 5,
      'kondisi': 'baik',
    },
    {
      'id_tool': 17,
      'kode_alat': 'ELK-SLD-02',
      'nama_alat': 'Solder Station & Hot Air Rework Quick 706W',
      'kategori': 'Teknik Elektronika',
      'deskripsi': 'Solder temperatur terkontrol & blower uap panas untuk komponen SMD mikrokontroler',
      'stok_total': 7,
      'stok_tersedia': 7,
      'kondisi': 'baik',
    },

    // 8. Teknik Mesin (D3)
    {
      'id_tool': 18,
      'kode_alat': 'MSN-CAL-01',
      'nama_alat': 'Jangka Sorong Digital Mitutoyo (Vernier Caliper)',
      'kategori': 'Teknik Mesin',
      'deskripsi': 'Alat ukur diameter dalam/luar presisi 0.01 mm untuk benda kerja bubut & milling',
      'stok_total': 12,
      'stok_tersedia': 12,
      'kondisi': 'baik',
    },
    {
      'id_tool': 19,
      'kode_alat': 'MSN-MIC-02',
      'nama_alat': 'Mikrometer Sekrup Luar Mitutoyo 0-25mm',
      'kategori': 'Teknik Mesin',
      'deskripsi': 'Pengukur ketebalan presisi 0.001 mm untuk inspeksi toleransi poros mesin',
      'stok_total': 8,
      'stok_tersedia': 8,
      'kondisi': 'baik',
    },

    // 9. Sarana Prasarana (Sarpras Kampus)
    {
      'id_tool': 20,
      'kode_alat': 'SPR-PRJ-01',
      'nama_alat': 'Proyektor Epson EB-2250U Laser 5000 Lumens',
      'kategori': 'Sarana Prasarana',
      'deskripsi': 'Proyektor HDMI resolusi tinggi untuk seminar, sidang tugas akhir, & kuliah umum',
      'stok_total': 4,
      'stok_tersedia': 3,
      'kondisi': 'baik',
    },
    {
      'id_tool': 21,
      'kode_alat': 'SPR-SPK-02',
      'nama_alat': 'Portable Wireless Sound System & Dual Mic Shure',
      'kategori': 'Sarana Prasarana',
      'deskripsi': 'Speaker portabel bluetooth & mikrofon wireless untuk kegiatan ormawa & acara kampus',
      'stok_total': 3,
      'stok_tersedia': 3,
      'kondisi': 'baik',
    },
  ];

  static final List<Map<String, dynamic>> _mockCustomers = [
    {
      'id_customer': 1,
      'nama': 'Ahmad Pratama',
      'nim': '2202001',
      'prodi': 'Teknologi Rekayasa Pemeliharaan Alat Berat (D4)',
      'no_hp': '081234567891',
    },
    {
      'id_customer': 2,
      'nama': 'Budi Santoso',
      'nim': '2201002',
      'prodi': 'Teknologi Rekayasa Perangkat Lunak (D4)',
      'no_hp': '081234567892',
    },
    {
      'id_customer': 3,
      'nama': 'Dewi Sartika',
      'nim': '2206003',
      'prodi': 'Bisnis Digital (D4)',
      'no_hp': '081234567893',
    },
    {
      'id_customer': 4,
      'nama': 'Rina Anggraini',
      'nim': '2203004',
      'prodi': 'Teknologi Rekayasa Logistik (D4)',
      'no_hp': '081234567894',
    },
    {
      'id_customer': 5,
      'nama': 'Fajar Hidayat',
      'nim': '2205005',
      'prodi': 'Teknik Listrik (D3)',
      'no_hp': '081234567895',
    },
    {
      'id_customer': 6,
      'nama': 'Siti Nurhaliza',
      'nim': '2204006',
      'prodi': 'Akuntansi Perpajakan (D4)',
      'no_hp': '081234567896',
    },
    {
      'id_customer': 7,
      'nama': 'Eko Wahyudi',
      'nim': '2207007',
      'prodi': 'Teknik Elektronika (D3)',
      'no_hp': '081234567897',
    },
    {
      'id_customer': 8,
      'nama': 'Bayu Saputra',
      'nim': '2208008',
      'prodi': 'Teknik Mesin (D3)',
      'no_hp': '081234567898',
    },
  ];

  static final List<Map<String, dynamic>> _mockLoans = [
    {
      'id_loan': 101,
      'id_customer': 1,
      'nama_mahasiswa': 'Ahmad Pratama',
      'nim_mahasiswa': '2202001',
      'prodi_mahasiswa': 'Teknologi Rekayasa Pemeliharaan Alat Berat (D4)',
      'tanggal_pinjam': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'tanggal_rencana_kembali': DateTime.now().add(const Duration(days: 3)).toIso8601String().substring(0, 10),
      'status': 'dipinjam',
      'keperluan': 'Overhaul Pompa Hidrolik Excavator Komatsu PC200 di Bengkel Alat Berat',
      'daftar_alat': [
        {'id_tool': 3, 'jumlah': 1},
        {'id_tool': 4, 'jumlah': 1},
      ],
    },
    {
      'id_loan': 102,
      'id_customer': 2,
      'nama_mahasiswa': 'Budi Santoso',
      'nim_mahasiswa': '2201002',
      'prodi_mahasiswa': 'Teknologi Rekayasa Perangkat Lunak (D4)',
      'tanggal_pinjam': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'tanggal_rencana_kembali': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10), // Terlambat
      'status': 'dipinjam',
      'keperluan': 'Hackathon Kampus & Presentasi Proyek Akhir Web',
      'daftar_alat': [
        {'id_tool': 1, 'jumlah': 1},
        {'id_tool': 20, 'jumlah': 1},
      ],
    },
    {
      'id_loan': 103,
      'id_customer': 3,
      'nama_mahasiswa': 'Dewi Sartika',
      'nim_mahasiswa': '2206003',
      'prodi_mahasiswa': 'Bisnis Digital (D4)',
      'tanggal_pinjam': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'tanggal_rencana_kembali': DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10),
      'status': 'dipinjam',
      'keperluan': 'Praktikum Live Streaming E-Commerce & Pembuatan Video Iklan UMKM',
      'daftar_alat': [
        {'id_tool': 13, 'jumlah': 1},
        {'id_tool': 14, 'jumlah': 1},
        {'id_tool': 15, 'jumlah': 1},
      ],
    },
    {
      'id_loan': 104,
      'id_customer': 4,
      'nama_mahasiswa': 'Rina Anggraini',
      'nim_mahasiswa': '2203004',
      'prodi_mahasiswa': 'Teknologi Rekayasa Logistik (D4)',
      'tanggal_pinjam': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'tanggal_rencana_kembali': DateTime.now().add(const Duration(days: 4)).toIso8601String().substring(0, 10),
      'status': 'dipinjam',
      'keperluan': 'Simulasi Stock Opname & Penataan Barcode Pallet di Lab Pergudangan',
      'daftar_alat': [
        {'id_tool': 6, 'jumlah': 1},
        {'id_tool': 7, 'jumlah': 1},
      ],
    },
    {
      'id_loan': 105,
      'id_customer': 8,
      'nama_mahasiswa': 'Bayu Saputra',
      'nim_mahasiswa': '2208008',
      'prodi_mahasiswa': 'Teknik Mesin (D3)',
      'tanggal_pinjam': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
      'tanggal_rencana_kembali': DateTime.now().subtract(const Duration(days: 3)).toIso8601String().substring(0, 10),
      'status': 'selesai',
      'keperluan': 'Pemesinan Bubut CNC & Kalibrasi Benda Kerja Poros Bertingkat',
      'daftar_alat': [
        {'id_tool': 18, 'jumlah': 1},
        {'id_tool': 19, 'jumlah': 1},
      ],
    },
  ];

  static final List<Map<String, dynamic>> _mockReturns = [
    {
      'id_return': 201,
      'id_loan': 105,
      'id_admin': 1,
      'tanggal_pengembalian': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'catatan': 'Jangka sorong dan micrometer dikembalikan dalam kondisi bersih dan terkalibrasi',
      'detail_pengembalian': [
        {'id_tool': 18, 'jumlah': 1, 'kondisi': 'baik'},
        {'id_tool': 19, 'jumlah': 1, 'kondisi': 'baik'},
      ],
    }
  ];

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
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> _handleResponse(http.Response res) async {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body['detail'] ?? 'Terjadi kesalahan';
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
