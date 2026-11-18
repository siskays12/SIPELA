// lib/models/tool_model.dart

int _safeInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
}

class Tool {
  final int idTool;
  final String kodeAlat;
  final String namaAlat;
  final String kategori;
  final String? deskripsi;
  final int stokTotal;
  final int stokTersedia;
  final String kondisi;

  Tool({
    required this.idTool,
    required this.kodeAlat,
    required this.namaAlat,
    this.kategori = 'Umum',
    this.deskripsi,
    required this.stokTotal,
    required this.stokTersedia,
    required this.kondisi,
  });

  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
        idTool: _safeInt(json['id_tool'], 0),
        kodeAlat: json['kode_alat']?.toString() ?? '',
        namaAlat: json['nama_alat']?.toString() ?? '',
        kategori: json['kategori']?.toString() ?? 'Umum',
        deskripsi: json['deskripsi']?.toString(),
        stokTotal: _safeInt(json['stok_total'], 0),
        stokTersedia: _safeInt(json['stok_tersedia'], 0),
        kondisi: json['kondisi']?.toString() ?? 'baik',
      );

  Map<String, dynamic> toJson() => {
        'kode_alat': kodeAlat,
        'nama_alat': namaAlat,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'stok_total': stokTotal,
        'stok_tersedia': stokTersedia,
        'kondisi': kondisi,
      };
}
