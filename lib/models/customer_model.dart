// lib/models/customer_model.dart

class Customer {
  final int idCustomer;
  final String nama;
  final String nim;
  final String prodi;
  final String noHp;

  Customer({
    required this.idCustomer,
    required this.nama,
    required this.nim,
    this.prodi = 'Teknik Informatika',
    this.noHp = '-',
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        idCustomer: json['id_customer'] ?? 0,
        nama: json['nama'] ?? '',
        nim: json['nim'] ?? '',
        prodi: json['prodi'] ?? 'Teknik Informatika',
        noHp: json['no_hp'] ?? '-',
      );

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'nim': nim,
        'prodi': prodi,
        'no_hp': noHp,
      };
}
