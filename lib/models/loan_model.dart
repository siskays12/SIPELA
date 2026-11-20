// lib/models/loan_model.dart
import 'dart:convert';

int _safeInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
}

int? _safeNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString());
}

List<dynamic> _parseJsonList(dynamic val) {
  if (val == null) return [];
  if (val is List) return val;
  if (val is String) {
    var str = val.trim();
    if (str.isEmpty || str == '[]' || str == 'null') return [];

    // 1. Coba decode JSON standar (double quotes)
    try {
      var decoded = jsonDecode(str);
      while (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is List) return decoded;
    } catch (_) {}

    // 2. Coba sanitasi jika format Python repr (single quotes & None/True/False)
    try {
      var sanitized = str
          .replaceAll(RegExp(r'\bNone\b'), 'null')
          .replaceAll(RegExp(r'\bTrue\b'), 'true')
          .replaceAll(RegExp(r'\bFalse\b'), 'false')
          .replaceAll("'", '"');
      var decoded = jsonDecode(sanitized);
      while (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is List) return decoded;
    } catch (_) {}
  }
  return [];
}

class ItemPinjaman {
  final int? idTool;      // null jika input free-text
  final String? namaAlat; // diisi jika input free-text
  final int jumlah;

  ItemPinjaman({this.idTool, this.namaAlat, required this.jumlah});

  factory ItemPinjaman.fromJson(Map<String, dynamic> json) => ItemPinjaman(
        idTool: _safeNullableInt(json['id_tool']),
        namaAlat: json['nama_alat'] as String?,
        jumlah: _safeInt(json['jumlah'], 1),
      );

  Map<String, dynamic> toJson() => {
        if (idTool != null) 'id_tool': idTool,
        if (namaAlat != null) 'nama_alat': namaAlat,
        'jumlah': jumlah,
      };
}

class Loan {
  final int idLoan;
  final int idCustomer;
  final String namaMahasiswa;
  final String nimMahasiswa;
  final String prodiMahasiswa;
  final String tanggalPinjam;
  final String tanggalRencanaKembali;
  final String status; // 'dipinjam', 'selesai'
  final String? keperluan;
  final String? catatanAdmin;
  final List<ItemPinjaman> daftarAlat;

  Loan({
    required this.idLoan,
    required this.idCustomer,
    this.namaMahasiswa = '',
    this.nimMahasiswa = '',
    this.prodiMahasiswa = '',
    required this.tanggalPinjam,
    required this.tanggalRencanaKembali,
    required this.status,
    this.keperluan,
    this.catatanAdmin,
    required this.daftarAlat,
  });

  bool get isTerlambat {
    if (status != 'dipinjam') return false;
    try {
      final deadline = DateTime.parse(tanggalRencanaKembali);
      final today = DateTime.now();
      return today.isAfter(DateTime(deadline.year, deadline.month, deadline.day, 23, 59, 59));
    } catch (_) {
      return false;
    }
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    final list = _parseJsonList(json['daftar_alat']);

    return Loan(
      idLoan: _safeInt(json['id_loan'], 0),
      idCustomer: _safeInt(json['id_customer'], 0),
      namaMahasiswa: json['nama_mahasiswa']?.toString() ?? '',
      nimMahasiswa: json['nim_mahasiswa']?.toString() ?? '',
      prodiMahasiswa: json['prodi_mahasiswa']?.toString() ?? '',
      tanggalPinjam: json['tanggal_pinjam']?.toString() ??
          json['tanggal_pengajuan']?.toString() ??
          DateTime.now().toIso8601String(),
      tanggalRencanaKembali: json['tanggal_rencana_kembali']?.toString() ?? '',
      status: json['status']?.toString() ?? 'dipinjam',
      keperluan: json['keperluan']?.toString(),
      catatanAdmin: json['catatan_admin']?.toString(),
      daftarAlat: list
          .map((e) => ItemPinjaman.fromJson(
                e is Map<String, dynamic>
                    ? e
                    : Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id_loan': idLoan,
        'id_customer': idCustomer,
        'nama_mahasiswa': namaMahasiswa,
        'nim_mahasiswa': nimMahasiswa,
        'prodi_mahasiswa': prodiMahasiswa,
        'tanggal_pinjam': tanggalPinjam,
        'tanggal_rencana_kembali': tanggalRencanaKembali,
        'status': status,
        'keperluan': keperluan,
        'catatan_admin': catatanAdmin,
        'daftar_alat': daftarAlat.map((e) => e.toJson()).toList(),
      };
}
