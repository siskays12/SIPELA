// lib/models/return_model.dart
import 'dart:convert';

int _safeInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
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

class ItemPengembalian {
  final int idTool;
  final String? namaAlat;
  final int jumlah;
  final String kondisi;

  ItemPengembalian({
    required this.idTool,
    this.namaAlat,
    required this.jumlah,
    required this.kondisi,
  });

  factory ItemPengembalian.fromJson(Map<String, dynamic> json) =>
      ItemPengembalian(
        idTool: _safeInt(json['id_tool'], 0),
        namaAlat: json['nama_alat'] as String?,
        jumlah: _safeInt(json['jumlah'], 1),
        kondisi: json['kondisi'] as String? ?? 'baik',
      );

  Map<String, dynamic> toJson() => {
        'id_tool': idTool,
        if (namaAlat != null) 'nama_alat': namaAlat,
        'jumlah': jumlah,
        'kondisi': kondisi,
      };
}

List<ItemPengembalian> _parsePengembalianItems(dynamic raw) {
  if (raw == null) return [];

  // 1. Jika raw adalah list of maps (JSON)
  final listJson = _parseJsonList(raw);
  if (listJson.isNotEmpty) {
    return listJson
        .map((e) => ItemPengembalian.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  // 2. Jika raw adalah String format teks deskriptif dari backend GitHub:
  // Contoh: "Jangka Sorong (1 unit) - Kondisi: Baik, Multimeter (1 unit) - Kondisi: Rusak"
  if (raw is String && raw.trim().isNotEmpty) {
    final str = raw.trim();
    if (str == '[]' || str == 'null') return [];

    final parts = str.split(', ');
    final result = <ItemPengembalian>[];
    final regex = RegExp(r'^(.*?)\s*\((\d+)\s*unit\)\s*-\s*Kondisi:\s*(.*)$', caseSensitive: false);

    for (final part in parts) {
      final p = part.trim();
      if (p.isEmpty) continue;
      final match = regex.firstMatch(p);
      if (match != null) {
        final nama = match.group(1)?.trim();
        final jml = int.tryParse(match.group(2) ?? '1') ?? 1;
        final kondisi = (match.group(3)?.trim() ?? 'baik').toLowerCase();
        result.add(ItemPengembalian(
          idTool: 0,
          namaAlat: nama,
          jumlah: jml,
          kondisi: kondisi,
        ));
      } else {
        result.add(ItemPengembalian(
          idTool: 0,
          namaAlat: p,
          jumlah: 1,
          kondisi: 'baik',
        ));
      }
    }

    if (result.isNotEmpty) return result;
  }

  return [];
}

class Pengembalian {
  final int idReturn;
  final int idLoan;
  final int idAdmin;
  final String? tanggalPengembalian;
  final String? catatan;
  final List<ItemPengembalian> detailPengembalian;

  Pengembalian({
    required this.idReturn,
    required this.idLoan,
    required this.idAdmin,
    this.tanggalPengembalian,
    this.catatan,
    required this.detailPengembalian,
  });

  factory Pengembalian.fromJson(Map<String, dynamic> json) => Pengembalian(
        idReturn: _safeInt(json['id_return'], 0),
        idLoan: _safeInt(json['id_loan'], 0),
        idAdmin: _safeInt(json['id_admin'], 1),
        tanggalPengembalian: json['tanggal_pengembalian']?.toString(),
        catatan: json['catatan']?.toString(),
        detailPengembalian: _parsePengembalianItems(json['detail_pengembalian']),
      );
}
