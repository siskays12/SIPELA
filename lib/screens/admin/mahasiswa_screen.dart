// lib/screens/admin/mahasiswa_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/customer_model.dart';
import '../../widgets/app_widgets.dart';

class MahasiswaScreen extends StatefulWidget {
  const MahasiswaScreen({super.key});

  @override
  State<MahasiswaScreen> createState() => _MahasiswaScreenState();
}

class _MahasiswaScreenState extends State<MahasiswaScreen> {
  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/customer');
      setState(() {
        _customers = (data as List).map((e) => Customer.fromJson(e)).toList();
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, e.toString());
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    setState(() {
      _filtered = _customers
          .where((c) =>
              c.nama.toLowerCase().contains(q) ||
              c.nim.toLowerCase().contains(q) ||
              c.prodi.toLowerCase().contains(q))
          .toList();
    });
  }

  final List<String> _prodiList = const [
    'Teknologi Rekayasa Perangkat Lunak (D4)',
    'Teknologi Rekayasa Pemeliharaan Alat Berat (D4)',
    'Teknologi Rekayasa Logistik (D4)',
    'Akuntansi Perpajakan (D4)',
    'Bisnis Digital (D4)',
    'Teknik Listrik (D3)',
    'Teknik Elektronika (D3)',
    'Teknik Mesin (D3)',
  ];

  Future<void> _showMahasiswaDialog([Customer? existing]) async {
    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final nimCtrl = TextEditingController(text: existing?.nim ?? '');
    String selectedProdi = _prodiList.contains(existing?.prodi) ? existing!.prodi : _prodiList.first;
    final noHpCtrl = TextEditingController(text: existing?.noHp ?? '');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: kSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null ? 'Data Mahasiswa Peminjam' : 'Edit Data Mahasiswa',
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: kTextMain),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: kTextMuted),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: kBorder),
                    const SizedBox(height: 14),

                    const Text('Nama Lengkap Mahasiswa *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: namaCtrl,
                      decoration: _dialogInput('Contoh: Budi Santoso'),
                      validator: (v) => v!.trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    const Text('NIM (Nomor Induk Mahasiswa) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: nimCtrl,
                      decoration: _dialogInput('Contoh: 2200101'),
                      validator: (v) => v!.trim().isEmpty ? 'NIM wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    const Text('Program Studi (Prodi) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProdi,
                      isExpanded: true,
                      decoration: _dialogInput('Pilih Program Studi'),
                      items: _prodiList.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setS(() => selectedProdi = v ?? _prodiList.first),
                    ),
                    const SizedBox(height: 12),

                    const Text('Nomor HP / WhatsApp (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: noHpCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _dialogInput('Contoh: 081234567890'),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: kBorder),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: kTextMuted, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: existing == null ? 'Simpan Mahasiswa' : 'Perbarui Data',
                          isLoading: saving,
                          icon: existing == null ? Icons.person_add : Icons.check,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setS(() => saving = true);
                            try {
                              final payload = {
                                'nim': nimCtrl.text.trim(),
                                'nama': namaCtrl.text.trim(),
                                'prodi': selectedProdi,
                                'no_hp': noHpCtrl.text.trim().isEmpty ? '-' : noHpCtrl.text.trim(),
                              };
                              if (existing == null) {
                                await ApiService.post('/customer', payload);
                              } else {
                                await ApiService.put('/customer/${existing.idCustomer}', payload);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                showSuccess(context, existing == null ? 'Data mahasiswa berhasil disimpan' : 'Data mahasiswa diperbarui');
                                _fetchData();
                              }
                            } catch (e) {
                              if (mounted) showError(context, e.toString());
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

  Future<void> _hapusMahasiswa(Customer c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Data Mahasiswa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Hapus "${c.nama}" (${c.nim}) dari basis data peminjam?', style: const TextStyle(fontSize: 13, color: kTextMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: kTextMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kColorDanger, elevation: 0),
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.delete('/customer/${c.idCustomer}');
      if (mounted) {
        showSuccess(context, 'Data mahasiswa berhasil dihapus');
        _fetchData();
      }
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  InputDecoration _dialogInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: kTextSubtle),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Container(
            color: kSurface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (v) {
                _search = v;
                _applyFilter();
              },
              decoration: InputDecoration(
                hintText: 'Cari mahasiswa berdasarkan nama, NIM, atau Prodi...',
                hintStyle: const TextStyle(fontSize: 13, color: kTextSubtle),
                prefixIcon: const Icon(Icons.search, size: 18, color: kTextMuted),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1, color: kBorder),

          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Memuat data mahasiswa...')
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: 'Tidak ada mahasiswa ditemukan',
                        subtitle: 'Daftarkan mahasiswa peminjam baru dengan tombol di bawah',
                        action: AppButton(
                          label: 'Tambah Mahasiswa',
                          icon: Icons.person_add,
                          onPressed: () => _showMahasiswaDialog(),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: kBrandAccent,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final c = _filtered[i];
                            return CleanCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    radius: 20,
                                    child: Text(
                                      getInitial(c.nama),
                                      style: const TextStyle(color: kBrandAccent, fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.nama,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'NIM: ${c.nim} • ${c.prodi}',
                                          style: const TextStyle(fontSize: 12, color: kTextMuted),
                                        ),
                                        if (c.noHp != '-' && c.noHp.isNotEmpty)
                                          Text(
                                            'No. HP: ${c.noHp}',
                                            style: const TextStyle(fontSize: 11.5, color: kBrandPrimary, fontWeight: FontWeight.w500),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: kBrandAccent),
                                        tooltip: 'Edit Data',
                                        onPressed: () => _showMahasiswaDialog(c),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: kColorDanger),
                                        tooltip: 'Hapus',
                                        onPressed: () => _hapusMahasiswa(c),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMahasiswaDialog(),
        backgroundColor: kBrandPrimary,
        elevation: 1,
        icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
        label: const Text('Tambah Mahasiswa', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
