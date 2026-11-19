// lib/screens/admin/alat_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/tool_model.dart';
import '../../widgets/app_widgets.dart';

class AlatScreen extends StatefulWidget {
  const AlatScreen({super.key});

  @override
  State<AlatScreen> createState() => _AlatScreenState();
}

class _AlatScreenState extends State<AlatScreen> {
  List<Tool> _tools = [];
  List<Tool> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _kategoriFilter = 'Semua';

  static const List<String> _defaultKategori = [
    'Elektronik',
    'Komputer dan Jaringan',
    'Peralatan Praktikum',
    'Audio Visual',
    'Peralatan Presentasi',
    'Peralatan Olahraga',
    'Perlengkapan Kegiatan',
    'Sarana Prasarana',
  ];

  static const Set<String> _ignoredLegacyKategori = {
    'Teknologi Rekayasa Perangkat Lunak',
    'Teknologi Rekayasa Pemeliharaan Alat Berat',
    'Teknologi Rekayasa Logistik',
    'Akuntansi Perpajakan',
    'Bisnis Digital',
    'Teknik Listrik',
    'Teknik Elektronika',
    'Teknik Mesin',
    'Umum',
  };

  List<String> _kategoriList = List.from(_defaultKategori);

  @override
  void initState() {
    super.initState();
    _fetchTools();
  }

  Future<void> _fetchTools() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/tools');
      final list = (data as List).map((e) => Tool.fromJson(e)).toList();
      _tools = list;

      // Sinkronkan daftar kategori dengan database (abaikan kategori lama prodi)
      final dynamicKategori = <String>{..._defaultKategori};
      for (final t in list) {
        final cat = t.kategori.trim();
        if (cat.isNotEmpty && !_ignoredLegacyKategori.contains(cat)) {
          dynamicKategori.add(cat);
        }
      }
      _kategoriList = dynamicKategori.toList();

      final q = _search.toLowerCase();
      final filteredList = _tools.where((t) {
        final matchesQuery = t.namaAlat.toLowerCase().contains(q) ||
            t.kodeAlat.toLowerCase().contains(q) ||
            t.kategori.toLowerCase().contains(q);
        final matchesKategori = _kategoriFilter == 'Semua' || t.kategori == _kategoriFilter;
        return matchesQuery && matchesKategori;
      }).toList();
      setState(() {
        _filtered = filteredList;
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
      _filtered = _tools.where((t) {
        final matchesQuery = t.namaAlat.toLowerCase().contains(q) ||
            t.kodeAlat.toLowerCase().contains(q) ||
            t.kategori.toLowerCase().contains(q);
        final matchesKategori = _kategoriFilter == 'Semua' || t.kategori == _kategoriFilter;
        return matchesQuery && matchesKategori;
      }).toList();
    });
  }

  Future<void> _showFormDialog([Tool? existing]) async {
    final formKey = GlobalKey<FormState>();
    final kode = TextEditingController(text: existing?.kodeAlat ?? '');
    final nama = TextEditingController(text: existing?.namaAlat ?? '');
    
    final bool hasExistingKategori = existing != null && existing.kategori.trim().isNotEmpty;
    bool isCustomKategori = hasExistingKategori && !_kategoriList.contains(existing.kategori.trim());
    String selectedKategori = hasExistingKategori && _kategoriList.contains(existing.kategori.trim())
        ? existing.kategori.trim()
        : _kategoriList.first;
    final customKategori = TextEditingController(
      text: isCustomKategori ? existing?.kategori.trim() : '',
    );

    final deskripsi = TextEditingController(text: existing?.deskripsi ?? '');
    final stokTotal = TextEditingController(text: existing?.stokTotal.toString() ?? '1');
    final stokTersedia = TextEditingController(text: existing?.stokTersedia.toString() ?? '1');
    String kondisi = existing?.kondisi ?? 'baik';
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: kSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            existing == null ? 'Tambah Alat Laboratorium' : 'Edit Data Alat',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextMain),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            existing == null ? 'Kelola inventaris fisik alat lab' : 'Perbarui data spesifikasi dan stok',
                            style: const TextStyle(fontSize: 12, color: kTextMuted),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: kTextMuted),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: kBorder),
                  const SizedBox(height: 14),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _inputLabel('Kode Alat *'),
                                      TextFormField(
                                        controller: kode,
                                        decoration: _dialogInput('Contoh: LPT-ASUS-01'),
                                        validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _inputLabel('Nama Alat *'),
                                      TextFormField(
                                        controller: nama,
                                        decoration: _dialogInput('Contoh: Laptop Asus Core i7'),
                                        validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _inputLabel('Kategori Alat *'),
                                InkWell(
                                  onTap: () {
                                    setS(() {
                                      isCustomKategori = !isCustomKategori;
                                      if (isCustomKategori && customKategori.text.isEmpty) {
                                        customKategori.text = selectedKategori;
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCustomKategori ? Icons.format_list_bulleted : Icons.add_circle_outline,
                                          size: 14,
                                          color: kBrandAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isCustomKategori ? 'Pilih dari Daftar' : '+ Ketik Kategori Baru',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: kBrandAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (isCustomKategori)
                              TextFormField(
                                controller: customKategori,
                                decoration: _dialogInput('Ketik nama kategori baru...'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama kategori wajib diisi' : null,
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: _kategoriList.contains(selectedKategori) ? selectedKategori : _kategoriList.first,
                                decoration: _dialogInput('Pilih Kategori Alat'),
                                isExpanded: true,
                                items: _kategoriList.map((k) => DropdownMenuItem(
                                  value: k,
                                  child: Text(k, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (v) => setS(() => selectedKategori = v ?? _kategoriList.first),
                              ),
                            const SizedBox(height: 12),

                            _inputLabel('Deskripsi Singkat (Opsional)'),
                            TextFormField(
                              controller: deskripsi,
                              maxLines: 2,
                              decoration: _dialogInput('Spesifikasi, perlengkapan, atau catatan penyimpanan'),
                            ),
                            const SizedBox(height: 14),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _inputLabel('Stok Total Inventaris'),
                                        TextFormField(
                                          controller: stokTotal,
                                          keyboardType: TextInputType.number,
                                          decoration: _dialogInput('0'),
                                          validator: (v) => (int.tryParse(v ?? '') == null) ? 'Angka valid' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _inputLabel('Stok Siap Dipinjam'),
                                        TextFormField(
                                          controller: stokTersedia,
                                          keyboardType: TextInputType.number,
                                          decoration: _dialogInput('0'),
                                          validator: (v) {
                                            final val = int.tryParse(v ?? '');
                                            final total = int.tryParse(stokTotal.text) ?? 0;
                                            if (val == null) return 'Angka valid';
                                            if (val > total) return 'Maks $total';
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            _inputLabel('Kondisi Fisik Alat:'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: _toolConditionOption(
                                    label: 'Baik',
                                    icon: Icons.check_circle_outline,
                                    isSelected: kondisi == 'baik',
                                    activeColor: kColorSuccess,
                                    onTap: () => setS(() => kondisi = 'baik'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _toolConditionOption(
                                    label: 'Rusak',
                                    icon: Icons.error_outline,
                                    isSelected: kondisi == 'rusak',
                                    activeColor: kColorDanger,
                                    onTap: () => setS(() => kondisi = 'rusak'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _toolConditionOption(
                                    label: 'Perawatan',
                                    icon: Icons.build_outlined,
                                    isSelected: kondisi == 'perawatan',
                                    activeColor: kColorWarning,
                                    onTap: () => setS(() => kondisi = 'perawatan'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
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
                        label: existing == null ? 'Simpan Alat' : 'Perbarui Data',
                        icon: existing == null ? Icons.add : Icons.check,
                        isLoading: saving,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          setS(() => saving = true);
                          try {
                            final finalKategori = isCustomKategori
                                ? customKategori.text.trim()
                                : selectedKategori;

                            final payload = {
                              'kode_alat': kode.text.trim(),
                              'nama_alat': nama.text.trim(),
                              'kategori': finalKategori,
                              'deskripsi': deskripsi.text.trim().isEmpty ? null : deskripsi.text.trim(),
                              'stok_total': int.tryParse(stokTotal.text) ?? 0,
                              'stok_tersedia': int.tryParse(stokTersedia.text) ?? 0,
                              'kondisi': kondisi,
                            };
                            if (existing == null) {
                              await ApiService.post('/tools', payload);
                            } else {
                              await ApiService.put('/tools/${existing.idTool}', payload);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              showSuccess(context, existing == null ? 'Alat berhasil ditambahkan' : 'Data alat diperbarui');
                              _fetchTools();
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
    );
  }

  Widget _toolConditionOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : kTextMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : kTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hapusTool(Tool tool) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Alat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Hapus "${tool.namaAlat}" dari inventaris laboratorium?',
            style: const TextStyle(fontSize: 13, color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kColorDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.delete('/tools/${tool.idTool}');
      if (mounted) {
        showSuccess(context, 'Alat berhasil dihapus');
        _fetchTools();
      }
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
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
            child: Column(
              children: [
                TextField(
                  onChanged: (v) {
                    _search = v;
                    _applyFilter();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari alat berdasarkan nama, kode, atau kategori...',
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Semua', ..._kategoriList].map((k) {
                      final active = _kategoriFilter == k;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () {
                            setState(() => _kategoriFilter = k);
                            _applyFilter();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: active ? kBrandAccent : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active ? kBrandAccent : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              k,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? Colors.white : kTextMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),

          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Memuat inventaris alat...')
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Tidak ada data alat',
                        subtitle: 'Alat laboratorium tidak ditemukan untuk filter ini',
                        action: AppButton(
                          label: 'Tambah Alat Baru',
                          icon: Icons.add,
                          onPressed: () => _showFormDialog(),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchTools,
                        color: kBrandAccent,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 84),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final t = _filtered[i];
                            final stockColor = t.stokTersedia == 0
                                ? kColorDanger
                                : (t.stokTersedia <= 2 ? kColorWarning : kColorSuccess);

                            return CleanCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.build_circle_outlined, size: 22, color: kBrandAccent),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.namaAlat,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(t.kodeAlat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextMuted)),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    t.kategori,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 11.5, color: kBrandAccent, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      KondisiBadge(t.kondisi),
                                    ],
                                  ),
                                  if (t.deskripsi != null && t.deskripsi!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      t.deskripsi!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: kTextMuted, height: 1.3),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Stok: ', style: TextStyle(fontSize: 12, color: kTextMuted)),
                                      Text(
                                        '${t.stokTersedia} ',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: stockColor,
                                        ),
                                      ),
                                      Text('/ ${t.stokTotal} unit siap dipinjam', style: const TextStyle(fontSize: 12, color: kTextMuted)),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () => _showFormDialog(t),
                                        borderRadius: BorderRadius.circular(6),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 14, color: kBrandAccent),
                                              SizedBox(width: 4),
                                              Text('Edit', style: TextStyle(fontSize: 12, color: kBrandAccent, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => _hapusTool(t),
                                        borderRadius: BorderRadius.circular(6),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 14, color: kColorDanger),
                                              SizedBox(width: 4),
                                              Text('Hapus', style: TextStyle(fontSize: 12, color: kColorDanger, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
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
        onPressed: () => _showFormDialog(),
        backgroundColor: kBrandPrimary,
        elevation: 1,
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: const Text('Tambah Alat', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
    );
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
}
