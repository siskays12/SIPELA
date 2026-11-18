// lib/models/return_model.dart

int _safeInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
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
        tanggalPengembalian: json['tanggal_pengembalian'],
        catatan: json['catatan'],
        detailPengembalian: (json['detail_pengembalian'] as List? ?? [])
            .map((e) => ItemPengembalian.fromJson(e))
            .toList(),
      );
}
